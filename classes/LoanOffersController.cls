public with sharing class LoanOffersController {
    public class LoanOffersResponse {
        @AuraEnabled
        public List<LoanOffer> loans;
    }
    
    public class LoanOffer{
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String validFrom;
        @AuraEnabled
        public String expirationDate;
        @AuraEnabled
        public String provider;
        @AuraEnabled
        public String lineType;
        @AuraEnabled
        public String currencyType;
        @AuraEnabled
        public LoanOfferLimit limits;
    }

    public class LoanOfferLimit {
        @AuraEnabled
        public Decimal creditAmount;
        @AuraEnabled
        public Decimal installmentsQuantity;
    }

    @AuraEnabled(Cacheable=false)
    public static List<LoanOffer> findLoanOffers(String accountId) {
        try {
            String personCode = String.valueOf(AccountDAO.getAccountById(accountId)?.PersonCode__c);

            if (String.isBlank(personCode)) {
                return new List<LoanOffer>();
            }
            
            return getLoanOffers(personCode);

        } catch (Exception e) {
            System.debug('catch ' + e);
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'LoanOffersController', 'findLoanOffers');
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static List<LoanOffer> getLoanOffers(String personCode){

        Ueno_Service_Domain__c domain = Ueno_Service_Domain__c.getOrgDefaults();
        Web_Service_Endpoint__mdt webserviceEndpointSetting = Web_Service_Endpoint__mdt.getInstance('loanOffers');

        String endpoint = domain.DomainName__c + String.format(webserviceEndpointSetting.path__c, new List<String>{personCode});

        HttpHelper.HttpClientWithRetry httpClient = new HttpHelper.HttpClientWithRetry();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader('Content-Type','application/json');
        req.setHeader('apikey', domain.ApiKey__c);
        req.setMethod('GET');
        req.setTimeout(60000);

        HttpResponse res = httpClient.doCallout(req);

        return processResponse(res, req);
    }

    private static List<LoanOffer> processResponse(HttpResponse response, HttpRequest req) {
        List<LoanOffer> loanOffers = new List<LoanOffer>();

        if (response != null && response.getStatusCode() == 200 && response.getBody() != null && response.getBody() != '') {
            String responseJSON = response.getBody(); 
            String jsonResponse = responseJSON.replace('currency', 'currencyType');
            
            LoanOffersResponse loanOffersResponse = (LoanOffersResponse) System.JSON.deserialize(jsonResponse, LoanOffersResponse.class);

            if (loanOffersResponse != null) {
                loanOffers = loanOffersResponse.loans;
            }
        } else {
            GenerateLogEvent.generateIntegrationLogEvent(req, response);
        }
       
        return loanOffers;
    }
}