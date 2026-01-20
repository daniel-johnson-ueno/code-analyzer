/**
 * @description       : 
 * @author            : marco.casanova@vurpix.com
 * @TKs               : 
 * @group             : 
 * @last modified on  : 06-13-2024
 * @last modified by  : marco.casanova@vurpix.com
**/
public without sharing class ProductsController {
    @AuraEnabled
    public static Account getAccount(String recordId){
        Id recordIdCase = recordId;
        if(recordIdCase.getSObjectType().getDescribe().getName() == 'Case') recordId = [SELECT Id, AccountId FROM Case WHERE Id =: recordId LIMIT 1].AccountId;
        Account acc = [SELECT Id, PersonCode__c, IsEmployee__c FROM Account WHERE Id =: recordId LIMIT 1];
        return acc;
    }
}