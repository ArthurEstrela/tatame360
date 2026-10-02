package br.com.tatame360.shared;

public class ApiException extends RuntimeException {
    public final int status;
    public final String code;
    public ApiException(int status, String code, String message) {
        super(message); this.status = status; this.code = code;
    }
    public static ApiException missing() { return new ApiException(404,"NOT_FOUND","Registro não encontrado."); }
    public static ApiException conflict(String message) { return new ApiException(409,"CONFLICT",message); }
    public static ApiException invalid(String message) { return new ApiException(422,"VALIDATION",message); }
}
