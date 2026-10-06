package br.com.tatame360.identity;

import br.com.tatame360.shared.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1")
public class TeamController {
    private static final Set<String> INVITABLE=Set.of("MANAGER","INSTRUCTOR","FRONT_DESK");
    private final Store store; private final Access access; private final PasswordEncoder encoder;
    private final ConcurrentHashMap<String,Window> tokenAttempts=new ConcurrentHashMap<>();
    private record Window(long time,int count){}

    public TeamController(Store store,Access access,PasswordEncoder encoder){this.store=store;this.access=access;this.encoder=encoder;}

    @GetMapping("/academies/{academy}/team") @Transactional
    public Object team(@PathVariable UUID academy){
        access.manager(academy);
        expireInvitations(academy);
        var members=store.db.queryForList("""
            select u.id,u.name,u.email,r.role,r.active,r.unit_id as \"unitId\",r.id as \"assignmentId\"
            from role_assignment r join app_user u on u.id=r.user_id
            where r.tenant_id=? and r.role in ('OWNER','MANAGER','INSTRUCTOR','FRONT_DESK')
            order by case r.role when 'OWNER' then 0 when 'MANAGER' then 1 else 2 end,u.name
            """,academy);
        var invitations=store.db.queryForList("""
            select id,name,email,role,status,expires_at as \"expiresAt\",created_at as \"createdAt\"
            from team_invitation where tenant_id=? order by created_at desc limit 50
            """,academy);
        return Map.of("members",members,"invitations",invitations);
    }

    public record InvitationInput(@NotBlank @Size(max=120) String name,@NotBlank @Email @Size(max=254) String email,@NotBlank String role){}

    @PostMapping("/academies/{academy}/invitations") @Transactional
    public Object invite(@PathVariable UUID academy,@Valid @RequestBody InvitationInput input){
        var scope=access.manager(academy); String role=role(input.role());
        if(scope.role().equals("MANAGER")&&role.equals("MANAGER")) throw forbidden();
        int recent=store.db.queryForObject("select count(*) from team_invitation where invited_by=? and created_at>now()-interval '1 hour'",Integer.class,scope.user());
        if(recent>=20) throw new ApiException(429,"RATE_LIMIT","Aguarde antes de enviar novos convites.");
        String email=input.email().trim().toLowerCase(Locale.ROOT);
        expireInvitations(academy);
        if(store.db.queryForObject("""
            select count(*) from role_assignment r join app_user u on u.id=r.user_id
            where r.tenant_id=? and lower(u.email)=? and r.active
            """,Integer.class,academy,email)>0) throw ApiException.conflict("Este e-mail já faz parte da equipe.");
        if(store.db.queryForObject("select count(*) from team_invitation where tenant_id=? and lower(email)=? and status='PENDING'",Integer.class,academy,email)>0)
            throw ApiException.conflict("Já existe um convite pendente para este e-mail.");
        String token=token(); UUID id=UUID.randomUUID();
        store.db.update("""
            insert into team_invitation(id,tenant_id,unit_id,email,name,role,token_hash,invited_by,expires_at)
            values (?,?,?,?,?,?,?,?,now()+interval '7 days')
            """,id,academy,scope.unit(),email,input.name().trim(),role,Store.hash(token),scope.user());
        store.event(academy,scope.user(),"TeamInvitationCreated",id);
        return Map.of("id",id,"token",token,"expiresIn",604800);
    }

    @PostMapping("/academies/{academy}/invitations/{id}/revoke") @Transactional
    public Object revoke(@PathVariable UUID academy,@PathVariable UUID id){
        var scope=access.manager(academy);
        int changed=store.db.update("update team_invitation set status='REVOKED' where tenant_id=? and id=? and status='PENDING'",academy,id);
        if(changed==0) throw ApiException.missing();
        store.event(academy,scope.user(),"TeamInvitationRevoked",id);
        return Map.of("ok",true);
    }

    public record MemberAccess(@NotBlank String role,boolean active){}

    @PatchMapping("/academies/{academy}/team/{userId}") @Transactional
    public Object updateMember(@PathVariable UUID academy,@PathVariable UUID userId,@Valid @RequestBody MemberAccess input){
        var scope=access.manager(academy); String newRole=role(input.role());
        var current=store.one("select id,role,active from role_assignment where tenant_id=? and user_id=? for update",academy,userId);
        String oldRole=current.get("role").toString();
        if(oldRole.equals("OWNER")) throw ApiException.invalid("O acesso do owner exige um fluxo de transferência de propriedade.");
        if(scope.role().equals("MANAGER")&&(oldRole.equals("MANAGER")||newRole.equals("MANAGER"))) throw forbidden();
        store.db.update("update role_assignment set role=?,active=? where tenant_id=? and user_id=?",newRole,input.active(),academy,userId);
        UUID assignment=(UUID)current.get("id"); store.event(academy,scope.user(),"TeamAccessChanged",assignment);
        return Map.of("ok",true);
    }

