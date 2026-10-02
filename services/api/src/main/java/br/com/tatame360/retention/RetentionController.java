package br.com.tatame360.retention;

import br.com.tatame360.identity.Access;
import br.com.tatame360.shared.*;
import java.util.*;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.transaction.annotation.Transactional;

@RestController @RequestMapping("/api/v1/academies/{academy}")
public class RetentionController {
    private final Store store;private final Access access;private final RetentionService service;
    public RetentionController(Store store,Access access,RetentionService service){this.store=store;this.access=access;this.service=service;}
    @GetMapping("/retention/attention") public Object attention(@PathVariable UUID academy){
        var scope=access.staff(academy);
        return store.db.queryForList("select a.id,s.id as \"studentId\",s.name,a.reason,a.score,a.status,a.version,a.due_on as \"dueOn\",a.opened_at as \"openedAt\",a.returned_at as \"returnedAt\",(select max(created_at) from contact_event where tenant_id=a.tenant_id and alert_id=a.id) as \"lastContact\" from retention_alert a join membership m on m.tenant_id=a.tenant_id and m.id=a.membership_id join student s on s.tenant_id=m.tenant_id and s.id=m.student_id where a.tenant_id=? and s.unit_id=? and a.status<>'CLOSED' and m.status='ACTIVE' and (? <> 'INSTRUCTOR' or a.owner_id=?) order by a.score nulls last,a.due_on,a.id limit 100",academy,scope.unit(),scope.role(),scope.user());
    }
    @PostMapping("/retention/evaluate") public Object evaluate(@PathVariable UUID academy){access.manager(academy);service.evaluate(academy);return Map.of("ok",true);}
    public record Contact(@NotBlank @Size(max=80) String outcome,@NotNull @Size(max=1000) String note,@Min(0) int version){}
    @PostMapping("/crm/tasks/{id}/contacts") @Transactional
    public Object contact(@PathVariable UUID academy,@PathVariable UUID id,@Valid @RequestBody Contact input,@RequestHeader("Idempotency-Key") UUID key){
        var scope=access.staff(academy);
        return store.replay(academy,scope.user(),"contact:"+id,key,input,()->{
            var task=task(scope,id);
            if(((Number)task.get("version")).intValue()!=input.version()||task.get("status").equals("CLOSED"))throw ApiException.conflict("O acompanhamento mudou. Atualize a tela.");
            if(!List.of("Sem resposta","Conversou","Dificuldade de horário","Pretende voltar","Pediu pausa","Pediu cancelamento","Outro").contains(input.outcome()))throw ApiException.invalid("Resultado inválido.");
            UUID contact=UUID.randomUUID();
            store.db.update("insert into contact_event(id,tenant_id,alert_id,author_id,outcome,note) values (?,?,?,?,?,?)",contact,academy,id,scope.user(),input.outcome(),input.note());
            store.db.update("update retention_alert set status=case when status='OPEN' then 'IN_PROGRESS' else status end,version=version+1 where tenant_id=? and id=?",academy,id);
            store.event(academy,scope.user(),"ContactRecorded",id);return Map.of("id",contact);
        });
    }
    public record Close(@NotBlank @Size(max=100) String reason,@Min(0) int version){}
    @PostMapping("/crm/tasks/{id}/complete") @Transactional
    public Object complete(@PathVariable UUID academy,@PathVariable UUID id,@Valid @RequestBody Close input){
        var scope=access.staff(academy);var task=task(scope,id);
        if(((Number)task.get("version")).intValue()!=input.version())throw ApiException.conflict("O acompanhamento mudou. Atualize a tela.");
        store.db.update("update retention_alert set status='CLOSED',closed_at=now(),close_reason=?,version=version+1 where tenant_id=? and id=?",input.reason(),academy,id);
        store.event(academy,scope.user(),"RetentionAlertClosed",id);return Map.of("ok",true);
    }
    private Map<String,Object> task(Access.Scope scope,UUID id){return store.one("select a.* from retention_alert a join membership m on m.tenant_id=a.tenant_id and m.id=a.membership_id join student s on s.tenant_id=m.tenant_id and s.id=m.student_id where a.tenant_id=? and a.id=? and s.unit_id=? and (? <> 'INSTRUCTOR' or a.owner_id=?) for update of a",scope.tenant(),id,scope.unit(),scope.role(),scope.user());}
    @GetMapping("/analytics/overview") public Object overview(@PathVariable UUID academy){
        var scope=access.manager(academy);
        var result=new HashMap<String,Object>();
        result.put("activeStudents",store.db.queryForObject("select count(*) from membership m join student s on s.tenant_id=m.tenant_id and s.id=m.student_id where m.tenant_id=? and s.unit_id=? and m.status='ACTIVE'",Integer.class,academy,scope.unit()));
        result.put("pausedStudents",store.db.queryForObject("select count(*) from membership m join student s on s.tenant_id=m.tenant_id and s.id=m.student_id where m.tenant_id=? and s.unit_id=? and m.status='PAUSED'",Integer.class,academy,scope.unit()));
        result.put("attention",store.db.queryForObject("select count(*) from retention_alert a join membership m on m.tenant_id=a.tenant_id and m.id=a.membership_id join student s on s.tenant_id=m.tenant_id and s.id=m.student_id where a.tenant_id=? and s.unit_id=? and a.status in ('OPEN','IN_PROGRESS') and m.status='ACTIVE'",Integer.class,academy,scope.unit()));
        result.put("presencesWeek",store.db.queryForObject("select count(*) from attendance a join class_session c on c.tenant_id=a.tenant_id and c.id=a.session_id where a.tenant_id=? and c.unit_id=? and a.valid and c.status<>'CANCELLED' and c.starts_at>=now()-interval '7 days' and c.starts_at<=now()",Integer.class,academy,scope.unit()));
        result.put("lastEvaluation",store.db.queryForObject("select max(created_at) from retention_snapshot where tenant_id=?",java.sql.Timestamp.class,academy));
        return result;
    }
}
