public with sharing class UpdateAccountController {
    
    public class UpdateAccountResponseWrapper {
        @AuraEnabled
        public Boolean hasError;
        @AuraEnabled
        public String errorMessage;
        @AuraEnabled
        public String errorCode;
    }
    
    @AuraEnabled(Cacheable = false)
    public static UpdateAccountResponseWrapper updateAccountCallout(String documentNumber, String documentType, String accountId) {
        UpdateAccountResponseWrapper response = new UpdateAccountResponseWrapper();
        response.hasError = false;
        response.errorMessage = null;
        response.errorCode = null;

        try {
            
            List<AccountMappingService.AccountMappingResult> results = AccountMappingService.mapAccountData(createRequest(documentNumber, documentType, accountId));
            if (results.isEmpty() || !results[0].success) {
                response.hasError = true;
                response.errorMessage = results.isEmpty() ? 'Unknown error' : results[0].message;
                response.errorCode = results[0].code;
            }
        } catch (Exception e) {
            response.hasError = true;
            response.errorMessage = e.getMessage();
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'UpdateAccountController', 'updateAccountCallout');
        }
        
        return response;
    }

    private static List<AccountMappingService.AccountMappingRequest> createRequest(String documentNumber, String documentType, String accountId){
        List<AccountMappingService.AccountMappingRequest> requests = new List<AccountMappingService.AccountMappingRequest>();
        AccountMappingService.AccountMappingRequest request = new AccountMappingService.AccountMappingRequest();
        request.documentId = documentNumber;
        request.documentType = documentType;
        request.accountId = accountId;
        requests.add(request);
        
        return requests;
    }
}