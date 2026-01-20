public class CasesHandleAsyncDML {
    @InvocableMethod
    public static List<Results> execute (List<Requests> requestList) {
        List<Results> lstResults = new List<Results>();
        if (requestList.size()>0) {
            List<Case> lstCasesToInsert = new List<Case>();
            List<Case> lstCasesToUpdate = new List<Case>();
            List<Case> lstCasesToDelete = new List<Case>();
            for (Requests request : requestList) {
                switch on request.strDMLOpperation {
                    when 'insert' {
                        lstCasesToInsert.add(request.objCase);
                    }
                    when 'update' {
                        lstCasesToUpdate.add(request.objCase);
                    }
                    when 'delete' {
                        lstCasesToDelete.add(request.objCase);
                    }
                    when else {
                        System.debug('INCORRECT DML OPERATION NAME');
                    }
                }
            }
            if (lstCasesToInsert.size()>0) {
                AsyncDMLOperationsUtility asyncDML = new AsyncDMLOperationsUtility(lstCasesToInsert, 'insert');
                Id jobId = System.enqueueJob(asyncDML);
                for (Integer i = 0; i < lstCasesToInsert.size(); i++) {
                    Results result = new Results();
                    result.idJob = jobId;
                    lstResults.add(result);
                }
            }
            if (lstCasesToUpdate.size()>0) {
                AsyncDMLOperationsUtility asyncDML = new AsyncDMLOperationsUtility(lstCasesToUpdate, 'update');
                Id jobId = System.enqueueJob(asyncDML);
                for (Integer i = 0; i < lstCasesToUpdate.size(); i++) {
                    Results result = new Results();
                    result.idJob = jobId;
                    lstResults.add(result);
                }
            }
            if (lstCasesToDelete.size()>0) {
                AsyncDMLOperationsUtility asyncDML = new AsyncDMLOperationsUtility(lstCasesToDelete, 'delete');
                Id jobId = System.enqueueJob(asyncDML);
                for (Integer i = 0; i < lstCasesToDelete.size(); i++) {
                    Results result = new Results();
                    result.idJob = jobId;
                    lstResults.add(result);
                }
            }
        }
        return lstResults;
    }
    public class Requests {
        @InvocableVariable(label='Cases to create' description='List of Obj Case' required=true)
        public Case objCase;
        @InvocableVariable(label='DML Operation' description='Use Insert, Update, Upsert or Delete' required=true)
        public String strDMLOpperation;
    }
    public class Results {
        @InvocableVariable(label='Id of Cases created' description='List of Ids' required=true)
        public Id idJob;
    }
}