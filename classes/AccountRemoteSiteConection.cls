public class AccountRemoteSiteConection {
    // Método para consumir el servicio y procesar el JSON
    public static HttpResponse getAccountFromBankitti(Map<String,String> parametersMap){
           
        Web_Service_Endpoint__mdt wsEndpSetting = Web_Service_Endpoint__mdt.getInstance('production_service');
        Ueno_Service_Domain__c service = Ueno_Service_Domain__c.getOrgDefaults();        

        String endpoint = service.DomainName__c + wsEndpSetting.path__c;    
        endpoint = addParametersToEndpoint(endpoint, parametersMap);
        
        HttpHelper.HttpClient httpClient = new HttpHelper.HttpClient();
        HttpRequest request;
        HttpResponse response;
        
        try{

            request = createPersonRequest(parametersMap, endpoint, service);
            response = httpClient.doCallout(request);

            if (response.getStatusCode() == 200) {
                String jsonResponse = response.getBody();

            } else {
                GenerateLogEvent.generateIntegrationLogEvent(request, response);
            }

        }catch(Exception e){
            System.debug('catch connection');
            System.debug('Line: ' + e.getLineNumber() + ' Ex: ' + e);
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'AccountRemoteSiteConection', 'getAccountFromBankitti');

            return null;
        }
        return response;
    }

    private static HttpRequest createPersonRequest(Map<String,String> parametersMap, String endpoint, Ueno_Service_Domain__c service){
        HttpRequest request = new HttpRequest();
        System.debug(endpoint);
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setHeader('Content-Type','application/json');
        request.setHeader('apikey', service.ApiKey__c);
        request.setTimeout(60000);
        return request;
    }
    
    public static String addParametersToEndpoint(String endpoint, Map<String,String> parameters){//crear method en helper
        endpoint += '?';
        Integer sizeMap = parameters.keySet().size();
        Integer cont = 1;
        for(String key : parameters.keySet()) {
            String value = parameters.get(key);
            endpoint += key + '=' + value;
            if(cont != sizeMap){
                endpoint += '&';
            }
            cont ++;
        }
        endpoint.replaceall(' ','%20');
        return endpoint;
    }
}