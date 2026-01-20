public with sharing class AccountMappingServiceLWC {
    @AuraEnabled
    public static Id getAccountId(String documentNumber,String documentType){
        AccountMappingResult result = new AccountMappingResult();
        try {
            MappingHelper.Wrapper accountWrapper = MappingHelper.getAccountFrombankitti(documentNumber, documentType);
                result.success = accountWrapper.success;
                result.message = accountWrapper.message;
                result.code = accountWrapper.code;

                if (accountWrapper.success) {
                    result.accountId = accountWrapper.accountId;
                } else {
                    result.accountId = null;
                }
        } catch(Exception e) {
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'AccountMappingService', 'mapAccountData');
            return null;
        }
        return result.accountId;
    }

    private class AccountMappingResult {
        private Boolean success;
        private String message;
        private String accountId;
        private String code;
        public AccountMappingResult(){}
    }
}