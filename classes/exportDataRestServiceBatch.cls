global class exportDataRestServiceBatch implements Database.Batchable<sObject>,Database.Stateful,Database.AllowsCallouts, Schedulable{
    global Boolean result;
    global Integer executionNumber = 0;
    global String objectName;

    global exportDataRestServiceBatch(String objectName){
        this.objectName = objectName;
    }

    global Database.QueryLocator start(Database.BatchableContext BC){

        String query = exportDataRestService.getDataRecord(this.objectName);
        if(Test.isRunningTest()){
            query += ' LIMIT 1';
        } 
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope){

        if(!scope.isEmpty()){
            String objectName = scope[0].getSObjectType().getDescribe().getName();
            result = exportDataRestService.processRecords(scope,executionNumber,objectName);
            executionNumber++;
        }
    }

    global void finish(Database.BatchableContext BC){
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc.getJobId()];
        System.debug('The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.');
    }

    global void execute(SchedulableContext SC) {
        if(!String.isBlank(this.objectName)){
            exportDataRestServiceBatch b = new exportDataRestServiceBatch(this.objectName); 
            Database.executeBatch(b,2000);
        }
    }
}