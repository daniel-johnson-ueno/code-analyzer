public class SearchClientServiceController {
    @AuraEnabled
    public static Id getAccountId(String documentNumber,String documentType){
        AccountWrapperResult result = new AccountWrapperResult();
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
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'SearchClientServiceController', 'getAccountId');
            return null;
        }
        return result.accountId;
    }

    @AuraEnabled
    public static AccountWrapperResult createAccountSF(String documentNumber,String documentType, String firstName, String lastName, String phone,String email, String company){
        List<AccountCreationService.AccountWrapperResult> resultCreation = new List<AccountCreationService.AccountWrapperResult>();
        resultCreation = AccountCreationService.createAccountSF(input(documentNumber, documentType, firstName, lastName, phone, email, company));
        return mapResult(resultCreation);
    }

    public static List<AccountCreationService.AccountWrapperInput> input(String documentNumber,String documentType, String firstName, String lastName, String phone,String email, String company){
        List<AccountCreationService.AccountWrapperInput> requests = new List<AccountCreationService.AccountWrapperInput>();
        AccountCreationService.AccountWrapperInput request = new AccountCreationService.AccountWrapperInput();
        request.recordType = getRecordTypeByDocumentType(documentType);
        request.documentNumber = documentNumber;
        request.documentType = documentType;
        request.firstName = firstName;
        request.lastName = lastName;
        request.phone = phone;
        request.email = email;
        request.company = company;
        request.originOfCreation = 'SF - Buscador de clientes';
        request.originOfLastModification = 'SF - Buscador de clientes';
        requests.add(request);
        return requests;
    }

    public static AccountWrapperResult mapResult(List<AccountCreationService.AccountWrapperResult> resultCreation){
        AccountWrapperResult result = new AccountWrapperResult();
        result.accountId = resultCreation[0].accountId;
        result.success = resultCreation[0].success;
        result.message = resultCreation[0].message;
        result.code = resultCreation[0].code;
        result.isDuplicated = resultCreation[0].isDuplicated;
        result.recordAccounts = resultCreation[0].recordAccounts;
        return result;
    }

    public static String getRecordTypeByDocumentType(String documentType){
        String result = '';
        if(documentType == '6'){
            Schema.RecordTypeInfo recordTypeInfoEmpresa = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('IndustriesBusiness');
            result = recordTypeInfoEmpresa.getRecordTypeId();
        } else {
            Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount');
            result = recordTypeInfo.getRecordTypeId();
        }
        return result;
    }

    @AuraEnabled
    public static Case updateCaseWithAccount(String accountId, String recordId){
            List<Case> caseRecord = [
            SELECT Id, AccountId 
            FROM Case
            WHERE Id =: recordId
            LIMIT 1
            ];
        if(!caseRecord.isEmpty()){
            try{
                caseRecord[0].AccountId = accountId;
                update caseRecord[0];
                return caseRecord[0];
            } catch (Exception e){
                GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'SearchClientServiceController', 'updateCaseWithAccount');
            }
        } 
        return null;
    }

    @AuraEnabled
    public static List<Account> getCompanies() {
        return [SELECT Id,GroupCompaniesUeno__c FROM Account WHERE GroupCompaniesUeno__c != NULL AND RecordType.DeveloperName = 'Vazquez_Group_Company' AND EnabledToAccountCreation__c = true];
    }

    @AuraEnabled
    public static Account getAccountById(String accountId) {
        return AccountDAO.getAccountById(accountId);
    }

    @AuraEnabled
    public static Boolean getPermission(String permissionName) {
        return featureManagement.checkPermission(permissionName);
    }

    public class AccountWrapperResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public String accountId;
        @AuraEnabled public String code;
        @AuraEnabled public Boolean isDuplicated;
        @AuraEnabled public List<Account> recordAccounts;
        public AccountWrapperResult(){}
    }
}