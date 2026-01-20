/**
 * @description       : 
 * @group             : 
 * @last modified on  : 06-16-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/

trigger CaseTrigger on Case (before update, before insert, after update, after insert ) {

    if(Trigger.isBefore){

        if(Trigger.isUpdate){

            CaseTriggerHandler.handleCaseStatuses(Trigger.new, Trigger.oldMap);

            for(Case currentNewCase : Trigger.new){

                    Case oldCase = Trigger.oldMap.get(currentNewCase.Id);

                        //CaseStatusTriggerHandler.handleCaseStatus(currentNewCase,oldCase);

					if((oldCase.Type != currentNewCase.Type) || (currentNewCase.Client_left__c != oldCase.Client_left__c && currentNewCase.Client_left__c)){
//                      CaseStatusTriggerHandler.handleCaseTipificacion(newCase,oldCase);
                        CaseStatusTriggerHandler.handleCaseTipificacion(currentNewCase,oldCase);
                        
                    }

                    if(oldCase.Type != currentNewCase.Type){
                        if (CaseStatusTriggerHandler.isFunctionActive('ClientOfCompanyCreation')) {
                            CaseStatusTriggerHandler.handleCaseClienteDeEmpresa(currentNewCase,oldCase);
                        }
                    }


            }


            IncidentCaseTriggerHandler.handleIncidentRelated(Trigger.new,Trigger.oldMap);



//        	for(Case oldCase: Trigger.old){
//
//            	for(Case newCase: Trigger.new){
//
//                	if(oldCase.Status != newCase.Status){
//                    	CaseStatusTriggerHandler.handleCaseStatus(Trigger.new,Trigger.oldMap);
//                	}else if ((oldCase.Type != newCase.type) || (newCase.Client_left__c != oldCase.Client_left__c && newCase.Client_left__c)){
//                    	CaseStatusTriggerHandler.handleCaseTipificacion(Trigger.new,Trigger.oldMap);
//                	}
//            	}
//        	}

            if(Label.EnableCompleteAreaAndTeam == 'true'){
        		TA_ChangeCaseArea.handleChangeCaseArea(Trigger.new,Trigger.oldMap);
            }   
        }else if(Trigger.isInsert){
            if(Label.EnableCompleteAreaAndTeam == 'true'){
            	//TA_ChangeCaseArea.completeCaseArea(Trigger.new);
                TA_ChangeCaseArea.handleChangeCaseArea(Trigger.new, null);

            }
            if (CaseStatusTriggerHandler.isFunctionActive('ClientOfCompanyCreation')) {
                for(Case currentNewCase : Trigger.new){
                    if(currentNewCase.Type!=null && currentNewCase.Reason!=null){
                        CaseStatusTriggerHandler.handleCaseClienteDeEmpresa(currentNewCase, null);
                    }
                }
            }
        }    
    }
    // if (Trigger.isAfter && Trigger.isUpdate) {
    //     CaseStatusTriggerHandler.handleKonnectInsightsCases(Trigger.new,Trigger.old);
    // }
    if (Trigger.isAfter) {

        if(Trigger.isInsert){
            CaseNotificationHandler.handle(Trigger.new, Trigger.newMap, Trigger.oldMap);
        }

        if(Trigger.isUpdate){

            if(Label.EnableCreateCaseHistory == 'true'){
                TA_CreateCaseHistoryRecord.afterUpdate(Trigger.new,Trigger.oldMap);
            }

            if(CaseNotificationHandler.isFirstTime){
                CaseNotificationHandler.isFirstTime = false;
                CaseNotificationHandler.handle(Trigger.new, Trigger.newMap, Trigger.oldMap);
            }
        }

    }

}