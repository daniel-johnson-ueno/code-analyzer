public without sharing class HttpHelper {
    public static Boolean doTimeOutExceptionWhenFalse = false; /** Tira excepcion cuando es igual a true*/

    /**
     * si no funciona el callout a la primera intenta hasta 3 veces
    */
    public class HttpClientWithRetry {
        
        public HttpResponse send(HttpRequest request) {
            HttpResponse tResponse;
            Boolean error = false;
            Integer retry = 0;
            Http http = new Http();
            request.setHeader('Connection','keep-alive');
            do{
                try{
                    error = false;
                    tResponse = http.send(request);
                }
                catch(Exception e){

                    if (retry < 4){
                        error = true;
                        retry ++;
                    }else{
                        GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'HttpHelper', 'send');
                        throw e;
                    }
                }
            }while(error);

            return tResponse;
        }

        public HttpResponse doCallout(HttpRequest request) {
            HttpResponse result = new HttpResponse();

            try {
                UUID traceId = UUID.randomUUID();
                request.setHeader('X-Trace-Id', traceId.toString());

                if (HttpHelper.doTimeOutExceptionWhenFalse){
                    Integer generateMathException = 1/0;
                } 

                result = send(request);
                return result;

            } catch (Exception e) {
                GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'HttpHelper', 'doCallout');

                result.setStatusCode(500);
                result.setBody('{"hasError": true, "message": "'+e.getMessage()+'"}');
                return result;
            }
        }
    }

    public class HttpClient {
        Http http = new Http();

        public HttpResponse doCallout(HttpRequest req) {
            HttpResponse response;

            try {
                UUID traceId = UUID.randomUUID();
                req.setHeader('X-Trace-Id', traceId.toString());

                response = http.send(req);
                return response;
            } catch (Exception e) {
                GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'HttpHelper', 'HttpClient');

                System.debug('catch conection');
                System.debug('Line: ' + e.getLineNumber() + ' Ex: ' + e);
                return response;
            }
        }
    }

}