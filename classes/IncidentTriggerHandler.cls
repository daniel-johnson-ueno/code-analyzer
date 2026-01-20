public class IncidentTriggerHandler {

    public static String STATUS_NUEVO = 'Nuevo';
    public static String STATUS_EN_CURSO = 'En curso';
    public static String STATUS_BLOQUEADO = 'Bloqueado';
    public static String STATUS_EN_VALIDACION = 'En validación';
    public static String STATUS_CERRADO = 'Cerrado';

    public static void handle(List<Incident> newList, Map<Id, Incident> oldMap) {
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                beforeInsert(newList);
            } else if (Trigger.isUpdate) {
                beforeUpdate(newList, oldMap);
            }
        } else if (Trigger.isAfter) {
            if (Trigger.isInsert) {
                afterInsert(newList);
            } else if (Trigger.isUpdate) {
                afterUpdate(newList, oldMap);
            }
        }
    }
    
    public static void beforeInsert(List<Incident> newList) {
    }
    
    public static void beforeUpdate(List<Incident> newList, Map<Id, Incident> oldMap) {
    }

    public static void afterUpdate(List<Incident> newList, Map<Id, Incident> oldMap) {
        statusVerificationCases(newList,oldMap);
    }
    
    public static void afterInsert(List<Incident> newList) {
    }

    public static void statusVerificationCases(List<Incident> newList, Map<Id, Incident> oldMap) {
        List<Incident> incidentsList = new List<Incident>();
        for (Incident incidents: newList){
            if (oldMap.get(incidents.id).Status != incidents.Status) {
                    incidentsList.add(incidents);
            }
        }
        if(!incidentsList.isEmpty()){
            Map<String,List<Case>> casesRelated = getRelatedCases(incidentsList);
            Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Reclamo');
            String reclamoRecordTypeId = recordTypeInfo.getRecordTypeId();
            String queueName = System.label.IncidentCaseOwnerStatusBloqueado;
            String IdQueueOwner = [SELECT Id FROM Group WHERE DeveloperName =:queueName and Type = 'Queue' LIMIT 1].Id;
            List<Case> casesToUpdate = new List<Case>();
            for(Incident inc : incidentsList){
                List<Case> cases = casesRelated.get(inc.Id);
                if(cases != null){
                    for(Case caso : cases){

                        //Me fijo si el caso no está cerrado
                        if(caso.Status != 'Cerrado'){

                            //Actualizo el status del caso de acuerdo al IM.
                            if(inc.Status == STATUS_NUEVO || inc.Status == STATUS_EN_CURSO || inc.Status == STATUS_BLOQUEADO){
                                caso.Status = STATUS_BLOQUEADO;
                                caso.OwnerId = IdQueueOwner;
                            }
                            else if(inc.Status == STATUS_EN_VALIDACION){
                                caso.Status = inc.Status;
                                caso.Motivo_en_validacion__c = 'Verificación con el cliente';
                            }
                            else if(inc.Status == STATUS_CERRADO){
                                caso.Status = inc.Status;
                                caso.OwnerId = IdQueueOwner;
                                caso.Resolution__c = 'Resolución a favor';
                                caso.Close_Reason_Automatic__c = 'Cerrado por incidente';
                            }

                            //Seteo de valores de Asunto y Descripcion caso relacionado.
                            if(String.isEmpty(caso.Subject)){
                                caso.Subject = inc.Subject;
                            }
                            if(String.isEmpty(caso.Description)){
                                caso.Description = inc.Description;
                            }

                            //Si es un record type distinto de reclamo, lo piso.
                            if(caso.RecordTypeId != reclamoRecordTypeId){
                                caso.recordtypeId = reclamoRecordTypeId;
                            }
                            //En el caso de que no tenga type y reason, le asigno el del IM.
                            if((caso.type == null || caso.type == '') || ((caso.Reason == null || caso.Reason == ''))){
                                caso.Type = inc.Tipo__c;
                                caso.Reason = inc.Motivo__c;
                            }

                            casesToUpdate.add(caso);
                        }
                    }
                }
            }

            try {
                if(!casesToUpdate.isEmpty()){
                    List<CasesHandleAsyncDML.Requests> requestList = new List<CasesHandleAsyncDML.Requests>();
                    for(Case caso : casesToUpdate){
                        CasesHandleAsyncDML.Requests request = new CasesHandleAsyncDML.Requests();
                        request.objCase = caso;
                        request.strDMLOpperation = 'update';
                        requestList.add(request);
                    }
                    List<CasesHandleAsyncDML.Results> lstResults = CasesHandleAsyncDML.execute(requestList);
                }
            } catch (Exception e) {
                System.debug('The following exception has occurred: ' + e.getMessage());
            }
        }
    }

    public static Map<String,List<Case>> getRelatedCases(List<Incident> incidentsList) {
        Map<String,List<Case>> result = new Map<String,List<Case>>();
        List<Case> casesRelated = [SELECT Id, Status, Motivo_en_validacion__c, Resolution__c, Incident__c, Type, Reason, Subject, Description, recordTypeId, OwnerId, Close_Reason_Automatic__c FROM Case WHERE Incident__c IN :incidentsList AND Status <> :STATUS_CERRADO];
        for(Case c : casesRelated){
            if(result.containsKey(c.Incident__c)){
                result.get(c.Incident__c).add(c);
            } else {
                List<Case> casesList = new List<Case>();
                casesList.add(c);
                result.put(c.Incident__c, casesList);
            }
        }
        return result;
    }
}