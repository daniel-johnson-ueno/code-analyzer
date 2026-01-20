@isTest
public class CaseRemoteSiteConnectionMock implements HttpCalloutMock {
    protected Integer code;
    protected String type;
    protected String message;
    protected String bodyAsString;
    private Map<String, Object> mockResponse;

    public CaseRemoteSiteConnectionMock(Integer code, String type, String message, String body) {
        this.code = code;
        this.type = type;
        this.message = message;
        this.bodyAsString = body;
    }

    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse resp = new HttpResponse();
        resp.setStatusCode(code);
        resp.setBody(bodyAsString);
        return resp;
    }

    public static String getVoucher_Founded() {
        return  '{'+
                '    "id": "TD23173307",'+
                '    "code": "23173307",'+
                '    "type": "TD",'+
                '    "date": "2025-01-08",'+
                '    "account": 619939412,'+
                '    "customer": 8112425,'+
                '    "store": "LACTOLANDA-ABASTO CENT",'+
                '    "amount": 298650.00'+
                '}';
    }
    public static String getVoucher_NotFound() {
        return '{"code":400, "description": "Invalid paramater"}';
    }
    public static String getVoucher_Bad() {
        return '{"code": 500, "description": "Internal error"}';
    }
}