package br.com.tatame360.members;

import br.com.tatame360.identity.Access;
import br.com.tatame360.shared.*;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.apache.commons.csv.*;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.time.*;
import java.util.*;

@RestController
@RequestMapping("/api/v1/academies/{academy}/students")
public class MemberController {
    private final Store store; private final Access access;
    public MemberController(Store store,Access access){this.store=store;this.access=access;}
    public record StudentInput(@NotBlank @Size(max=120) String name,@Email @Size(max=254) String email,
        @Size(max=30) String phone,@NotNull @PastOrPresent LocalDate startsOn,UUID classId){}
    private String select(){return "select s.id,s.name,s.email,s.phone,s.belt,s.degrees,s.version,m.id as \"membershipId\",m.status,m.starts_on as \"startsOn\",m.primary_class_id as \"classId\" from student s join membership m on m.student_id=s.id and m.tenant_id=s.tenant_id where s.tenant_id=? and s.unit_id=? and m.id=(select id from membership where tenant_id=s.tenant_id and student_id=s.id order by starts_on desc,id desc limit 1)";}
    @GetMapping
    public Object list(@PathVariable UUID academy,@RequestParam(defaultValue="") String search,@RequestParam(defaultValue="0") int page) {
        var scope=access.staff(academy);if(page<0||page>100000||search.length()>120)throw ApiException.invalid("Filtro inválido.");
        String filter=" and s.name ilike ?";List<Object> args=new ArrayList<>(List.of(academy,scope.unit(),"%"+search+"%"));
        if(scope.role().equals("INSTRUCTOR")){filter+=" and m.primary_class_id in(select id from class_template where tenant_id=? and instructor_id=?)";args.add(academy);args.add(scope.user());}
        args.add(25);args.add(page*25);
        return Map.of("items",store.db.queryForList(select()+filter+" order by s.name,s.id limit ? offset ?",args.toArray()),"page",page,"pageSize",25);
    }
    @PostMapping @Transactional
    public Object create(@PathVariable UUID academy,@Valid @RequestBody StudentInput input,@RequestHeader("Idempotency-Key") UUID key) {
        var scope=access.manager(academy);
        return store.replay(academy,scope.user(),"student.create",key,input,()->createStudent(scope,input));
    }
    public Object createStudent(Access.Scope scope,StudentInput input) {
        if(input.classId()!=null) store.one("select id from class_template where tenant_id=? and unit_id=? and id=?",scope.tenant(),scope.unit(),input.classId());
        UUID student=UUID.randomUUID(),membership=UUID.randomUUID();
        store.db.update("insert into student(id,tenant_id,unit_id,name,email,phone) values (?,?,?,?,?,?)",student,scope.tenant(),scope.unit(),input.name().trim(),input.email(),input.phone());
        store.db.update("insert into membership(id,tenant_id,student_id,starts_on,status,primary_class_id) values (?,?,?,?,'ACTIVE',?)",membership,scope.tenant(),student,input.startsOn(),input.classId());
        store.event(scope.tenant(),scope.user(),"StudentEnrolled",student);
        return Map.of("id",student,"membershipId",membership);
    }
    @GetMapping("/{student}")
    public Object detail(@PathVariable UUID academy,@PathVariable UUID student) {
        var scope=access.staff(academy); var row=store.one(select()+" and s.id=?",academy,scope.unit(),student);
        if(scope.role().equals("INSTRUCTOR"))store.one("select id from class_template where tenant_id=? and id=? and instructor_id=?",academy,row.get("classId"),scope.user());
        row.put("presences",store.db.queryForList("select c.starts_at as \"startsAt\",t.name from attendance a join class_session c on c.tenant_id=a.tenant_id and c.id=a.session_id join class_template t on t.tenant_id=c.tenant_id and t.id=c.template_id where a.tenant_id=? and a.student_id=? and a.valid order by c.starts_at desc limit 30",academy,student));
        row.put("promotions",store.db.queryForList("select id,belt,degrees,effective_on as \"effectiveOn\" from promotion_event where tenant_id=? and student_id=? order by effective_on desc,created_at desc",academy,student));
        return row;
    }
    public record Assign(@NotNull UUID classId){}
    @PatchMapping("/{student}/class") @Transactional
    public Object assign(@PathVariable UUID academy,@PathVariable UUID student,@Valid @RequestBody Assign input){
        var scope=access.manager(academy);
        store.one("select id from student where tenant_id=? and unit_id=? and id=?",academy,scope.unit(),student);
        store.one("select id from class_template where tenant_id=? and unit_id=? and id=?",academy,scope.unit(),input.classId());
        store.db.update("update membership set primary_class_id=? where tenant_id=? and student_id=? and status<>'CANCELLED'",input.classId(),academy,student);
        store.event(academy,scope.user(),"StudentClassAssigned",student);return Map.of("ok",true);
    }
    public record Pause(@NotNull LocalDate endsOn,@NotBlank @Size(max=80) String reason){}
    @PostMapping("/{student}/pause") @Transactional
    public Object pause(@PathVariable UUID academy,@PathVariable UUID student,@Valid @RequestBody Pause input){
        var scope=access.manager(academy);var s=store.one(select()+" and s.id=? for update of m",academy,scope.unit(),student);
        LocalDate today=today(academy);
        if(!s.get("status").equals("ACTIVE")||input.endsOn().isBefore(today))throw ApiException.invalid("Informe uma pausa válida para um aluno ativo.");
        store.db.update("insert into pause_period(id,tenant_id,membership_id,starts_on,ends_on,reason) values (?,?,?,?,?,?)",UUID.randomUUID(),academy,s.get("membershipId"),today,input.endsOn(),input.reason());
        store.db.update("update membership set status='PAUSED' where tenant_id=? and id=?",academy,s.get("membershipId"));
        store.db.update("update retention_alert set status='SNOOZED',version=version+1 where tenant_id=? and membership_id=? and status<>'CLOSED'",academy,s.get("membershipId"));
        store.event(academy,scope.user(),"StudentPaused",student);return Map.of("ok",true);
    }
    @PostMapping("/{student}/cancel") @Transactional
    public Object cancel(@PathVariable UUID academy,@PathVariable UUID student){
        var scope=access.manager(academy);var s=store.one(select()+" and s.id=? for update of m",academy,scope.unit(),student);
        store.db.update("update membership set status='CANCELLED',ends_on=? where tenant_id=? and id=?",today(academy),academy,s.get("membershipId"));
        store.db.update("update retention_alert set status='CLOSED',close_reason='Cancelamento',closed_at=now(),version=version+1 where tenant_id=? and membership_id=? and status<>'CLOSED'",academy,s.get("membershipId"));
        store.event(academy,scope.user(),"StudentCancelled",student);return Map.of("ok",true);
    }
    public record Promotion(@NotBlank @Size(max=30) String belt,@Min(0) @Max(10) int degrees,@NotNull @PastOrPresent LocalDate effectiveOn,@Min(0) int version){}
    @PostMapping("/{student}/promotions") @Transactional
    public Object promote(@PathVariable UUID academy,@PathVariable UUID student,@Valid @RequestBody Promotion input,@RequestHeader("Idempotency-Key") UUID key){
        var scope=access.scope(academy,"OWNER");
        return store.replay(academy,scope.user(),"promotion:"+student,key,input,()->{
            var s=store.one("select * from student where tenant_id=? and unit_id=? and id=? for update",academy,scope.unit(),student);
            if(((Number)s.get("version")).intValue()!=input.version())throw ApiException.conflict("A graduação mudou. Atualize o perfil.");
            if(!List.of("Branca","Azul","Roxa","Marrom","Preta","Cinza","Amarela","Laranja","Verde","Coral","Vermelha").contains(input.belt()))throw ApiException.invalid("Faixa não configurada.");
            UUID event=UUID.randomUUID();
            store.db.update("insert into promotion_event(id,tenant_id,student_id,previous_belt,previous_degrees,belt,degrees,effective_on,author_id) values (?,?,?,?,?,?,?,?,?)",event,academy,student,s.get("belt"),s.get("degrees"),input.belt(),input.degrees(),input.effectiveOn(),scope.user());
            store.db.update("update student set belt=?,degrees=?,version=version+1 where tenant_id=? and id=?",input.belt(),input.degrees(),academy,student);
            store.event(academy,scope.user(),"PromotionGranted",student);return Map.of("id",event);
        });
    }
    private LocalDate today(UUID tenant){return LocalDate.now(ZoneId.of(store.one("select timezone from academy where id=?",tenant).get("timezone").toString()));}
}
