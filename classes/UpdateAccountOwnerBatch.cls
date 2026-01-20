/**
 * @description       : 
 * @author            : Noe Vasquez
 * @group             : 
 * @last modified on  : 03-31-2025
 * @last modified by  : Noe Vasquez
**/
global class UpdateAccountOwnerBatch implements Database.Batchable<SObject>, Schedulable {

    global void execute(SchedulableContext sc) {
        // Llamar al batch dentro del scheduler
        Database.executeBatch(this, 200);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(
            'SELECT Id, OwnerId, AccountExecutiveEmail__c, Owner.Email FROM Account WHERE AccountExecutiveEmail__c != null'
        );
    }

    global void execute(Database.BatchableContext BC, List<Account> scope) {
        List<Account> filteredAccounts = new List<Account>();
        Set<String> emailsToFind = new Set<String>();

        // Filtrar cuentas cuyo AccountExecutiveEmail__c no coincide con el Owner.Email
        for (Account acc : scope) {
            System.debug('acc.AccountExecutiveEmail__c: ' + acc.AccountExecutiveEmail__c);
            System.debug('acc.Owner.Email: ' + acc.Owner.Email);
            if (acc.Owner != null && acc.AccountExecutiveEmail__c != acc.Owner.Email) {
                filteredAccounts.add(acc);
                emailsToFind.add(acc.AccountExecutiveEmail__c);
            }
        }

        // Si no hay cuentas a actualizar, salir del método
        if (filteredAccounts.isEmpty()) {
            return;
        }

        Map<String, Id> emailToUserIdMap = new Map<String, Id>();
        for (User u : [SELECT Id, Email FROM User WHERE Email IN :emailsToFind AND IsActive = TRUE]) {
            emailToUserIdMap.put(u.Email, u.Id);
        }

        List<Account> accountsToUpdate = new List<Account>();

        for (Account acc : filteredAccounts) {
            if (emailToUserIdMap.containsKey(acc.AccountExecutiveEmail__c)) {
                acc.OwnerId = emailToUserIdMap.get(acc.AccountExecutiveEmail__c);
                accountsToUpdate.add(acc);
            }
        }

        if (!accountsToUpdate.isEmpty()) {
            List<Database.SaveResult> results = Database.update(accountsToUpdate, false);
            
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    for (Database.Error err : results[i].getErrors()) {
                        System.debug('Error actualizando Account Id: ' + accountsToUpdate[i].Id + ' - ' + err.getMessage());
                    }
                }
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Proceso batch completado.');
    }
}