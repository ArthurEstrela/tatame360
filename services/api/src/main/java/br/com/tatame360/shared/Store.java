package br.com.tatame360.shared;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import java.util.*;
import java.security.MessageDigest;
import java.nio.charset.StandardCharsets;

@Component
public class Store {
    public final JdbcTemplate db;
    public final ObjectMapper json;
    public Store(JdbcTemplate db,ObjectMapper json) { this.db=db; this.json=json; }
    public Map<String,Object> one(String sql,Object... args) {
        var rows=db.queryForList(sql,args); if(rows.isEmpty()) throw ApiException.missing(); return rows.getFirst();
    }
    public String json(Object value) { try {return json.writeValueAsString(value);} catch(JsonProcessingException e){throw new IllegalStateException(e);} }
    public Object parse(String value) { try{return json.readValue(value,Object.class);}catch(JsonProcessingException e){throw new IllegalStateException(e);} }
    public static String hash(String value) {
        try{return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8)));}
        catch(Exception e){throw new IllegalStateException(e);}
    }
    public void event(UUID tenant,UUID author,String type,UUID resource) {
        db.update("insert into audit_event(id,tenant_id,author_id,action,resource_id) values (?,?,?,?,?)",UUID.randomUUID(),tenant,author,type,resource);
        db.update("insert into outbox_event(id,tenant_id,event_type,resource_id) values (?,?,?,?)",UUID.randomUUID(),tenant,type,resource);
    }
    // Transaction-scoped advisory lock serializes concurrent replays before checking the record.
    public Object replay(UUID tenant,UUID user,String operation,UUID key,Object payload,java.util.function.Supplier<Object> action) {
        String identity=tenant+":"+user+":"+operation+":"+key;
        db.queryForList("select pg_advisory_xact_lock(hashtextextended(?,0))",identity);
        String fingerprint=hash(json(payload));
        var previous=db.queryForList("select payload_hash,response::text from idempotency_record where tenant_id=? and user_id=? and operation=? and key=?",tenant,user,operation,key);
        if(!previous.isEmpty()) {
            if(!fingerprint.equals(previous.getFirst().get("payload_hash"))) throw ApiException.conflict("Esta operação já foi usada com outros dados.");
            return parse(previous.getFirst().get("response").toString());
        }
        Object result=action.get();
        db.update("insert into idempotency_record(tenant_id,user_id,operation,key,payload_hash,response) values (?,?,?,?,?,?::jsonb)",tenant,user,operation,key,fingerprint,json(result));
        return result;
    }
}
