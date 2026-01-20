public with sharing class LoyaltyController {


    public class LoyaltyWrapper {
        @AuraEnabled
        public Integer balance;
        @AuraEnabled
        public TierWrapper tier;
        @AuraEnabled
        public String errorMessage;
        @AuraEnabled
        public Boolean hasError;

    }

    public class TierWrapper {
        @AuraEnabled
        public Integer id;
        @AuraEnabled
        public Integer businessUnitId;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public Integer level;
        @AuraEnabled
        public String minimumPoints;
        @AuraEnabled
        public String maximumPoints;

    }

    @AuraEnabled(Cacheable=false)
    public static LoyaltyWrapper loyaltyCallout(String accountId) {
    try {
        String uniqueId = AccountDAO.getAccountById(accountId)?.UniqueId__c;
        if (String.isBlank(uniqueId)) {
            String msg = System.Label.loyaltyErrorMessageUniqueId;
            return createEmptyLoyaltyError(msg);
        }

        HttpRequest req = createLoyaltyRequest(uniqueId);
        HttpHelper.HttpClientWithRetry httpClient = new HttpHelper.HttpClientWithRetry();
        HttpResponse tResponse = httpClient.doCallout(req);
        return processResponse(req, tResponse);
    } catch (Exception e) {
        System.debug('catch ' + e);
        GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'LoyaltyController', 'LoyaltyCallout');
        throw new AuraHandledException(e.getMessage());
    }
}

    private static LoyaltyWrapper processResponse(HttpRequest req, HttpResponse tResponse) {
        LoyaltyWrapper loyalty = new LoyaltyWrapper();
        String msgError;
        if (tResponse != null && tResponse.getStatusCode() == 200 && tResponse.getBody() != null && tResponse.getBody() != '') {
            String responseJSON = tResponse.getBody();
            loyalty = (LoyaltyWrapper) System.JSON.deserialize(responseJSON, LoyaltyWrapper.class);
        } else if(tResponse.getStatusCode() != 200) {
            GenerateLogEvent.generateIntegrationLogEvent(req, tResponse);
            msgError = System.label.loyaltyErrorMessage;
            loyalty = createEmptyLoyaltyError(msgError);
        } else {
            loyalty = createEmptyLoyaltyError('No se encontraron puntos de Loyalty para este cliente.');
        }

        return loyalty;
    }

    private static HttpRequest createLoyaltyRequest(String uniqueId){

        Ueno_Service_Domain__c domain = Ueno_Service_Domain__c.getOrgDefaults();
        Web_Service_Endpoint__mdt wsEndpSetting = Web_Service_Endpoint__mdt.getInstance('loyaltyLWC');
        String endpoint = domain.DomainName__c + wsEndpSetting.path__c + '/member/'+ uniqueId;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader('Content-Type','application/json');
        req.setHeader('apikey', domain.ApiKey__c);
        req.setMethod('GET');
        req.setTimeout(60000);

        return req;
    }

    private static LoyaltyWrapper createEmptyLoyaltyError(String message) {
        LoyaltyWrapper loyalty = new LoyaltyWrapper();
        loyalty.balance = 0;
        loyalty.tier = new TierWrapper();
        loyalty.tier.level = 1;
        loyalty.tier.maximumPoints = '2999';
        loyalty.tier.minimumPoints = '0';
        loyalty.errorMessage = message;
        loyalty.hasError = true;
        return loyalty;
    }
}