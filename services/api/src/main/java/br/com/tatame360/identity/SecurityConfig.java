package br.com.tatame360.identity;

import java.io.IOException;
import java.util.*;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import org.springframework.context.annotation.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.cors.*;
import br.com.tatame360.shared.Store;

@Configuration
public class SecurityConfig {
    @Bean PasswordEncoder passwords(){return new BCryptPasswordEncoder(12);}
    @Bean SecurityFilterChain security(HttpSecurity http,Store store,@Value("${app.allowed-origin}") String origin) throws Exception {
        var cors=new CorsConfiguration(); cors.setAllowedOrigins(List.of(origin)); cors.setAllowCredentials(true);
        cors.setAllowedMethods(List.of("GET","POST","PATCH","OPTIONS"));
        cors.setAllowedHeaders(List.of("Content-Type","Authorization","Idempotency-Key","X-Tatame-Client"));
        var source=new UrlBasedCorsConfigurationSource(); source.registerCorsConfiguration("/**",cors);
        // Cookie endpoints are protected by a mandatory custom header and exact Origin validation below.
        http.cors(c->c.configurationSource(source)).csrf(c->c.disable())
            .sessionManagement(s->s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(a->a.requestMatchers("/api/v1/auth/**","/actuator/health").permitAll().anyRequest().authenticated())
            .exceptionHandling(e->e.authenticationEntryPoint((req,res,ex)->{
                res.setStatus(401);res.setContentType("application/json");res.getWriter().write("{\"code\":\"UNAUTHORIZED\",\"message\":\"Entre novamente para continuar.\"}");
            }))
            .addFilterBefore(new OncePerRequestFilter(){
                @Override protected void doFilterInternal(HttpServletRequest req,HttpServletResponse res,FilterChain chain) throws ServletException,IOException {
                    if(req.getRequestURI().startsWith("/api/v1/auth/")&&!req.getMethod().equals("OPTIONS")) {
                        String requestOrigin=req.getHeader("Origin");
                        if(!"app".equals(req.getHeader("X-Tatame-Client")) || (requestOrigin!=null&&!requestOrigin.equals(origin))) {
                            res.sendError(403);return;
                        }
                    }
                    String header=req.getHeader("Authorization");
                    if(header!=null&&header.startsWith("Bearer ")) {
                        var rows=store.db.queryForList("select s.user_id from auth_session s join app_user u on u.id=s.user_id where s.access_hash=? and not s.revoked and s.access_expires>now() and u.active",Store.hash(header.substring(7)));
                        if(!rows.isEmpty()) SecurityContextHolder.getContext().setAuthentication(new UsernamePasswordAuthenticationToken(rows.getFirst().get("user_id").toString(),null,List.of()));
                    }
                    chain.doFilter(req,res);
                }
            },UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }
}
