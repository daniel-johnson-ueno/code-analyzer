public without sharing class ContactBotCustomerController {
    
    public class MissingPersonCodeException extends Exception {}

    public class ContactRequestWrapper {
        @AuraEnabled
        public String caseId { get; set; }
        @AuraEnabled
        public String agentId { get; set; }
        @AuraEnabled
        public String personCode { get; set; }

        public ContactRequestWrapper(String caseId, String agentId, String personCode) {
            this.caseId = caseId;
            this.agentId = agentId;
            this.personCode = personCode;
        }
    }

    public class ContactResponseWrapper {
        @AuraEnabled
        public String status { get; set; }
        @AuraEnabled
        public String eventType { get; set; }
        @AuraEnabled
        public Boolean isError { get; set; }

        public ContactResponseWrapper(String status, String eventType, Boolean isError) {
            this.status = status;
            this.eventType = eventType;
            this.isError = isError;
        }
    }

    @AuraEnabled(Cacheable=false)
    public static ContactResponseWrapper execute(String caseId) {
        
        try{

            HttpRequest req = createRequest(caseId, getAgentId(), getPersonCode(caseId));
            HttpHelper.HttpClientWithRetry httpClient = new HttpHelper.HttpClientWithRetry();
            HttpResponse tResponse = httpClient.doCallout(req);

            return processResponse(req, tResponse);

        } catch (Exception e) {
            System.debug('Error: ' + e + ' Line: ' + e.getLineNumber());
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'ContactBotCustomer', 'execute');
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static HttpRequest createRequest(String caseId, String agentId, String personCode){

        Chatbot_Service_Domain__c domain = Chatbot_Service_Domain__c.getOrgDefaults();
        Web_Service_Endpoint__mdt wsEndpSetting = Web_Service_Endpoint__mdt.getInstance('chatbotPushNotification');
        String endpoint = domain.DomainName__c + wsEndpSetting.path__c;

        ContactRequestWrapper body = new ContactRequestWrapper(caseId, agentId, personCode);
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('apikey', domain.ApiKey__c);
        req.setMethod('POST');
        req.setBody(JSON.serialize(body));
        req.setTimeout(60000);

        return req;
    }

    private static ContactResponseWrapper processResponse(HttpRequest req, HttpResponse res) {
        if(res.getStatusCode() == 200){
            return new ContactResponseWrapper('Success', 'agentContact', false);
        } else if (res.getStatusCode() == 422){
            System.debug('Push notification error response: ' + res);
            GenerateLogEvent.generateIntegrationLogEvent(req, res);
            return new ContactResponseWrapper('Error', 'El usuario ya tiene una conversacion con un Agente', true);
        } else {
            System.debug('Push notification error response: ' + res);
            GenerateLogEvent.generateIntegrationLogEvent(req, res);
            return new ContactResponseWrapper('Error', 'No se pudo contactar al cliente. Error en el servicio', true);
        }
        
    }

    private static String getPersonCode(String caseId){
        
        Case caseInfo = [SELECT Account.PersonCode__c FROM Case WHERE Id = :caseId LIMIT 1];
        
        if(caseInfo.Account.PersonCode__c == null) {
            throw new MissingPersonCodeException();
        }
        return String.valueOf(caseInfo.Account.PersonCode__c);
        
    }

    private static String getAgentId() {
        return UserInfo.getUserId();
    }
}