/**
 * @name               : shortMessageService
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 12-12-2024
 * @modification date  : 19-12-2024
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Clase de consumo de API para enviar SMS
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   12-12-2024   Alvaro Gonzales Lapponi   Initial Version
**/
public with sharing class shortMessageService {

    /**
    * @description 
    * @author Alvaro Gonzales Lapponi | 12-12-2024 
    * @return Response 
    **/
    public static Response sendSMS(String phone, String message) {
        Response response = new Response();
        try{
            ServiceRequest request = buildRequest(phone, message);
            String body = JSON.serialize(request, true);
            HttpResponse res = makeCallout(body);
            response.serviceResponse = (ServiceResponse) JSON.deserialize(res.getBody(), ServiceResponse.class);
            response.hasException = false;
        } catch(Exception e){
            response.hasException = true;
            response.exceptionInfo = e;
        }
        return response;
    }

    /**
    * @description Método para construir la solicitud
    * @author Alvaro Gonzales Lapponi | 12-12-2024 
    * @param String phone 
    * @param String message 
    * @return ServiceRequest 
    **/
    private static ServiceRequest buildRequest(String phone, String message){
        ServiceRequest request = new ServiceRequest();
        request.customer = new Customer();
        request.customer.phone = phone;
        request.message = message;
        return request;
    }

    /**
    * @description Método para realizar callout
    * @author Alvaro Gonzales Lapponi | 12-12-2024 
    * @param String body 
    * @return HttpResponse 
    **/
    private static HttpResponse makeCallout(String body){
        HttpRequest req = new HttpRequest();
        req.setTimeout(60000);
        req.setEndpoint('callout:kong/cloud/api/bff/care-totems/v2/sms/send');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(body);
        HttpResponse res = new Http().send(req);
        return res;
    }

    public class Response {
        public Boolean hasException;
        public Exception exceptionInfo;
        public ServiceResponse serviceResponse;
    }

    public class ServiceRequest{
        public Customer customer;
        public String message;
    }

    public class Customer{
        public String phone;
    }

    public class ServiceResponse{
        public String status;
        public Integer code;
        public String message;
    }
}