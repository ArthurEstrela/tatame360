package br.com.tatame360.identity;

import java.util.*;
import org.springframework.stereotype.Component;
import org.springframework.security.core.context.SecurityContextHolder;
import br.com.tatame360.shared.*;

@Component
public class Access {
    private final Store store;
    public Access(Store store){this.store=store;}
    public UUID user(){return UUID.fromString(SecurityContextHolder.getContext().getAuthentication().getName());}
    public Scope scope(UUID academy,String... roles) {
        var r=store.one("select unit_id,role from role_assignment where tenant_id=? and user_id=? and active=true",academy,user());
        String role=r.get("role").toString();
        if(roles.length>0&&!Arrays.asList(roles).contains(role)) throw new ApiException(403,"FORBIDDEN","Você não tem permissão para esta ação.");
        return new Scope(academy,(UUID)r.get("unit_id"),user(),role);
    }
    public Scope staff(UUID academy){return scope(academy,"OWNER","MANAGER","INSTRUCTOR","FRONT_DESK");}
    public Scope manager(UUID academy){return scope(academy,"OWNER","MANAGER");}
    public record Scope(UUID tenant,UUID unit,UUID user,String role){}
}
