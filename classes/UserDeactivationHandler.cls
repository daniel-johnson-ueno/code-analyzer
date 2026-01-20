/**
 * @description       : 
 * @author            : Noe Vasquez
 * @group             : 
 * @last modified on  : 06-04-2025
 * @last modified by  : Noe Vasquez
**/
public with sharing class UserDeactivationHandler {
    /**
     *  @description: Se realiza @future por las operaciones DML que se realizan en este metodo
     * 
     */
    @future
    public static void processDeactivatedUsers(Set<Id> deactivatedUserIds) {
        try {
            Map<Id, User> inactiveUsers = new Map<Id, User>();
            for (User u : [
                SELECT Id, Email FROM User
                WHERE Id IN :deactivatedUserIds
                AND IsActive = false
            ]) {
                inactiveUsers.put(u.Id, u);
            }
        
            Set<String> inactiveEmails = new Set<String>();
            for (User u : inactiveUsers.values()) {
                if (u.Email != null) inactiveEmails.add(u.Email);
            }
        
            if (inactiveEmails.isEmpty()) {
                return;
            }
        
            Map<Id, Id> userToNewOwnerMap = new Map<Id, Id>();
        
            List<Contact> matchingContacts = [
                SELECT Id, Email, Account.Name,  Account.Manager_UenoX__r.Email, SecondaryOffice__r.Manager_UenoX__r.Email
                FROM Contact
                WHERE RecordType.DeveloperName = 'Internal_Contact'
                AND Email IN :inactiveEmails
            ];
        
            Map<String, String> userEmailToManagerEmail = new Map<String, String>();
            for (Contact c : matchingContacts) {
                if (c.Email != null && c.Account != null && c.Account.Manager_UenoX__r != null) {
                    userEmailToManagerEmail.put(c.Email, c.Account.Manager_UenoX__r.Email);
                }
            }
        

            Set<String> gerenteEmails = new Set<String>(userEmailToManagerEmail.values());

            Map<String, Id> gerenteEmailToUserId = new Map<String, Id>();
            for (User u : [
                SELECT Id, Email FROM User
                WHERE Email IN :gerenteEmails
            ]) {
                gerenteEmailToUserId.put(u.Email, u.Id);
            }

            for (Id userId : inactiveUsers.keySet()) {
                String email = inactiveUsers.get(userId).Email;
                if (userEmailToManagerEmail.containsKey(email)) {
                    String gerenteEmail = userEmailToManagerEmail.get(email);
                    if (gerenteEmailToUserId.containsKey(gerenteEmail)) {
                        userToNewOwnerMap.put(userId, gerenteEmailToUserId.get(gerenteEmail));
                    }
                }
            }

            if (userToNewOwnerMap.isEmpty()) {
                return;
            }

            if (gerenteEmailToUserId.isEmpty()) {
                return;
            }
        
            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            List<Lead> leadsToUpdate = new List<Lead>();
        
            List<Opportunity> filteredOpps = new List<Opportunity>();

            //Unicamente toma en cuenta las opps que están abiertas (No son Closed)
            for (Opportunity opp : [
                SELECT Id, OwnerId, IsClosed
                FROM Opportunity
                WHERE OwnerId IN :userToNewOwnerMap.keySet()
            ]) {
                if(!opp.IsClosed) {
                    opp.OwnerId = userToNewOwnerMap.get(opp.OwnerId);
                    oppsToUpdate.add(opp);                }
            }
        
            for (Lead lead : [
                SELECT Id, OwnerId
                FROM Lead
                WHERE OwnerId IN :userToNewOwnerMap.keySet()
                AND Status IN ('Nuevo','Asignado','En curso')
            ]) {
                lead.OwnerId = userToNewOwnerMap.get(lead.OwnerId);
                leadsToUpdate.add(lead);
            }
        
            updateRecordsWithLogging(oppsToUpdate, 'UserDeactivationHandler', 'processDeactivatedUsers');
            updateRecordsWithLogging(leadsToUpdate, 'UserDeactivationHandler', 'processDeactivatedUsers');
        }
        catch(Exception ex) {
            GenerateLogEvent.generateErrorLogEvent(ex, UserInfo.getUserId(), 'UserDeactivationHandler', 'processDeactivatedUsers');
        }
    }

    private static void updateRecordsWithLogging(List<SObject> recordsToUpdate, String className, String methodName) {
        if (recordsToUpdate.isEmpty()) return;

        Database.SaveResult[] results = Database.update(recordsToUpdate, false);
        for (Database.SaveResult sr : results) {
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    System.debug('Error en registro: ' + err.getMessage());
                    CustomLogException ex = new CustomLogException(err.getStatusCode() + ': ' + err.getMessage());
                    GenerateLogEvent.generateErrorLogEvent(ex, UserInfo.getUserId(), className, methodName);
                }
            }
        }
    }
    public class CustomLogException extends Exception {}
}