package br.com.tatame360.retention;

import br.com.tatame360.shared.Store;
import java.time.*;
import java.time.temporal.ChronoUnit;
import java.util.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class RetentionService {
    private final Store store;
    public RetentionService(Store store){this.store=store;}
    @Transactional public void evaluate(UUID tenant){
        var academy=store.one("select * from academy where id=?",tenant);
        ZoneId zone=ZoneId.of(academy.get("timezone").toString());LocalDate today=LocalDate.now(zone);
        store.db.queryForList("select pg_advisory_xact_lock(hashtextextended(?,0))","retention:"+tenant);
        var memberships=store.db.queryForList("select m.*,s.unit_id,s.name from membership m join student s on s.tenant_id=m.tenant_id and s.id=m.student_id where m.tenant_id=? and m.status<>'CANCELLED'",tenant);
        for(var m:memberships){
            UUID membership=(UUID)m.get("id"),student=(UUID)m.get("student_id");
            boolean paused=m.get("status").equals("PAUSED");
            if(paused){
                int active=store.db.queryForObject("select count(*) from pause_period where tenant_id=? and membership_id=? and ends_on>=?",Integer.class,tenant,membership,today);
                if(active==0){store.db.update("update membership set status='ACTIVE' where tenant_id=? and id=? and status='PAUSED'",tenant,membership);paused=false;}
            }
            LocalDate started=((java.sql.Date)m.get("starts_on")).toLocalDate();
            OffsetDateTime since=today.minusDays(28).atStartOfDay(zone).toOffsetDateTime(),until=today.atStartOfDay(zone).toOffsetDateTime();
            var sessions=store.db.queryForList("select starts_at,status from class_session where tenant_id=? and template_id=? and starts_at>=? and ends_at<? and status<>'CANCELLED'",tenant,m.get("primary_class_id"),since,until);
            var dates=store.db.queryForList("select c.starts_at from attendance a join class_session c on c.tenant_id=a.tenant_id and c.id=a.session_id where a.tenant_id=? and a.student_id=? and a.valid and c.status<>'CANCELLED' and c.starts_at>=? and c.ends_at<? order by c.starts_at",tenant,student,since,until).stream().map(r->((java.sql.Timestamp)r.get("starts_at")).toInstant().atZone(zone).toLocalDate()).toList();
            long completed=sessions.stream().filter(r->r.get("status").equals("COMPLETED")).count();
            double coverage=sessions.isEmpty()?0:completed/(double)sessions.size();
            int recent=(int)dates.stream().filter(d->!d.isBefore(today.minusDays(7))).count(),baseline=dates.size()-recent;
            int days=dates.isEmpty()?999:(int)ChronoUnit.DAYS.between(dates.getLast(),today);
            int pauses=store.db.queryForObject("select count(*) from pause_period where tenant_id=? and membership_id=? and ends_on>=?",Integer.class,tenant,membership,today.minusDays(28));
            boolean enough=ChronoUnit.DAYS.between(started,today)>=28&&!((java.sql.Date)academy.get("collection_started")).toLocalDate().isAfter(today.minusDays(28))&&dates.size()>=3&&coverage>=0.8&&pauses==0;
            int inactive=0;
            for(int w=0;w<2;w++){
                LocalDate low=today.minusDays((w+1)*7),high=today.minusDays(w*7);
                boolean observed=sessions.stream().anyMatch(s->{LocalDate d=((java.sql.Timestamp)s.get("starts_at")).toInstant().atZone(zone).toLocalDate();return !d.isBefore(low)&&d.isBefore(high)&&s.get("status").equals("COMPLETED");});
                if(observed&&dates.stream().noneMatch(d->!d.isBefore(low)&&d.isBefore(high)))inactive++;
            }
            String state=paused?"PAUSED":enough?"SCORED":"INSUFFICIENT_DATA";
            Integer score=enough&&!paused?RetentionRules.calculate(new RetentionRules.Factors(baseline,recent,days,inactive)).score():null;
            String reason=score==null?(paused?"Pausa registrada":"Coletando histórico confiável"):recent+" treino(s) nos últimos 7 dias; média anterior de "+String.format(Locale.forLanguageTag("pt-BR"),"%.1f",baseline/3.0)+" por semana. Última presença há "+days+" dias.";
            var factors=Map.of("baselineCount",baseline,"recentCount",recent,"daysSinceAttendance",days,"inactiveWeeks",inactive,"coverage",coverage,"reason",reason);
            store.db.update("insert into retention_snapshot(id,tenant_id,membership_id,evaluated_on,state,score,factors) values (?,?,?,?,?,?,?::jsonb) on conflict(tenant_id,membership_id,evaluated_on,rule_version) do nothing",UUID.randomUUID(),tenant,membership,today,state,score,store.json(factors));
            boolean newcomer=!paused&&pauses==0&&ChronoUnit.DAYS.between(started,today)>=7&&ChronoUnit.DAYS.between(started,today)<28&&dates.isEmpty()&&sessions.stream().filter(s->s.get("status").equals("COMPLETED")&&!((java.sql.Timestamp)s.get("starts_at")).toInstant().atZone(zone).toLocalDate().isBefore(started)).count()>=2;
            if((score!=null&&score<60)||newcomer){
                int cooldown=store.db.queryForObject("select count(*) from retention_alert where tenant_id=? and membership_id=? and closed_at>now()-interval '7 days'",Integer.class,tenant,membership);
                if(cooldown>0)continue;
                var owner=store.db.queryForList("select user_id from role_assignment where tenant_id=? and unit_id=? and role='OWNER' and active limit 1",tenant,m.get("unit_id"));
                if(owner.isEmpty())continue;
                UUID alert=UUID.randomUUID();
                int inserted=store.db.update("insert into retention_alert(id,tenant_id,membership_id,reason,score,owner_id,due_on) values (?,?,?,?,?,?,?) on conflict(tenant_id,membership_id) where status<>'CLOSED' do nothing",alert,tenant,membership,newcomer?"Aluno novo sem presença registrada. Faça um contato de acolhimento.":reason,score,owner.getFirst().get("user_id"),today.plusDays(2));
                if(inserted>0)store.event(tenant,null,"RetentionAlertOpened",alert);
            }
        }
    }
}
