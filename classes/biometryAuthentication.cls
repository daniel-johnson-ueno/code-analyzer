/**
 * @name               : biometryAuthentication
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 05-12-2024
 * @modification date  : 05-12-2024
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Clase de consumo API para obtener token de Biometría
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   04-12-2024   Alvaro Gonzales Lapponi   Initial Version
**/
public with sharing class biometryAuthentication {
	
    /**
    * @description Método para obtener token de biometría
    * @author Alvaro Gonzales Lapponi | 05-12-2024 
    **/
    public static Response getToken() {
        Response response = new Response();
        try{
            String body =   'username=' + '{!$Credential.biometryAuthentication.username}' +
                            '&password=' + '{!$Credential.biometryAuthentication.password}';
            HttpRequest req = new HttpRequest();
            req.setTimeout(60000);
            req.setEndpoint('callout:biometry/user.php/auth/login');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.setBody(body);
            HttpResponse res = new Http().send(req);
            response.serviceResponse = (ServiceResponse) JSON.deserialize(res.getBody(), biometryAuthentication.ServiceResponse.class);
            response.hasException = false;
        } catch(Exception e){
            response.hasException = true;
            response.exceptionInfo = e;
        }
        return response;
    }


    public class Response {
        public Boolean hasException;
        public Exception exceptionInfo;
        public ServiceResponse serviceResponse;
    }

    public class ServiceResponse {
        public String access_token;
    }
}