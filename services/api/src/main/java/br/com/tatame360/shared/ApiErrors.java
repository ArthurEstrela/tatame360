package br.com.tatame360.shared;

import java.util.*;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

@RestControllerAdvice
public class ApiErrors {
    @ExceptionHandler(ApiException.class)
    ResponseEntity<?> domain(ApiException e) { return response(e.status,e.code,e.getMessage(),List.of()); }
    @ExceptionHandler(MethodArgumentNotValidException.class)
    ResponseEntity<?> invalid(MethodArgumentNotValidException e) {
        return response(422,"VALIDATION","Revise os campos informados.",e.getBindingResult().getFieldErrors().stream()
            .map(f -> Map.of("field",f.getField(),"message",Objects.toString(f.getDefaultMessage(),"Inválido"))).toList());
    }
    @ExceptionHandler(DataIntegrityViolationException.class)
    ResponseEntity<?> conflict() { return response(409,"CONFLICT","O registro conflita com dados existentes. Atualize e tente novamente.",List.of()); }
    @ExceptionHandler({HttpMessageNotReadableException.class,MethodArgumentTypeMismatchException.class})
    ResponseEntity<?> format() { return response(400,"INVALID_FORMAT","Formato de dados inválido.",List.of()); }
    private ResponseEntity<?> response(int status,String code,String message,Object fields) {
        return ResponseEntity.status(status).body(Map.of("code",code,"message",message,"fieldErrors",fields,"requestId",UUID.randomUUID().toString()));
    }
}
