public with sharing class LoanRequestsController {
    public class LoanRequestsResponse {
        @AuraEnabled
        public List<LoanRequest> loans;
    }

    public class LoanRequest {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String currencyType;
        @AuraEnabled
        public Decimal amount;
        @AuraEnabled
        public String state;
        @AuraEnabled 
        public Integer installments;
        @AuraEnabled
        public LoanRequestMetadata metadata;
    }

    public class LoanRequestMetadata {
        @AuraEnabled
        public String provider;
        @AuraEnabled
        public String alias;
    }

    @AuraEnabled(Cacheable=false)
    public static List<LoanRequest> findLoanRequests(String accountId) {
        try {
            String personCode = String.valueOf(AccountDAO.getAccountById(accountId)?.PersonCode__c);

            if (String.isBlank(personCode)) {
                return new List<LoanRequest>();
            }
            
            return getLoanRequests(personCode);

        } catch (Exception e) {
            System.debug('catch ' + e);
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'LoanRequestsController', 'findLoanRequests');
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static List<LoanRequest> getLoanRequests(String personCode){

        Ueno_Service_Domain__c domain = Ueno_Service_Domain__c.getOrgDefaults();
        Web_Service_Endpoint__mdt webserviceEndpointSetting = Web_Service_Endpoint__mdt.getInstance('loanRequests');

        String endpoint = domain.DomainName__c + String.format(webserviceEndpointSetting.path__c, new List<String>{personCode});

        HttpHelper.HttpClientWithRetry httpClient = new HttpHelper.HttpClientWithRetry();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader('Content-Type','application/json');
        req.setHeader('apikey', domain.ApiKey__c);
        req.setMethod('GET');
        req.setTimeout(60000);

        HttpResponse res = httpClient.doCallout(req);


        return proccessResponse(res, req);
    }

    private static List<LoanRequest> proccessResponse(HttpResponse response, HttpRequest req) {
        List<LoanRequest> loanRequests = new List<LoanRequest>();

        if (response != null && response.getStatusCode() == 200 && response.getBody() != null && response.getBody() != '') {
            String responseJSON = response.getBody(); 
            String jsonResponse = responseJSON.replace('currency', 'currencyType');
            
            LoanRequestsResponse loanRequestsResponse = (LoanRequestsResponse) System.JSON.deserialize(jsonResponse, LoanRequestsResponse.class);

            if (loanRequestsResponse != null) {
                loanRequests = loanRequestsResponse.loans;
            }
        } else {
            GenerateLogEvent.generateIntegrationLogEvent(req, response);

        }
       
        return loanRequests;
    }

}