public with sharing class RefundHistoryController {

    public class RefundHistoryWrapper {
        @AuraEnabled
        public String description = '';
        @AuraEnabled
        public String store = '';
        @AuraEnabled
        public String refundDate = '';
        @AuraEnabled
        public Decimal amount = 0;
    }

    @AuraEnabled
    public static List<RefundHistoryWrapper> getRefundHistory(String accountId) {
        try {
            String personCode = String.valueOf(AccountDAO.getAccountById(accountId)?.PersonCode__c);

            if (String.isBlank(personCode)) {
                return new List<RefundHistoryWrapper>();
            }

            HttpRequest req = createHistoryRefundRequest(personCode);
            HttpHelper.HttpClientWithRetry httpClient = new HttpHelper.HttpClientWithRetry();
            HttpResponse tResponse = httpClient.doCallout(req);

            return processResponse(req, tResponse);

        } catch (Exception e) {
            System.debug('Error: ' + e + ' Line: ' + e.getLineNumber());
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'RefundHistoryController', 'getRefundHistory');
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static HttpRequest createHistoryRefundRequest(String personCode) {
        Ueno_Service_Domain__c domain = Ueno_Service_Domain__c.getOrgDefaults();
        Web_Service_Endpoint__mdt wsEndpSetting = Web_Service_Endpoint__mdt.getInstance('refundHistory');
        String endpoint = domain.DomainName__c + wsEndpSetting.path__c + personCode;

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('apikey', domain.ApiKey__c);
        req.setMethod('GET');
        req.setTimeout(60000);

        return req;
    }

    private static List<RefundHistoryWrapper> processResponse(HttpRequest req, HttpResponse tResponse) {
        List<RefundHistoryWrapper> wrapperList = new List<RefundHistoryWrapper>();

        if (tResponse != null && tResponse.getStatusCode() == 200) {
            String responseJSON = tResponse.getBody();
            System.debug(responseJSON);

            String jsonResponse = responseJSON.replace('date', 'refundDate');
            wrapperList = (List<RefundHistoryWrapper>) JSON.deserialize(jsonResponse, List<RefundHistoryWrapper>.class);

            for (RefundHistoryWrapper wrapper : wrapperList) {
                wrapper.description = wrapper.description != null ? wrapper.description : '';
                wrapper.store = wrapper.store != null ? wrapper.store : '';
                wrapper.refundDate = getDateValue(wrapper.refundDate != null ? wrapper.refundDate : '');
                wrapper.amount = wrapper.amount != null ? wrapper.amount : 0;
            }
        } else {
            GenerateLogEvent.generateIntegrationLogEvent(req, tResponse);
            return new List<RefundHistoryWrapper>();
        }

        return wrapperList;
    }

    public static String getDateValue(String dateValue) {
        String result;
        if (String.isNotBlank(dateValue)) {
            List<String> timeParts = dateValue.split(' ');
            List<String> dateParts = timeParts[0].split('-');
            result = dateParts.size() == 3 ? dateParts[2].trim() + '/' + dateParts[1].trim() + '/' + dateParts[0].trim() : null;
        } else {
            result = null;
        }
        return result;
    }
}