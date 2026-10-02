package br.com.tatame360.identity;

import br.com.tatame360.shared.*;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.security.SecureRandom;
import java.time.Duration;
import jakarta.servlet.http.*;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseCookie;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1")
public class AuthController {
    private final Store store; private final PasswordEncoder encoder; private final Access access; private final boolean secure;
    private final String dummyHash;
    private final ConcurrentHashMap<String,Window> attempts=new ConcurrentHashMap<>();
    private record Window(long time,int count){}
    public AuthController(Store store,PasswordEncoder encoder,Access access,@Value("${app.cookie-secure}") boolean secure) {
        this.store=store;this.encoder=encoder;this.access=access;this.secure=secure;dummyHash=encoder.encode(UUID.randomUUID().toString());
    }
    public record Login(@NotBlank @Email @Size(max=254) String email,@NotBlank @Size(max=72) String password,boolean mobile){}
    public record Refresh(@Size(max=200) String refreshToken,boolean mobile){}
    private void limit(String ip) {
        long now=System.currentTimeMillis();
        attempts.entrySet().removeIf(e->now-e.getValue().time>900000);
        Window w=attempts.compute(ip,(k,old)->old==null?new Window(now,1):new Window(old.time,old.count+1));
        if(w.count>30) throw new ApiException(429,"RATE_LIMIT","Aguarde alguns minutos antes de tentar novamente.");
    }
    @PostMapping("/auth/login") @Transactional
    public Object login(@Valid @RequestBody Login input,HttpServletRequest request,HttpServletResponse response) {
        limit(request.getRemoteAddr());
        var rows=store.db.queryForList("select id,password_hash from app_user where email=? and active",input.email().trim().toLowerCase(Locale.ROOT));
        String hash=rows.isEmpty()?dummyHash:rows.getFirst().get("password_hash").toString();
        if(!encoder.matches(input.password(),hash)||rows.isEmpty()) throw new ApiException(401,"INVALID_CREDENTIALS","E-mail ou senha inválidos.");
        return issue((UUID)rows.getFirst().get("id"),UUID.randomUUID(),input.mobile(),response);
    }
    @PostMapping("/auth/refresh") @Transactional(noRollbackFor=ApiException.class)
    public Object refresh(@Valid @RequestBody Refresh input,HttpServletRequest req,HttpServletResponse response) {
        limit(req.getRemoteAddr());
        String token=input.mobile()?input.refreshToken():cookie(req);
        if(token==null) throw new ApiException(401,"SESSION_EXPIRED","Sua sessão expirou.");
        var rows=store.db.queryForList("select s.* from auth_session s join app_user u on u.id=s.user_id where refresh_hash=? and u.active for update of s",Store.hash(token));
        if(rows.isEmpty()) throw new ApiException(401,"SESSION_EXPIRED","Sua sessão expirou.");
        var session=rows.getFirst();
        if((boolean)session.get("revoked")) {
            store.db.update("update auth_session set revoked=true where family_id=?",session.get("family_id"));
            throw new ApiException(401,"SESSION_REUSED","Entre novamente para continuar.");
        }
        if(((java.sql.Timestamp)session.get("refresh_expires")).toInstant().isBefore(java.time.Instant.now())) throw new ApiException(401,"SESSION_EXPIRED","Sua sessão expirou.");
        store.db.update("update auth_session set revoked=true where id=?",session.get("id"));
        return issue((UUID)session.get("user_id"),(UUID)session.get("family_id"),input.mobile(),response);
    }
    @PostMapping("/auth/logout") @Transactional
    public Object logout(@Valid @RequestBody Refresh input,HttpServletRequest req,HttpServletResponse response) {
        String token=input.mobile()?input.refreshToken():cookie(req);
        if(token!=null) store.db.update("update auth_session set revoked=true where family_id in (select family_id from auth_session where refresh_hash=?)",Store.hash(token));
        response.addHeader("Set-Cookie",refreshCookie("",0));return Map.of("ok",true);
    }
    @GetMapping("/me")
    public Object me() {
        var user=store.one("select id,name,email from app_user where id=?",access.user());
        user.put("academies",store.db.queryForList("select a.id,a.name,a.timezone,r.unit_id as \"unitId\",r.role from academy a join role_assignment r on r.tenant_id=a.id where r.user_id=? and r.active order by a.name",access.user()));
        return user;
    }
    private Object issue(UUID user,UUID family,boolean mobile,HttpServletResponse response) {
        String accessToken=token(),refreshToken=token();
        store.db.update("insert into auth_session(id,user_id,access_hash,refresh_hash,access_expires,refresh_expires,family_id) values (?,?,?,?,now()+interval '15 minutes',now()+interval '30 days',?)",UUID.randomUUID(),user,Store.hash(accessToken),Store.hash(refreshToken),family);
        var result=new HashMap<String,Object>();result.put("accessToken",accessToken);result.put("expiresIn",900);
        if(mobile) result.put("refreshToken",refreshToken); else response.addHeader("Set-Cookie",refreshCookie(refreshToken,2592000));
        return result;
    }
    private String refreshCookie(String token,long seconds){return ResponseCookie.from("tatame_refresh",token).httpOnly(true).secure(secure).sameSite("Strict").path("/api/v1/auth").maxAge(Duration.ofSeconds(seconds)).build().toString();}
    private String cookie(HttpServletRequest req){return req.getCookies()==null?null:Arrays.stream(req.getCookies()).filter(c->c.getName().equals("tatame_refresh")).map(Cookie::getValue).findFirst().orElse(null);}
    private String token(){byte[] bytes=new byte[32];new SecureRandom().nextBytes(bytes);return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);}
}
