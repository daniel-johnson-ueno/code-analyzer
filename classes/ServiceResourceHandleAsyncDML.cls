public with sharing class ServiceResourceHandleAsyncDML {
    @InvocableMethod
    public static List<Results> execute (List<Requests> requestList) {
        List<Results> lstResults = new List<Results>();
        if (requestList.size()>0) {
            List<ServiceResource> lstServiceResourceToInsert = new List<ServiceResource>();
            List<ServiceResource> lstServiceResourceToUpdate = new List<ServiceResource>();
            for (Requests request : requestList) {
                switch on request.strDMLOpperation {
                    when 'insert' {
                        lstServiceResourceToInsert.add(request.objServiceResources);
                    }
                    when 'update' {
                        lstServiceResourceToUpdate.add(request.objServiceResources);
                    }
                    when else {
                        System.debug('INCORRECT DML OPERATION NAME');
                    }
                }
            }
            if (lstServiceResourceToInsert.size()>0) {
                AsyncDMLOperationsUtility asyncDML = new AsyncDMLOperationsUtility(lstServiceResourceToInsert, 'insert');
                Id jobId = System.enqueueJob(asyncDML);
                for (Integer i = 0; i < lstServiceResourceToInsert.size(); i++) {
                    Results result = new Results();
                    result.idJob = jobId;
                    lstResults.add(result);
                }
            }
            if (lstServiceResourceToUpdate.size()>0) {
                AsyncDMLOperationsUtility asyncDML = new AsyncDMLOperationsUtility(lstServiceResourceToUpdate, 'update');
                Id jobId = System.enqueueJob(asyncDML);
                for (Integer i = 0; i < lstServiceResourceToUpdate.size(); i++) {
                    Results result = new Results();
                    result.idJob = jobId;
                    lstResults.add(result);
                }
            }
        }
        return lstResults;
    }
    
    public class Requests {
        @InvocableVariable(label='ServiceResource to handle' description='List of Obj ServiceResources' required=true)
        public ServiceResource objServiceResources;
        @InvocableVariable(label='DML Operation' description='Use: insert, update, upsert or delete' required=true)
        public String strDMLOpperation;
    }
    
    public class Results {
        @InvocableVariable(label='Id of Job' description='List of Ids' required=true)
        public Id idJob;
    }
}