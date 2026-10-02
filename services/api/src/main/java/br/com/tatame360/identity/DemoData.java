package br.com.tatame360.identity;

import br.com.tatame360.shared.Store;
import java.util.*;
import java.time.*;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;

@Component @Profile("dev")
public class DemoData implements CommandLineRunner {
    private final Store store;private final PasswordEncoder encoder;private final String password;
    public DemoData(Store store,PasswordEncoder encoder,@Value("${app.demo-password}") String password){this.store=store;this.encoder=encoder;this.password=password;}
    public static UUID id(String value){return UUID.nameUUIDFromBytes(value.getBytes(java.nio.charset.StandardCharsets.UTF_8));}
    @Override @Transactional public void run(String... args){
        if(password.length()<12)throw new IllegalStateException("Configure DEMO_PASSWORD com pelo menos 12 caracteres no perfil dev.");
        if(store.db.queryForObject("select count(*) from academy",Integer.class)>0)return;
        ZoneId zone=ZoneId.of("America/Sao_Paulo");LocalDate today=LocalDate.now(zone);
        String passwordHash=encoder.encode(password);
        for(String code:List.of("raiz","norte")){
            UUID tenant=id(code),unit=id(code+"-unit"),owner=id(code+"-owner"),template=id(code+"-class");
            store.db.update("insert into academy(id,name,collection_started) values (?,?,?)",tenant,code.equals("raiz")?"Raiz Jiu-Jitsu · Demonstração":"Norte Jiu-Jitsu · Demonstração",today.minusDays(60));
            store.db.update("insert into academy_unit(id,tenant_id,name) values (?,?,'Unidade Centro')",unit,tenant);
            for(String role:List.of("owner","instructor","student")){
                UUID user=id(code+"-"+role);
                store.db.update("insert into app_user(id,email,name,password_hash) values (?,?,?,?)",user,role+"@"+code+".example",role.equals("owner")?"Alex · Demo":role+" · Demo",passwordHash);
                store.db.update("insert into role_assignment(id,tenant_id,unit_id,user_id,role) values (?,?,?,?,?)",id(code+"-role-"+role),tenant,unit,user,role.toUpperCase(Locale.ROOT));
            }
            store.db.update("insert into class_template(id,tenant_id,unit_id,name,weekday,local_time,duration_minutes,instructor_id) values (?,?,?,'Jiu-Jitsu · Todos os níveis',?,'19:00',60,?)",template,tenant,unit,today.getDayOfWeek().getValue(),owner);
            for(int i=0;i<30;i++){
                UUID student=id(code+"-student-"+i),membership=id(code+"-membership-"+i);
                String[] names={"Ana","Bruno","Camila","Diego","Elisa","Felipe","Gabriela","Hugo","Iara","João"};
                store.db.update("insert into student(id,tenant_id,unit_id,name,belt,user_id) values (?,?,?,?,?,?)",student,tenant,unit,names[i%10]+" Exemplo "+(i+1),i%3==0?"Azul":"Branca",i==0?id(code+"-student"):null);
                store.db.update("insert into membership(id,tenant_id,student_id,starts_on,status,primary_class_id) values (?,?,?,?,'ACTIVE',?)",membership,tenant,student,today.minusDays(i==29?8:60),template);
            }
            for(int day=-56;day<8;day++){
                LocalDate date=today.plusDays(day);
                if(day!=0&&date.getDayOfWeek().getValue()%2==0)continue;
                UUID session=id(code+"-session-"+date);ZonedDateTime start=date.atTime(19,0).atZone(zone);
                // Today's demo class starts shortly before now, so the first call can be exercised immediately.
                if(day==0)start=ZonedDateTime.now(zone).minusMinutes(10).withSecond(0).withNano(0);
                store.db.update("insert into class_session(id,tenant_id,unit_id,template_id,starts_at,ends_at,status) values (?,?,?,?,?,?,?)",session,tenant,unit,template,start.toOffsetDateTime(),start.plusHours(1).toOffsetDateTime(),day<0?"COMPLETED":"SCHEDULED");
                if(day>=0)continue;
                for(int i=0;i<29;i++){
                    UUID student=id(code+"-student-"+i);
                    store.db.update("insert into session_roster(tenant_id,session_id,student_id) values (?,?,?)",tenant,session,student);
                    if((i<5&&day>-11)||(i>=5&&Math.floorMod(day+i,4)==0))continue;
                    store.db.update("insert into attendance(id,tenant_id,session_id,student_id,author_id,source,recorded_at) values (?,?,?,?,?,'MANUAL',?)",UUID.randomUUID(),tenant,session,student,owner,start.toOffsetDateTime());
                }
            }
        }
    }
}
