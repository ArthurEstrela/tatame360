package br.com.tatame360.classes;

import br.com.tatame360.identity.Access;
import br.com.tatame360.shared.*;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import java.time.*;
import java.util.*;

@RestController
@RequestMapping("/api/v1/academies/{academy}")
public class ClassController {
    private final Store store;private final Access access;
    public ClassController(Store store,Access access){this.store=store;this.access=access;}
    public record Template(@NotBlank @Size(max=100) String name,@Min(1) @Max(7) int weekday,@NotNull LocalTime time,@Min(15) @Max(240) int durationMinutes){}
    @GetMapping("/class-templates")
    public Object templates(@PathVariable UUID academy){
        var scope=access.staff(academy);
        return store.db.queryForList("select id,name,weekday,local_time as time,duration_minutes as \"durationMinutes\" from class_template where tenant_id=? and unit_id=? and active and (? <> 'INSTRUCTOR' or instructor_id=?) order by weekday,local_time",academy,scope.unit(),scope.role(),scope.user());
    }
    @PostMapping("/class-templates") @Transactional
    public Object create(@PathVariable UUID academy,@Valid @RequestBody Template input,@RequestHeader("Idempotency-Key") UUID key){
        var scope=access.manager(academy);
        return store.replay(academy,scope.user(),"class.create",key,input,()->{
            UUID id=UUID.randomUUID();
            store.db.update("insert into class_template(id,tenant_id,unit_id,name,weekday,local_time,duration_minutes,instructor_id) values (?,?,?,?,?,?,?,?)",id,academy,scope.unit(),input.name().trim(),input.weekday(),input.time(),input.durationMinutes(),scope.user());
            ZoneId zone=ZoneId.of(store.one("select timezone from academy where id=?",academy).get("timezone").toString());
            LocalDate today=LocalDate.now(zone);
            for(int i=0;i<28;i++){
                LocalDate day=today.plusDays(i);if(day.getDayOfWeek().getValue()!=input.weekday())continue;
                ZonedDateTime start=day.atTime(input.time()).atZone(zone);
                store.db.update("insert into class_session(id,tenant_id,unit_id,template_id,starts_at,ends_at) values (?,?,?,?,?,?) on conflict do nothing",UUID.randomUUID(),academy,scope.unit(),id,start.toOffsetDateTime(),start.plusMinutes(input.durationMinutes()).toOffsetDateTime());
            }
            store.event(academy,scope.user(),"ClassCreated",id);return Map.of("id",id);
        });
    }
    @GetMapping("/sessions")
    public Object sessions(@PathVariable UUID academy,@RequestParam LocalDate from,@RequestParam LocalDate to){
        var scope=access.staff(academy);if(to.isBefore(from)||from.plusDays(62).isBefore(to))throw ApiException.invalid("Consulte até 62 dias por vez.");
        ZoneId zone=ZoneId.of(store.one("select timezone from academy where id=?",academy).get("timezone").toString());
        return store.db.queryForList("select c.id,t.name,c.starts_at as \"startsAt\",c.ends_at as \"endsAt\",c.status,c.version,(select count(*) from attendance a where a.tenant_id=c.tenant_id and a.session_id=c.id and a.valid) as present from class_session c join class_template t on t.tenant_id=c.tenant_id and t.id=c.template_id where c.tenant_id=? and c.unit_id=? and c.starts_at>=? and c.starts_at<? and (? <> 'INSTRUCTOR' or t.instructor_id=?) order by c.starts_at,c.id",academy,scope.unit(),from.atStartOfDay(zone).toOffsetDateTime(),to.plusDays(1).atStartOfDay(zone).toOffsetDateTime(),scope.role(),scope.user());
    }
    private Map<String,Object> session(Access.Scope scope,UUID id,boolean lock){
        return store.one("select c.*,t.name from class_session c join class_template t on t.tenant_id=c.tenant_id and t.id=c.template_id where c.tenant_id=? and c.unit_id=? and c.id=? and (? <> 'INSTRUCTOR' or t.instructor_id=?)"+(lock?" for update of c":""),scope.tenant(),scope.unit(),id,scope.role(),scope.user());
    }
    @GetMapping("/sessions/{id}/roster")
    public Object roster(@PathVariable UUID academy,@PathVariable UUID id){
        var scope=access.staff(academy);var c=session(scope,id,false);
        var rows=store.db.queryForList("select s.id,s.name,s.belt,exists(select 1 from attendance a where a.tenant_id=s.tenant_id and a.student_id=s.id and a.session_id=? and a.valid) as present from student s where s.tenant_id=? and s.unit_id=? and (exists(select 1 from membership m where m.tenant_id=s.tenant_id and m.student_id=s.id and m.primary_class_id=? and m.status='ACTIVE') or exists(select 1 from session_roster r where r.tenant_id=s.tenant_id and r.student_id=s.id and r.session_id=?)) order by s.name,s.id",id,academy,scope.unit(),c.get("template_id"),id);
        return Map.of("session",Map.of("id",id,"name",c.get("name"),"status",c.get("status"),"version",c.get("version")),"students",rows);
    }
    public record Batch(@NotNull @Size(max=500) List<@NotNull UUID> studentIds,@Min(0) int version){}
    @PostMapping("/sessions/{id}/attendance/batch") @Transactional
    public Object attendance(@PathVariable UUID academy,@PathVariable UUID id,@Valid @RequestBody Batch input,@RequestHeader("Idempotency-Key") UUID key){
        var scope=access.staff(academy);
        return store.replay(academy,scope.user(),"attendance:"+id,key,input,()->{
            var c=session(scope,id,true);
            if(c.get("status").equals("CANCELLED"))throw new ApiException(422,"ATTENDANCE_SESSION_CANCELLED","Esta aula foi cancelada.");
            if(((Number)c.get("version")).intValue()!=input.version()||c.get("status").equals("COMPLETED"))throw ApiException.conflict("A chamada já foi alterada ou finalizada. Atualize a tela.");
            if(((java.sql.Timestamp)c.get("starts_at")).toInstant().isAfter(Instant.now().plusSeconds(900)))throw ApiException.invalid("A chamada abre 15 minutos antes da aula.");
            // Validate every selection before making any change. Transaction rollback preserves the full batch.
            for(UUID student:input.studentIds()){
                store.one("select s.id from student s join membership m on m.tenant_id=s.tenant_id and m.student_id=s.id where s.tenant_id=? and s.unit_id=? and s.id=? and m.status='ACTIVE' and m.primary_class_id=?",academy,scope.unit(),student,c.get("template_id"));
            }
            store.db.update("insert into session_roster(tenant_id,session_id,student_id) select ?,?,s.id from student s join membership m on m.tenant_id=s.tenant_id and m.student_id=s.id where s.tenant_id=? and s.unit_id=? and m.primary_class_id=? and m.status='ACTIVE' on conflict do nothing",academy,id,academy,scope.unit(),c.get("template_id"));
            for(UUID student:new LinkedHashSet<>(input.studentIds())){
                store.db.update("insert into attendance(id,tenant_id,session_id,student_id,author_id,source) values (?,?,?,?,?,'MANUAL') on conflict(tenant_id,session_id,student_id) do nothing",UUID.randomUUID(),academy,id,student,scope.user());
                store.db.update("update retention_alert set status='RETURN_OBSERVED',returned_at=now(),version=version+1 where tenant_id=? and membership_id in(select id from membership where tenant_id=? and student_id=? and status='ACTIVE') and status in ('OPEN','IN_PROGRESS')",academy,academy,student);
            }
            store.db.update("update class_session set status='COMPLETED',version=version+1 where tenant_id=? and id=?",academy,id);
            store.event(academy,scope.user(),"AttendanceRecorded",id);
            return Map.of("ok",true,"present",new HashSet<>(input.studentIds()).size());
        });
    }
    @PostMapping("/sessions/{id}/cancel") @Transactional
    public Object cancel(@PathVariable UUID academy,@PathVariable UUID id){
        var scope=access.manager(academy);session(scope,id,true);
        if(store.db.queryForObject("select count(*) from attendance where tenant_id=? and session_id=? and valid",Integer.class,academy,id)>0)throw ApiException.conflict("Corrija as presenças antes de cancelar a aula.");
        store.db.update("update class_session set status='CANCELLED',version=version+1 where tenant_id=? and id=?",academy,id);
        store.event(academy,scope.user(),"SessionCancelled",id);return Map.of("ok",true);
    }
}
