global with sharing class EndBotMessagingSessionController {
    global class EndBotSessionRequest {
        @InvocableVariable(required=true label='Person Code')
        global Decimal personCode;
    }

    @InvocableMethod(label='EndBotMessagingSession')
    public static void execute(List<EndBotSessionRequest> listRequest) {
        try {
            List<Long> personCodes = new List<Long>();
            for (EndBotSessionRequest request : listRequest) {
                if (request != null && request.personCode != null) {
                    personCodes.add(request.personCode.longValue());
                } else {
                    System.debug('PersonCode inválido: ' + request);
                }
            }

            Integer batchSize = 15;
            Integer totalSize = personCodes.size();

            for (Integer i = 0; i < totalSize; i += batchSize) {
                List<Long> currentBatch = new List<Long>();
                for (Integer j = i; j < Math.min(i + batchSize, totalSize); j++) {
                    currentBatch.add(personCodes[j]);
                }
                System.enqueueJob(new PerformHttpCalloutJob(currentBatch));
            }
        } catch (Exception e) {
            System.debug('Error: ' + e + ' Line: ' + e.getLineNumber());
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'EndBotMessagingSession', 'execute');
            throw new AuraHandledException(e.getMessage());
        }
    }

    global class PerformHttpCalloutJob implements Queueable, Database.AllowsCallouts {
        private List<Long> personCodes;

        public PerformHttpCalloutJob(List<Long> personCodes) {
            this.personCodes = personCodes;
        }

        public void execute(QueueableContext context) {
            for (Long personCode : personCodes) {
                HttpRequest req = createRequest(personCode);
                HttpHelper.HttpClient httpClient = new HttpHelper.HttpClient();
                HttpResponse tResponse = httpClient.doCallout(req);
                processResponse(req, tResponse);
            }
        }
    }

    private static HttpRequest createRequest(Long personCode) {
        Chatbot_Service_Domain__c domain = Chatbot_Service_Domain__c.getOrgDefaults();
        Web_Service_Endpoint__mdt wsEndpSetting = Web_Service_Endpoint__mdt.getInstance('chatbotEndSession');
        String endpoint = domain.DomainName__c + wsEndpSetting.path__c + '/' + personCode;

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('apikey', domain.ApiKey__c);
        req.setMethod('POST');
        req.setBody('{}');
        req.setTimeout(60000);

        return req;
    }

    private static void processResponse(HttpRequest req, HttpResponse res) {
        if (res.getStatusCode() == 200) {
            System.debug('Se cerró la sesión para el cliente ' + res);
        } else {
            System.debug('ERROR al cerrar la sesión para el cliente, response: ' + res);
            GenerateLogEvent.generateIntegrationLogEvent(req, res);
        }
    }
}