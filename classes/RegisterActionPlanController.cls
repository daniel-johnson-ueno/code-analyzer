public with sharing class RegisterActionPlanController {
    @AuraEnabled(cacheable=true)
    public static Task getTaskById(Id taskId) {
        try {
            return [SELECT Id, Subject, WhatId, Status, OwnerId, Owner.Name, Owner.Type  FROM Task WHERE Id = :taskId LIMIT 1];
        } catch (Exception e) {
            throw new AuraHandledException('Error al obtener la tarea: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Id getCurrentUserId() {
        return UserInfo.getUserId();
    }

    public static String getWhatIdFromTask(Id taskId) {
        String oppId; 
        List<Task> t = [SELECT WhatId FROM Task WHERE Id = :taskId LIMIT 1];
        if(t.size() > 0){
            oppId = t[0].WhatId;
        }
         
        return oppId; 
    }

    @AuraEnabled
    public static void updateTaskStatus(String taskId, String fechaActivacion, String action) {
        try {
            String opportunityId;
            Task tarea = getTaskById(taskId); 
            system.debug('tarea '+tarea);
            String whatId = (tarea != null) ? tarea.whatId : ''; //getWhatIdFromTask(taskId);
            system.debug(' whatId '+ whatId);
            if((whatId != null) && (whatId.startsWith('006'))){
                opportunityId = whatId;
            
                Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
                system.debug(' opp '+ opp);
                Task task = [SELECT Id, Status, Subject, RecordType.Name FROM Task WHERE Id =: taskId AND WhatId = :opportunityId LIMIT 1];
                system.debug(' task '+ task);
                switch on action {
                    when 'aprobar' { 
                        task.Status = 'Aprobado';
                    }
                    when 'darAlta' {
                        Date fechaActual = Date.today();
                        String dateString = fechaActivacion;
                        Date dateValue = Date.valueOf(dateString);

                        System.debug(fechaActivacion);  
                        task.Status = 'Aprobado';
                        opp.CloseDate = fechaActual; 
                        opp.Product_Activation_Date__c = dateValue; 
                    }
                    when 'rechazar' {
                        task.Status = 'Rechazado';
                    }
                    when 'devolver' {
                        task.Status = 'Devuelto';
                    }
                }
                // Actualizar registros
                update task;
                update opp;
                system.debug(' opp despues de update '+ opp);
                system.debug(' task despues de update '+ task);
            } else {
                system.debug('Esta tarea no tiene relacionada una oportunidad ');
            }
            
        } catch (Exception e) {
            throw new AuraHandledException('Error al actualizar los registros: ' + e.getMessage());
        }
    }
}