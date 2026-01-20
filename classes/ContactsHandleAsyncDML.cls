public with sharing class ContactsHandleAsyncDML {
    @InvocableMethod
    public static List<Results> execute (List<Requests> requestList) {
        List<Results> lstResults = new List<Results>();
        if (requestList.size()>0) {
            List<Contact> lstContactsToInsert = new List<Contact>();
            List<Contact> lstContactsToUpdate = new List<Contact>();
            List<Contact> lstContactsToDelete = new List<Contact>();
            for (Requests request : requestList) {
                switch on request.strDMLOpperation {
                    when 'insert' {
                        lstContactsToInsert.add(request.objContact);
                    }
                    when 'update' {
                        lstContactsToUpdate.add(request.objContact);
                    }
                    when 'delete' {
                        lstContactsToDelete.add(request.objContact);
                    }
                    when else {
                        System.debug('INCORRECT DML OPERATION NAME');
                    }
                }
            }
            if (lstContactsToInsert.size()>0) {
                AsyncDMLOperationsUtility asyncDML = new AsyncDMLOperationsUtility(lstContactsToInsert, 'insert');
                Id jobId = System.enqueueJob(asyncDML);
                for (Integer i = 0; i < lstContactsToInsert.size(); i++) {
                    Results result = new Results();
                    result.idJob = jobId;
                    lstResults.add(result);
                }
            }
            if (lstContactsToUpdate.size()>0) {
                AsyncDMLOperationsUtility asyncDML = new AsyncDMLOperationsUtility(lstContactsToUpdate, 'update');
                Id jobId = System.enqueueJob(asyncDML);
                for (Integer i = 0; i < lstContactsToUpdate.size(); i++) {
                    Results result = new Results();
                    result.idJob = jobId;
                    lstResults.add(result);
                }
            }
            if (lstContactsToDelete.size()>0) {
                AsyncDMLOperationsUtility asyncDML = new AsyncDMLOperationsUtility(lstContactsToDelete, 'delete');
                Id jobId = System.enqueueJob(asyncDML);
                for (Integer i = 0; i < lstContactsToDelete.size(); i++) {
                    Results result = new Results();
                    result.idJob = jobId;
                    lstResults.add(result);
                }
            }
        }
        return lstResults;
    }
    public class Requests {
        @InvocableVariable(label='Contacts to Handel' description='List of Obj Contact' required=true)
        public Contact objContact;
        @InvocableVariable(label='DML Operation' description='Use: insert, update, or delete' required=true)
        public String strDMLOpperation;
    }
    public class Results {
        @InvocableVariable(label='Id of Running Job' description='Job Id' required=true)
        public Id idJob;
    }
}