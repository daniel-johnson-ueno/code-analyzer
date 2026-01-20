public with sharing class LogoutExperience {
    
    

    @AuraEnabled
    public static String getTimeCallApexLog() {
        Turnero__mdt meta = [SELECT Field__c  FROM Turnero__mdt WHERE Type__c = 'AutoUpdateCitas' AND MasterLabel = 'RefreshLogout' WITH USER_MODE LIMIT 1];
        return meta.Field__c;
    } 

    @AuraEnabled
    public static void generateDebugLog() {
        system.debug('###### Log Logout Expirience');
        User us = [SELECT id from User WHERE ID =: UserInfo.getUserId()];
        System.debug('IDDDDDD '+us.ID);
    }
}