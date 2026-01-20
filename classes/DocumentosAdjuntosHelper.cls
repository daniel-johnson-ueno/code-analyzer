public without sharing class DocumentosAdjuntosHelper {

    public class DocumentsWrapper{
        @AuraEnabled public String description {get;set;}
        @AuraEnabled public String url {get;set;}
    }

    public static String getDocumentsByPersonCode(Decimal personCode){
        
        String responseJSON = '';

        HttpHelper.HttpClientWithRetry httpClient = new HttpHelper.HttpClientWithRetry();
        HttpRequest req = createDocumentsRequest(personCode);
        HttpResponse tResponse = httpClient.doCallout(req);

        if(tResponse.getStatusCode() == 200){
            responseJSON = tResponse.getBody();
        } else {
            GenerateLogEvent.generateIntegrationLogEvent(req, tResponse);
        }

        return responseJSON;
    }

    private static HttpRequest createDocumentsRequest(Decimal personCode) {
        Web_Service_Endpoint__mdt wsEndpSetting = Web_Service_Endpoint__mdt.getInstance('customerDocuments');
        Ueno_Service_Domain__c domain = Ueno_Service_Domain__c.getOrgDefaults();

        String endpoint = domain.DomainName__c + wsEndpSetting.path__c + '/' + personCode + '/documents';        
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('apikey', domain.ApiKey__c);
        req.setMethod('GET');
        req.setTimeout(60000);


        return req;
    }
}