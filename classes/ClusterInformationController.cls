public class ClusterInformationController {
    
    @AuraEnabled
    public static ClusterInfoWrapper clusterCallout(String recordId){
        ClusterInfoWrapper resultWrapper = new ClusterInfoWrapper();
        String uniqueId = AccountDAO.getAccountById(recordId)?.UniqueId__c;
        if (String.isBlank(uniqueId)) {
            return createEmptyClusterInfo();
        }
        HttpHelper.HttpClientWithRetry httpClient = new HttpHelper.HttpClientWithRetry();
        HttpResponse tResponse = httpClient.doCallout(createRequest(uniqueId));
        String responseJSON = tResponse.getBody();
        System.debug('@@@@tResponse.getStatusCode(): '+ tResponse.getStatusCode());
        System.debug('@@@@responseJSON: '+ responseJSON);
        //String responseJSON = '{"_Id":"12312321","cod_persona":"213","nombreCluster":"SIN MOVIMIENTOS EN CAH"}';
        
        if(tResponse.getStatusCode() == 200){
            String clusterName = getClusterInfo(responseJSON);
            resultWrapper.cluster = clusterName;
            resultWrapper.hasError = false;
            resultWrapper.errorMessage = '';
        } else {
            System.debug('Error: ' + tResponse.getStatusCode() + ' - ' + tResponse.getBody());
            return createEmptyClusterInfo();
        }
    
        return resultWrapper;
    }

    private static ClusterInfoWrapper createEmptyClusterInfo() {
        ClusterInfoWrapper resultWrapper = new ClusterInfoWrapper();
        resultWrapper.hasError = true;
        resultWrapper.errorMessage = 'Sin información de Cluster';
        return resultWrapper;
    }


    private static HttpRequest createRequest(String uniqueId){
        Web_Service_Endpoint__mdt wsEndpSetting;
        Ueno_Service_Domain__c domain = Ueno_Service_Domain__c.getOrgDefaults(); 
        wsEndpSetting = Web_Service_Endpoint__mdt.getInstance('clusterService');
        List<String> parameters = new List<String>();
        parameters.add(uniqueId);
        String append =  String.format(wsEndpSetting.path__c,parameters);
        String endpoint = domain.DomainName__c + append;
        System.debug(endpoint);
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);      
        req.setHeader('Content-Type','application/json');
        req.setHeader('apikey', domain.ApiKey__c);
        req.setMethod('GET');
        req.setTimeout(60000);
        return req;
    }

    public static String getClusterInfo(String clusterJsonResponse){
        String result;
        Map<String, Object> clusterMap = (Map<String, Object>) JSON.deserializeUntyped(clusterJsonResponse);
        return (String) clusterMap.get('clusterName');
    }

    public class ClusterInfoWrapper{
        @AuraEnabled
        public String cluster {get;set;}
        @AuraEnabled
        public Boolean hasError {get;set;}
        @AuraEnabled
        public String errorMessage {get;set;}
    }
}