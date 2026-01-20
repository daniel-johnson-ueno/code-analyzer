public with sharing class FinancialInformationController {

    @AuraEnabled
    public static List<Informacion_Financiera__c> getCompanyFinancialInfo (String accountId){

        List<Informacion_Financiera__c> informacionFinanciera = new List<Informacion_Financiera__c>();

        try {
            informacionFinanciera = AccountDAO.getCompanyFinancialInfo(accountId);

        } catch (Exception e) {
            System.debug(e);
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'FinancialInformationController', 'getCompanyFinancialInfo');
            throw new AuraHandledException(e.getMessage());

        }

        return informacionFinanciera;
    }

}