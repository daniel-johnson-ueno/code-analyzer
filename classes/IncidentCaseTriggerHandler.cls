public class IncidentCaseTriggerHandler {

    public static String STATUS_NUEVO = 'Nuevo';
    public static String STATUS_EN_CURSO = 'En curso';
    public static String STATUS_BLOQUEADO = 'Bloqueado';
    public static String STATUS_EN_VALIDACION = 'En validación';
    public static String STATUS_CERRADO = 'Cerrado';
    public static String UENOBANKSA = Label.UenoBankSa;
    public static String GROUPCOMPANY_ERROR = Label.msgErrorGroupCompany;
    public static Map<Id, String> caseErrors = new Map<Id, String>();
    public static List<Case> casesWithErrors = new List<Case>(); 

    public static void handleIncidentRelated(List<Case> newList, Map<Id, Case> oldMap) {
        List<Case> casesList = new List<Case>();
        for (Case cases: newList){
            Case oldCase = oldMap.get(cases.Id);
            if((oldCase.Incident__c != cases.Incident__c) && (cases.Incident__c <> null)){
                casesList.add(cases);
            }
        }

        if(!casesList.isEmpty()){
            Map<String,Incident> incidentRelated = getRelatedIncident(casesList);
            Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Reclamo');
            String reclamoRecordTypeId = recordTypeInfo.getRecordTypeId();
            String queueName = System.label.IncidentCaseOwnerStatusBloqueado;
            String IdQueueOwner = [SELECT Id FROM Group WHERE DeveloperName =:queueName and Type = 'Queue' LIMIT 1].Id;
            Map<String,Account> accGrupoVazquez = getRelatedAccount(casesList);

            for(Case c : casesList){
                Incident inc = incidentRelated.get(c.Id);

                if(inc <> null){
                    //Verfico Empresa Ueno
                    if(accGrupoVazquez.containsKey(c.id)){
                        String gvName = accGrupoVazquez.get(c.id).Name;
                        if((gvName == UENOBANKSA) && (inc.Vazquez_Group_Company__c <> 'UENO_BANK')){
                            caseErrors.put(c.Id, String.format(GROUPCOMPANY_ERROR,new List<String>()));
                            casesWithErrors.add(c);
                            continue;
                        } else if((gvName <> inc.Vazquez_Group_Company__c) && (gvName <> UENOBANKSA)){
                                caseErrors.put(c.Id, String.format(GROUPCOMPANY_ERROR,new List<String>()));
                                casesWithErrors.add(c);
                                continue;
                            }
                    }


                    //Actualizo el status del caso de acuerdo al IM.
                    if(inc.Status == STATUS_NUEVO || inc.Status == STATUS_EN_CURSO || inc.Status == STATUS_BLOQUEADO){
                        c.Status = STATUS_BLOQUEADO;
                        c.OwnerId = IdQueueOwner;
                    }
                    else if(inc.Status == STATUS_EN_VALIDACION){
                        c.Status = inc.Status;
                        c.Motivo_en_validacion__c = 'Verificación con el cliente';
                    }
                    else if(inc.Status == STATUS_CERRADO ){
                        c.Status = inc.Status;
                        c.OwnerId = IdQueueOwner;
                        c.Resolution__c = c.Resolution__c == null ? 'Resolución a favor': c.Resolution__c;
                    }

                    //Seteo de valores de Asunto y Descripcion caso relacionado.
                    if(String.isEmpty(c.Subject)){
                        c.Subject = inc.Subject;
                    }
                    if(String.isEmpty(c.Description)){
                        c.Description = inc.Description;
                    }

                    //Si es un record type distinto de reclamo, lo piso.
                    if(c.RecordTypeId != reclamoRecordTypeId){
                        c.recordtypeId = reclamoRecordTypeId;
                    }

                    //En el caso de que no tenga type y reason, le asigno el del IM.
                    if((c.type == null || c.type == '') || ((c.Reason == null || c.Reason == ''))){
                        c.Type = inc.Tipo__c;
                        c.Reason = inc.Motivo__c;
                    }
                }
            }
        }

        if(caseErrors != null || !caseErrors.isEmpty()){
            applyErrorsToCases(caseErrors, casesWithErrors);
        }


    }

    private static void applyErrorsToCases(Map<Id, String> errors, List<Case> cases) {
        for (Case c : cases) {
            if (errors.containsKey(c.Id)) {
                c.addError(errors.get(c.Id));
            }
        }
    }

    public static Map<String,Incident> getRelatedIncident(List<Case> casesList) {
        Map<String,Incident> result = new Map<String,Incident>();
        Set<Id> idRelatedIncident = new Set<Id>();
        for(Case c : casesList){
            idRelatedIncident.add(c.Incident__c);
        }

        if(!idRelatedIncident.isEmpty()){
            List<Incident> incidentRelated = [SELECT Id, Status, Tipo__c, Motivo__c, Description, Subject, Vazquez_Group_Company__c FROM Incident WHERE Id IN :idRelatedIncident];
            for(Case c : casesList){
                for(Incident i : incidentRelated){
                    if(c.Incident__c == i.Id){
                        result.put(c.Id, i);
                    }
                }
            }
        }
        return result;
    }

    public static Map<String,Account> getRelatedAccount(List<Case> casesList) {
        Map<String,Account> result = new Map<String,Account>();

        Set<Id> idRelatedAcc = new Set<Id>();
        for(Case c : casesList){
            idRelatedAcc.add(c.Vazquez_Group_Company__c);
        }

        if(!idRelatedAcc.isEmpty()){
            List<Account> accountRelated = [SELECT Id, Name FROM Account WHERE Id IN :idRelatedAcc];
            if(!accountRelated.isEmpty()){
                for(Case c : casesList){
                    for(Account acc : accountRelated){
                        if(c.Vazquez_Group_Company__c == acc.Id){
                            result.put(c.Id, acc);
                        }
                    }
                }
            }
        }

        return result;
    }

    public static Boolean isCaseWithIncidentRelated(Case currentNewCase, Case oldCase) {
        if((currentNewCase.incident__c <> null) && (oldCase.incident__c <> null)){
            return true;
        } else {
            if(currentNewCase.incident__c <> null){
                return true;
            }
        }
        return false;
    }

}