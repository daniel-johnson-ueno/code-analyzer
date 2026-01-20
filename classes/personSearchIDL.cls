/**
 * @name               : personSearchIDL
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 24-01-2025
 * @modification date  : 29-01-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Clase de consumo de API de BFF isCustomer
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   24-01-2025  Alvaro Gonzales Lapponi   Initial Version
**/
public with sharing class personSearchIDL {
    
    /**
    * @description Busca persona en API de BFF por tipo y número de documento
    * @author Alvaro Gonzales Lapponi | 24-01-2025 
    * @return Response 
    **/
    public static Response searchIsCustomer(String tipoDocumento, String numeroDocumento) {
        Response response = new Response();
        try{
            Map<String,String> documento = new Map<String,String>();
            documento.put(tipoDocumento, numeroDocumento);
            String body = JSON.serialize(documento, true);
            HttpResponse res = makeCallout(body);
            List<ServiceResponse> resultList = (List<ServiceResponse>) JSON.deserialize(res.getBody(), List<ServiceResponse>.class);
            if(!resultList.isEmpty()){
                response.serviceResponse = resultList[0];
            }
            response.hasException = false;
        } catch(Exception e){
            response.hasException = true;
            response.exceptionInfo = e;
        }
        return response;
    }

    /**
    * @description Método para realizar callout
    * @author Alvaro Gonzales Lapponi | 24-01-2025
    * @param String body 
    * @return HttpResponse 
    **/
    private static HttpResponse makeCallout(String body){
        HttpRequest req = new HttpRequest();
        req.setTimeout(60000);
        req.setEndpoint('callout:kong/cloud/api/bff/care-totems/v1/customer/iscustomer');
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
        public String cedulaIdentidad;
    }
    
    public class ServiceResponse{
        public String firstName;
        public String lastName;
        public String cedulaIdentidad;
        public String phone;
        public String email;
        public String customerNumber;
        public CustomerType customerType;
    }
    
    public class CustomerType{
        public Integer id;
    }

}