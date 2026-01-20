public with sharing class SegmentationService {
    public class SegmentationWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String segmentationType;
        @AuraEnabled public String value;
    }
    public class AccountInput {
        @InvocableVariable(required=true)
        public String accountId;
    }
    @AuraEnabled(cacheable=false)
    public static SegmentationWrapper getSegmentationData(String accountId) {
        try {
            if (accountId == null) {
                return createEmptySegmentationError('');
            }
            Account account = AccountDAO.getAccountById(accountId);
            if (account == null || account.IsPerson__c == null) {
                return createEmptySegmentationError('');
            }

            String queryParam;
            String type;
            
            if (account.IsPerson__c == false) {
                queryParam = account.DocumentNumber__c;
                system.debug('segmentation request ruc:' + queryParam);
                if (String.isBlank(queryParam)) {
                    return createEmptySegmentationError('');
                }
                type = 'ruc';
            } else {
                queryParam = account.UniqueId__c;
                system.debug('segmentation request gvuserid:' + queryParam);
                if (String.isBlank(queryParam)) {
                    return createEmptySegmentationError('');
                }
                type = 'gvUserId';
            }
            HttpRequest req = createSegmentationRequest(queryParam, type);
            HttpHelper.HttpClientWithRetry httpClient = new HttpHelper.HttpClientWithRetry();
            HttpResponse response = httpClient.doCallout(req);
            SegmentationWrapper result = processResponse(req, response);
            return result;

        } catch (Exception e) {
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'SegmentationService', 'getSegmentation');
            return createEmptySegmentationError('');
        }
    }
    private static HttpRequest createSegmentationRequest(String uniqueId, String type) {
        Ueno_Service_Domain__c domain = Ueno_Service_Domain__c.getOrgDefaults();
        Web_Service_Endpoint__mdt wsEndpSetting = Web_Service_Endpoint__mdt.getInstance('segmentation');
    
        String endpoint = domain.DomainName__c + wsEndpSetting.path__c + '?' + type + '=' + EncodingUtil.urlEncode(uniqueId, 'UTF-8');
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('apikey', domain.ApiKey__c);
        req.setMethod('GET');
        req.setTimeout(60000);
        System.debug('➡️ req: ' + req);
        return req;
    }
    
    

    private static SegmentationWrapper processResponse(HttpRequest req, HttpResponse res) {
        System.debug('➡️ Response: ' + res);
        if (res != null && res.getStatusCode() == 200 && String.isNotBlank(res.getBody())) {
            
            return (SegmentationWrapper) JSON.deserialize(res.getBody(), SegmentationWrapper.class);
        } else {return createEmptySegmentationError();}
    }

    private static SegmentationWrapper createEmptySegmentationError() {
        SegmentationWrapper segment = new SegmentationWrapper();
        segment.id = '';
        segment.segmentationType = '';
        segment.value = '';
        return segment;
    }
    private static SegmentationWrapper createEmptySegmentationError(String message) {
        SegmentationWrapper segment = new SegmentationWrapper();
        segment.id = '0';
        segment.value = message;
        return segment;
    }
}