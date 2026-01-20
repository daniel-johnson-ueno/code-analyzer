global with sharing class AccountMappingService {

    @InvocableMethod(label='Map Account Data' description='Maps the account data from the provided parameters')
    global static List<AccountMappingResult> mapAccountData(List<AccountMappingRequest> requests) {
        List<AccountMappingResult> results = new List<AccountMappingResult>();

        try{

            for (AccountMappingRequest request : requests) {
                MappingHelper.Wrapper accountWrapper = new MappingHelper.Wrapper();
                SegmentationService.SegmentationWrapper segmentation = SegmentationService.getSegmentationData(request.accountId);

                if(request.personCode != '' && request.personCode != null) {
                    accountWrapper = MappingHelper.getAccountFromBankittiByPersonCode(request.personCode);

                } else {
                    accountWrapper = MappingHelper.getAccountFromBankitti(request.documentId.trim(), request.documentType);
                }
                MappingHelper.setSegmentation(segmentation,request.accountId);
                AccountMappingResult result = new AccountMappingResult();
                result.success = accountWrapper.success;
                result.message = accountWrapper.message;
                result.code = accountWrapper.code;

                if (accountWrapper.success) {
                    result.accountId = accountWrapper.accountId;
                } else {
                    result.accountId = null;
                }

                results.add(result);

            }

        } catch(Exception e) {
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'AccountMappingService', 'mapAccountData');
            return null;
        }

        
        return results;
    }
    
    global class AccountMappingRequest {
        @InvocableVariable(required=false label='Document ID' description='Document ID de la cuenta')
        global String documentId;
        
        @InvocableVariable(required=false label='Document Type' description='Document type de la cuenta')
        global String documentType;

        @InvocableVariable(required=false label='Person Code' description='Person code de la cuenta')
        global String personCode;
        
        @InvocableVariable(required=false label='Account ID' description='Id de la cuenta')
        global String accountId;
    }
    
    global class AccountMappingResult {
        @InvocableVariable(label='Success' description='mapeo exitoso')
        global Boolean success;
        
        @InvocableVariable(label='Message' description='resultado del mapeo')
        global String message;
        
        @InvocableVariable(label='Account' description='cuenta mapeada')
        global String accountId;
        
        @InvocableVariable(label='Code' description='Codigo de error')
        global String code;
        public AccountMappingResult(){}
    }
}