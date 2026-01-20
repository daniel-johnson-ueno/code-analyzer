public class CaseRemoteSiteConection {
    public static HttpResponse getVoucher(String PaymentMethod, String OperationNumber, String idCase){
        
        Web_Service_Endpoint__mdt wsEndpSetting = Web_Service_Endpoint__mdt.getInstance('GetVoucher');
        Ueno_Service_Domain__c service = Ueno_Service_Domain__c.getOrgDefaults();

        String endpoint = service.DomainName__c + wsEndpSetting.path__c + PaymentMethod + OperationNumber;
        
        
        HttpHelper.HttpClient httpClient = new HttpHelper.HttpClient();
        HttpRequest request;
        HttpResponse response;
        
        try{
            request = createRequest(endpoint, service);
            response = httpClient.doCallout(request);

            if (response.getStatusCode() == 200) {
                String jsonResponse = response.getBody();
                Refund_Audit__c audit = new Refund_Audit__c();
                audit.Related_Case__c = idCase;
                audit.ServiceName__c = service.DomainName__c;
                audit.Receipt_Number__c = OperationNumber;
                audit.Payload__c = response.getBody();
                insert audit;
            } else {
                Integration_Log__c log = new Integration_Log__c();
                log.EndPoint__c = endpoint;
                log.Response__c = response.getBody();
                log.Response_Status_Code__c = response.getStatusCode();
                log.Request__c = request.getBody();
                insert log;
            }
        }catch(Exception e){
            Integration_Log__c log = new Integration_Log__c();
            log.Response__c = endpoint + ' ' + response.getBody()+' Error: ' + e.getMessage();
            insert log;
            return null;
        }
        return response;
    }

    private static HttpRequest createRequest(String endpoint, Ueno_Service_Domain__c service){
        HttpRequest request = new HttpRequest();
        System.debug(endpoint);
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setHeader('x-forwarded-for','13.108.0.0');
        request.setHeader('apikey', service.ApiKey__c);
        return request;
    }
}