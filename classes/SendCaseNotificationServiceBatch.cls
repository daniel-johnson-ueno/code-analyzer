public class SendCaseNotificationServiceBatch implements Database.Batchable<CaseNotificationRequestDto>,Database.Stateful,Database.AllowsCallouts{

    //public List<DataInput> records;
    public List<CaseNotificationRequestDto> records;
    public SendCaseNotificationServiceBatch(List<CaseNotificationRequestDto> inputRecords) {
        this.records = inputRecords;
    }

    public Iterable<CaseNotificationRequestDto> start(Database.BatchableContext BC) {
        return records;
    }

    public void execute(Database.BatchableContext BC, List<CaseNotificationRequestDto> scope) {

        if(!scope.isEmpty()){
           /* Web_Service_Endpoint__mdt wsEndpSetting = Web_Service_Endpoint__mdt.getInstance('caseNotification');
            Ueno_Service_Domain__c domain = Ueno_Service_Domain__c.getOrgDefaults();
            String endpoint = domain.DomainName__c + wsEndpSetting.path__c;*/
    
            for(CaseNotificationRequestDto caseRequest : scope) {

                HttpRequest req = CustomerNotificationHandler.createNotificationRequest(caseRequest);
               /* HttpRequest req = new HttpRequest();
                req.setEndpoint(endpoint);
                req.setHeader('Content-Type', 'application/json');
                req.setHeader('apikey', domain.ApiKey__c);
                req.setMethod('POST');
                System.debug('SendCaseNotificationBatch: ' + req);

                String requestBody = '{' +
                        '"personCode": "' + dataInput.personCode + '", ' +
                        '"origin": "' + dataInput.caseOrigin + '", ' +
                        '"event": "' + dataInput.brazeEvent + '", ' +
                        '"caseId": "' + dataInput.caseNumber + '", ' +
                        '"typology": {' +
                            '"type": "' + dataInput.typologyType.toLowerCase() +
                            '", "reason": "' + dataInput.typologyReason?.unescapeJava() +
                        '"}' +
                '}';
        
                req.setBody(requestBody);
                req.setTimeout(60000);*/
        
                HttpHelper.HttpClientWithRetry httpClient = new HttpHelper.HttpClientWithRetry();
        
                if (req != null) {
                    HttpResponse tResponse = httpClient.doCallout(req);
                    System.debug('Respuesta: ' + tResponse.getStatusCode());
                    System.debug('Message: ' + tResponse.getBody());
                }
            }
            
        }
        
    }

    public void finish(Database.BatchableContext BC){
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc.getJobId()];
        System.debug('The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.');
    }

    /*public class DataInput {
        public String personCode;
        public String caseOrigin;
        public String caseNumber;
        public String typologyType;
        public String typologyReason;
        public String brazeEvent;

        public DataInput(String personCode, String origin, String caseNumber, String typologyType, String typologyReason, String brazeEvent){

            this.personCode = personCode;
            this.caseOrigin = origin;
            this.caseNumber = caseNumber;
            this.typologyType = typologyType;
            this.typologyReason = typologyReason;
            this.brazeEvent = brazeEvent;

        }
    }*/

}