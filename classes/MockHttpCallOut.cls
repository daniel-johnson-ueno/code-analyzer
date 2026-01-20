/**
 * @name               : 
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 
 * @modification date  : 05-12-2024
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : 
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   05-12-2024   Alvaro Gonzales Lapponi   Initial Version
**/
@isTest
global class MockHttpCallOut implements HttpCalloutMock {

    protected Integer statusCode;
    protected String status;
    protected String bodyAsString;
    protected List<String> bodyAsStringList;

    public MockHttpCallOut(Integer code, String status){
        this.statusCode = code;
        this.status = status;
    }

    public MockHttpCallOut(Integer code, String status, String body){
        this.statusCode = code;
        this.status = status;
        this.bodyAsString = body;
    }

    public MockHttpCallOut(Integer code, String status, List<String> jsonList){
        this.statusCode = code;
        this.status = status;
        this.bodyAsStringList = jsonList;
    }



    global HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();

        if(bodyAsString != null){
            res.setHeader('Content-Type', 'application/json');
            res.setBody(bodyAsString);
            res.setStatusCode(statusCode);
            res.setStatus(status);
        }

        if(bodyAsStringList != null && bodyAsStringList.size() > 0){
            res.setHeader('Content-Type', 'application/json');
            res.setBody(bodyAsStringList.remove(0));
            res.setStatusCode(statusCode);
            res.setStatus(status);
        }


        return res;
    }


    public class MultiRequestMock implements HttpCalloutMock {
        Map<String, HttpCalloutMock> requests;
    
        public MultiRequestMock(Map<String, HttpCalloutMock> requests) {
            this.requests = requests;
        }
    
        public HTTPResponse respond(HTTPRequest req) {
        HttpCalloutMock mock = requests.get(req.getEndpoint());
            if (mock != null) {
                return mock.respond(req);
            } else {
                 throw new MultiRequestMockException('HTTP callout not supported for test methods');
            }
        }
    
        public void addRequestMock(String url, HttpCalloutMock mock) {
            requests.put(url, mock);
        }
            
    }

    private class MultiRequestMockException extends Exception {
    }

}