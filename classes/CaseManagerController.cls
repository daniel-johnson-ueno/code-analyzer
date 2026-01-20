public with sharing class CaseManagerController {

    public class ResultWrapper {
        @AuraEnabled public String mainField { get; set; }
        @AuraEnabled public String subField { get; set; }
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public Map<String, Object> otherFields { get; set; }
    }


    @AuraEnabled(cacheable=false)
    public static List<Group> getExistingQueues() {
        List<Group> lst = new List<Group>();
        lst = [SELECT Id, Name, DeveloperName FROM Group WHERE Type = 'Queue'] ;

        return lst;
    }

    @AuraEnabled(cacheable=false)
    public static List<ResultWrapper> getTipificadores(String product) {
        List<ResultWrapper> result = new List<ResultWrapper>();

        List<Tipificadores__mdt> existingTipificadores = [
                SELECT Id, Key__c, CaseOwnerQueue__c, CaseStatus__c, Reason__c, Product__c, Type__c, RecordType__c
                FROM Tipificadores__mdt
                WHERE TipificadorActive__c = TRUE AND  Product__c =: product
        ];

        for (Tipificadores__mdt tipificador : existingTipificadores) {
            ResultWrapper wrapper = new ResultWrapper();
            wrapper.mainField = tipificador.Key__c;
            wrapper.subField = tipificador.RecordType__c;
            wrapper.id = tipificador.Id;
            wrapper.otherFields = tipificador.getPopulatedFieldsAsMap();
            result.add(wrapper);
        }

        return result;
    }

    @AuraEnabled(cacheable=false)
    public static Contact getPersonAccountContact(String accountId) {

        Account currentAccount = AccountDAO.getAccountById(accountId);
        Contact personContact;

        if(currentAccount.IsPersonAccount == true){
            personContact = [SELECT Id FROM Contact WHERE Id =: currentAccount.PersonContactId];
        }

        return personContact;
    }




}