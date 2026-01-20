public without sharing class TA_CreateCaseHistoryRecord /*implements  TriggerAction.AfterUpdate*/ {

    public static void afterUpdate(List<Case> newList, Map<Id, Case> oldCaseMap) {
        Boolean isUser = false;
        Case_History_Enhanced__c caseHistory;
        List<User> usersToSearch = new List<User>();
        List<Case_History_Enhanced__c> caseHistories = new List<Case_History_Enhanced__c>();
        Map<Id, String> queuesDeveloperNameById = getQueues();
        List<Error_Log__c> logs = new List<Error_Log__c>();
        Long operatingTime;
        Boolean createChe = false;
        Case newCase;
        Case oldCase;
        for (Case c : newList) {
            oldCase = oldCaseMap.get(c.Id);
            newCase = c;
            if((newCase.Status == 'Cerrado' && oldCase.Status != newCase.Status) || oldCase.OwnerId != newCase.OwnerId && oldCase.Status != 'Cerrado' ){
                createChe = true; 
            }
        }
        if(createChe == true && oldCase != null && newCase != null){
            caseHistory = new Case_History_Enhanced__c();
            caseHistory.Case__c = newCase.Id;
            caseHistory.Stage__c = oldCase.Status;
            if(oldCase.Area_actual__c != null){
                caseHistory.CaseArea__c = oldCase.Area_actual__c;
            }
            if(String.valueOf(oldCase.OwnerId).startsWith('005')){
                caseHistory.User__c = oldCase.OwnerId;
                isUser = true;
            }else if(String.valueOf(oldCase.OwnerId).startsWith('00G')){
                if(queuesDeveloperNameById.get(oldCase.OwnerId) != null){
                    caseHistory.QueueName__c = queuesDeveloperNameById.get(oldCase.OwnerId);
                }
            }
            caseHistory.Name = 'Cambio de propietario case: '+newCase.CaseNumber;
        }
        if(caseHistory != null){
        	if(isUser == true){
            	usersToSearch = [SELECT Id, Assigned_Team__c FROM User WHERE Id =:caseHistory.User__c];
        	}
        	if(!usersToSearch.isEmpty() ){
            	caseHistory.UserTeamName__c = usersToSearch[0].Assigned_Team__c;
        	}
            List<Case_History_Enhanced__c> previousCaseHistories = [SELECT Id, CreatedDate, Case__c FROM Case_History_Enhanced__c WHERE Case__c = :caseHistory.Case__c ORDER BY CreatedDate DESC LIMIT 1];
            if(!previousCaseHistories.isEmpty()){
               operatingTime = (System.now()).getTime() - (previousCaseHistories[0].CreatedDate).getTime();
               caseHistory.Total_Operating_Time__c = (Double)(operatingTime / 1000);
            }else{
                List<Case> casesToSearch = [SELECT Id, CreatedDate FROM Case WHERE Id = :caseHistory.Case__c LIMIT 1];
                operatingTime = (System.now()).getTime() - (casesToSearch[0].CreatedDate).getTime();
               	caseHistory.Total_Operating_Time__c = (Double)(operatingTime / 1000);
            }
        System.debug('caseHistory '+caseHistory);
        caseHistories.add(caseHistory);
        }    
        List<Database.SaveResult> resultsDB = new List<Database.SaveResult>();
        if(caseHistories.size() > 0){
           resultsDB = Database.insert(caseHistories, false);
        	for(Database.SaveResult sr :resultsDB){
            	if(!sr.isSuccess()){
                	Error_Log__c log = new Error_Log__c();
                    log.Class_Name__c = 'TA_CreateCaseHistoryRecord';
                    log.Error_Message__c = 'Error al insertar case history enhanced';
                    log.Execution_Date__c = Datetime.now();
                     logs.add(log);
                	}
            	}
	     }
         if(!logs.isEmpty()){
            Database.insert(logs, false);
        }
    }
    
    private static Map<Id,String> getQueues() {
        Map<Id, String> queuesById = new Map<Id,String> ();
        for(Group g :[SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue']){
            queuesById.put(g.Id, g.DeveloperName);
        }
        return queuesById;
    }
}