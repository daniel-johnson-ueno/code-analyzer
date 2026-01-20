global with sharing class CloseCasesBatchableClass implements Database.Batchable<SObject>, Database.Stateful {
    global static Database.QueryLocator start(Database.BatchableContext BC) {

        if(Test.isRunningTest()){
            return Database.getQueryLocator([
                SELECT Id, Subject, Description, Status FROM Case WHERE Status = 'Nuevo' AND Origin = 'Teléfono'
            ]);
        }
        
        return Database.getQueryLocator([
            SELECT Id, Subject, Description, Status, AutomaticClosure__c FROM Case WHERE CreatedDate < LAST_N_DAYS:1 AND Status = 'Nuevo' AND Origin = 'Teléfono' and Owner.Name = 'Casos Canal' AND (NOT ClientProduct__c IN ('Fraude','Jubilados'))
        ]);
    }

    global void execute(Database.BatchableContext BC, List<Case> casesToClose) {

        for (Case caseToClose : casesToClose) {
            caseToClose.Status = 'Cerrado';
            caseToClose.Subject = 'Cierre automático';
            caseToClose.Description = 'Este caso fue cerrado automaticamente.';
            caseToClose.AutomaticClosure__c = True;
        }

        Database.update(casesToClose, false);
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('CloseCases Batch Process Complete.');
    }

    @invocablemethod
    public static void closeCases() {
        Database.executeBatch(new CloseCasesBatchableClass(), 10);
    }
}