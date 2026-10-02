package br.com.tatame360.members;

import br.com.tatame360.identity.Access;
import br.com.tatame360.shared.*;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.time.*;
import java.util.*;
import org.apache.commons.csv.*;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController @RequestMapping("/api/v1/academies/{academy}/imports")
public class ImportController {
    private final Store store;private final Access access;private final MemberController members;
    public ImportController(Store store,Access access,MemberController members){this.store=store;this.access=access;this.members=members;}
    @PostMapping("/preview") @Transactional
    public Object preview(@PathVariable UUID academy,@RequestParam MultipartFile file) throws IOException {
        var scope=access.manager(academy);
        if(file.getSize()>5*1024*1024)throw ApiException.invalid("O arquivo deve ter até 5 MB.");
        String text=new String(file.getBytes(),StandardCharsets.UTF_8).replace("\uFEFF","");
        String header=text.lines().findFirst().orElse("");char delimiter=header.contains(";")?';':',';
        var format=CSVFormat.DEFAULT.builder().setDelimiter(delimiter).setHeader().setSkipHeaderRecord(true).setTrim(true).get();
        var rows=new ArrayList<Map<String,Object>>();
        try(var parser=CSVParser.parse(text,format)){
            if(!parser.getHeaderMap().keySet().containsAll(List.of("nome","data_inicio")))throw ApiException.invalid("Use as colunas nome e data_inicio (AAAA-MM-DD). Contato opcional: email e telefone.");
            for(var row:parser){
                if(rows.size()>=5000)throw ApiException.invalid("O lote deve ter até 5.000 linhas.");
                String name=row.get("nome"),starts=row.get("data_inicio");
                String email=row.isMapped("email")?row.get("email"):"",phone=row.isMapped("telefone")?row.get("telefone"):"";
                var errors=new ArrayList<String>();
                if(name.isBlank()||name.length()>120)errors.add("Nome obrigatório, até 120 caracteres.");
                try{if(LocalDate.parse(starts).isAfter(LocalDate.now()))errors.add("Data de início futura.");}catch(Exception e){errors.add("Data inválida: use AAAA-MM-DD.");}
                if(email.length()>254||(!email.isBlank()&&!email.matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$")))errors.add("E-mail inválido.");
                if(phone.length()>30)errors.add("Telefone muito longo.");
                boolean duplicate=store.db.queryForObject("select count(*) from student where tenant_id=? and lower(name)=lower(?)",Integer.class,academy,name)>0||rows.stream().anyMatch(r->name.equalsIgnoreCase(r.get("name").toString()));
                rows.add(Map.of("line",row.getRecordNumber()+1,"name",name,"startsOn",starts,"email",email,"phone",phone,"errors",errors,"possibleDuplicate",duplicate));
            }
        }catch(IllegalArgumentException|UncheckedIOException e){throw ApiException.invalid("CSV inválido. Confira delimitadores e aspas.");}
        if(rows.isEmpty())throw ApiException.invalid("O arquivo não possui alunos.");
        UUID id=UUID.randomUUID();
        store.db.update("insert into import_batch(id,tenant_id,author_id,rows_data) values (?,?,?,?::jsonb)",id,academy,scope.user(),store.json(rows));
        return Map.of("id",id,"rows",rows);
    }
    public record Confirm(boolean acceptPossibleDuplicates){}
    @PostMapping("/{id}/confirm") @Transactional
    @SuppressWarnings("unchecked")
    public Object confirm(@PathVariable UUID academy,@PathVariable UUID id,@RequestBody Confirm input){
        var scope=access.manager(academy);
        var batch=store.one("select *,rows_data::text as data from import_batch where tenant_id=? and id=? and author_id=? and created_at>now()-interval '7 days' for update",academy,id,scope.user());
        var rows=(List<Map<String,Object>>)store.parse(batch.get("data").toString());
        if((boolean)batch.get("confirmed"))return Map.of("ok",true,"imported",rows.size());
        if(rows.stream().anyMatch(r->!((List<?>)r.get("errors")).isEmpty()))throw ApiException.invalid("Corrija as linhas inválidas e envie o arquivo novamente.");
        if(!input.acceptPossibleDuplicates()&&rows.stream().anyMatch(r->Boolean.TRUE.equals(r.get("possibleDuplicate"))))throw ApiException.conflict("Revise e confirme os possíveis alunos duplicados.");
        for(var row:rows)members.createStudent(scope,new MemberController.StudentInput(row.get("name").toString(),row.get("email").toString(),row.get("phone").toString(),LocalDate.parse(row.get("startsOn").toString()),null));
        store.db.update("update import_batch set confirmed=true where tenant_id=? and id=?",academy,id);
        store.event(academy,scope.user(),"ImportConfirmed",id);return Map.of("ok",true,"imported",rows.size());
    }
}
