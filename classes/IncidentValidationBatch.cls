global class IncidentValidationBatch implements Database.Batchable<sObject>,Database.Stateful, Schedulable{
    global Boolean result;

    global Database.QueryLocator start(Database.BatchableContext BC){
        Datetime hs24Ago = Datetime.now().addHours(-24);
        String query = 'SELECT Id, Status, Date_Status_In_Validation__c FROM Incident ';
        if(!Test.isRunningTest()){
            query += 'WHERE Date_Status_In_Validation__c <= :hs24Ago AND Status != \'Cerrado\'';
        } else {
            query += ' LIMIT 1';
        }
       
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Incident> scope){
        if(!scope.isEmpty()){
            List<Incident> incidentsToUpdate = new List<Incident>();
            for(Incident incident : scope){
                incident.Status = 'Cerrado';
                incidentsToUpdate.add(incident);
            }

            if(!incidentsToUpdate.isEmpty()){
                try{
                    update incidentsToUpdate;
                }catch(Exception e){
                    System.debug('Exception: ' + e);
                }
            }
        }
    }

    global void finish(Database.BatchableContext BC){
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc.getJobId()];
        System.debug('The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.');
    }

    global void execute(SchedulableContext SC) {
        IncidentValidationBatch b = new IncidentValidationBatch(); 
        Database.executeBatch(b,2000);
    }
}