    @GetMapping("/auth/invitations/{token}")
    public Object invitation(@PathVariable String token,HttpServletRequest request){
        limit(request.getRemoteAddr()); var invitation=invitation(token,false);
        boolean existing=store.db.queryForObject("select count(*) from app_user where lower(email)=lower(?) and active",Integer.class,invitation.get("email"))>0;
        return Map.of("name",invitation.get("name"),"email",invitation.get("email"),"role",invitation.get("role"),
            "academyName",invitation.get("academyName"),"expiresAt",invitation.get("expiresAt"),"existingAccount",existing);
    }

    public record AcceptInvitation(@Size(max=120) String name,@NotBlank @Size(min=12,max=72) String password){}

    @PostMapping("/auth/invitations/{token}/accept") @Transactional
    public Object accept(@PathVariable String token,@Valid @RequestBody AcceptInvitation input,HttpServletRequest request){
        limit(request.getRemoteAddr()); var invitation=invitation(token,true);
        UUID tenant=(UUID)invitation.get("tenantId"); String email=invitation.get("email").toString();
        var users=store.db.queryForList("select id,password_hash from app_user where lower(email)=lower(?) and active for update",email);
        UUID user;
        if(users.isEmpty()){
            String name=input.name()==null?"":input.name().trim();
            if(name.length()<2) throw ApiException.invalid("Informe seu nome.");
            user=UUID.randomUUID(); store.db.update("insert into app_user(id,email,name,password_hash) values (?,?,?,?)",user,email,name,encoder.encode(input.password()));
        } else {
            var existing=users.getFirst();
            if(!encoder.matches(input.password(),existing.get("password_hash").toString()))
                throw new ApiException(401,"INVALID_CREDENTIALS","Use a senha atual da sua conta para aceitar o convite.");
            user=(UUID)existing.get("id");
        }
        store.db.update("""
            insert into role_assignment(id,tenant_id,unit_id,user_id,role,active) values (?,?,?,?,?,true)
            on conflict(tenant_id,user_id) do update set unit_id=excluded.unit_id,role=excluded.role,active=true
            """,UUID.randomUUID(),tenant,invitation.get("unitId"),user,invitation.get("role"));
        UUID id=(UUID)invitation.get("id");
        store.db.update("update team_invitation set status='ACCEPTED',accepted_by=?,accepted_at=now() where id=?",user,id);
        store.event(tenant,user,"TeamInvitationAccepted",id);
        return Map.of("ok",true,"email",email,"academyName",invitation.get("academyName"));
    }

    private Map<String,Object> invitation(String token,boolean lock){
        if(token.length()>200) throw invalidToken();
        var rows=store.db.queryForList("""
            select i.id,i.tenant_id as \"tenantId\",i.unit_id as \"unitId\",i.email,i.name,i.role,
                   i.expires_at as \"expiresAt\",a.name as \"academyName\"
            from team_invitation i join academy a on a.id=i.tenant_id
            where i.token_hash=? and i.status='PENDING' and i.expires_at>now()
            """+(lock?" for update of i":""),Store.hash(token));
        if(rows.isEmpty()) throw invalidToken(); return rows.getFirst();
    }
    private String role(String role){String normalized=role.trim().toUpperCase(Locale.ROOT);if(!INVITABLE.contains(normalized))throw ApiException.invalid("Papel de equipe inválido.");return normalized;}
    private void expireInvitations(UUID academy){store.db.update("update team_invitation set status='EXPIRED' where tenant_id=? and status='PENDING' and expires_at<=now()",academy);}
    private ApiException forbidden(){return new ApiException(403,"FORBIDDEN","Você não tem permissão para gerenciar este papel.");}
    private ApiException invalidToken(){return new ApiException(410,"TOKEN_INVALID","Este convite expirou, foi revogado ou já foi utilizado.");}
    private void limit(String ip){long now=System.currentTimeMillis();tokenAttempts.entrySet().removeIf(e->now-e.getValue().time>900000);Window w=tokenAttempts.compute(ip,(k,v)->v==null?new Window(now,1):new Window(v.time,v.count+1));if(w.count>60)throw new ApiException(429,"RATE_LIMIT","Aguarde alguns minutos antes de tentar novamente.");}
    private String token(){byte[] bytes=new byte[32];new SecureRandom().nextBytes(bytes);return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);}
}
