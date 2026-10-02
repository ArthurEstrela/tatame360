package br.com.tatame360.retention;

import br.com.tatame360.shared.Store;
import java.time.*;
import java.util.UUID;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.slf4j.LoggerFactory;

@Component
public class RetentionJob {
    private final Store store;private final RetentionService service;
    public RetentionJob(Store store,RetentionService service){this.store=store;this.service=service;}
    @Scheduled(initialDelay=15000,fixedDelay=3600000)
    public void run(){
        for(var academy:store.db.queryForList("select id,timezone from academy")){
            if(ZonedDateTime.now(ZoneId.of(academy.get("timezone").toString())).getHour()<3)continue;
            try{service.evaluate((UUID)academy.get("id"));}
            catch(Exception e){LoggerFactory.getLogger(getClass()).error("Retention evaluation failed for tenant {}",academy.get("id"),e);}
        }
    }
}
