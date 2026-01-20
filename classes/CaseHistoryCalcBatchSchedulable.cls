public without sharing class CaseHistoryCalcBatchSchedulable implements Schedulable{
    public static Integer sizeBatch = Integer.valueOf(Label.SizeBatchCalcsGTR);
    
    public void execute(SchedulableContext context){
        CaseHistoryCalcBatch btch = new CaseHistoryCalcBatch();
        Database.executeBatch(btch,sizeBatch);
    }

}