global class CaseServiceSchedulable implements Schedulable {
    global void execute(SchedulableContext sc) {
        CaseServiceBatch b = new CaseServiceBatch(); 
        Database.executeBatch(b,1000);
    }
 }