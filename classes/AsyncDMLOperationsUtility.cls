public class AsyncDMLOperationsUtility implements Queueable {
    
    private List<SObject> lstObjs;
    private String strDMLOpperation;
    
    public AsyncDMLOperationsUtility(List<SObject> lstObjs, String strDMLOpperation) {
        this.lstObjs = lstObjs;
        this.strDMLOpperation = strDMLOpperation;
    }
    
    public void execute(QueueableContext context) {
        switch on strDMLOpperation {
            when 'insert' {
                executeInsert(lstObjs);
            }
            when 'update' {
                executeUpdate(lstObjs);
            }
            // when 'upsert' {
            //     executeUpsert(lstObjs);
            // }
            when 'delete' {
                executeDelete(lstObjs);
            }
            when else {
                System.debug('INCORRECT DML OPERATION NAME');
            }
        }
    }

    private void executeInsert(List<SObject> lstObjs) {
        List<Database.SaveResult> lstResults = Database.insert(lstObjs, false);
        if(lstResults.size()>0){
            for (Database.SaveResult result : lstResults) {
                if (result.isSuccess()) {
                    System.debug('INSERT Successfully. '+ result?.getId()?.getSobjectType()?.getDescribe()?.getName() + ' ID: ' + result?.getId());
                }
                else {
                    if(result.getErrors() != null && result.getErrors().size()>0){
                        for(Database.Error error : result.getErrors()) {
                            System.debug('The following error has occurred.');
                            System.debug(error?.getStatusCode() + ': ' + error?.getMessage());
                            System.debug(result?.getId()?.getSobjectType()?.getDescribe()?.getName() + ' fields that affected this error: ' + error?.getFields());
                        }
                    }

                }
            }
        }

    }
    
    private void executeUpdate(List<SObject> lstObjs) {
        List<Database.SaveResult> lstResults = Database.update(lstObjs, false);
        if(lstResults.size()>0){
            for (Database.SaveResult result : lstResults) {
                if (result.isSuccess()) {
                    System.debug('UPDATED Successfully. '+ result?.getId()?.getSobjectType()?.getDescribe()?.getName() + ' ID: ' + result?.getId());
                }
                else {
                    if(result.getErrors() != null && result.getErrors().size()>0){
                        for(Database.Error error : result.getErrors()) {
                            System.debug('The following error has occurred.');
                            System.debug(error?.getStatusCode() + ': ' + error?.getMessage());
                            System.debug(result?.getId()?.getSobjectType()?.getDescribe()?.getName() + ' fields that affected this error: ' + error?.getFields());
                        }
                    }
                }
            }
        }

    }
    // private void executeUpsert(List<SObject> lstObjs) {
    //     // to implement
    // }
    private void executeDelete(List<SObject> lstObjs) {
        List<Database.DeleteResult> lstResults = Database.delete(lstObjs, false);
        if(lstResults.size()>0){
            for (Database.DeleteResult result : lstResults) {
                if (result.isSuccess()) {
                    System.debug('DELETE Successfully. '+ result?.getId()?.getSobjectType()?.getDescribe()?.getName() + ' ID: ' + result?.getId());
                }
                else {
                    if(result.getErrors() != null && result.getErrors().size()>0){
                        for(Database.Error error : result.getErrors()) {
                            System.debug('The following error has occurred.');
                            System.debug(error?.getStatusCode() + ': ' + error?.getMessage());
                            System.debug(result?.getId()?.getSobjectType()?.getDescribe()?.getName() + ' fields that affected this error: ' + error?.getFields());
                        }
                    }
                }
            }
        }

    }
}