public class ActionPlanTriggerHandler {
    private static Set<Id> processedTasks = new Set<Id>();
    public static void setStartDate(List<ActionPlan> taskList){
        
        List<ActionPlan> tasksToUpdate = new List<ActionPlan>();
        Datetime now = Datetime.now();

        Set<Id> whatIds = new Set<Id>();
        for (ActionPlan t : taskList) {
            
            if (t.TargetId != null && !processedTasks.contains(t.Id)) {
                whatIds.add(t.TargetId);
            }
        }

        // Si no hay WhatId, no hacemos nada
        if (whatIds.isEmpty()) {
            return;
        }

        // Consultar oportunidades asociadas a las tareas
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([
            SELECT Id, RecordType.Name, CompanyType__c 
            FROM Opportunity  
            WHERE Id IN :whatIds  
            AND RecordType.Name = 'Onboarding'  
            AND CompanyType__c IN ('EAS', 'SRL', 'SA', 'otros', 'Unipersonal')
        ]);

        for (ActionPlan t : taskList) {
            // Verificamos si la tarea está asociada a una oportunidad válida y no ha sido procesada
            if (oppMap.containsKey(t.TargetId) &&  (t.StartDateTime__c == null) &&  !processedTasks.contains(t.Id)) {
                ActionPlan taskToUpd = new ActionPlan(Id = t.Id);
                taskToUpd.StartDateTime__c = now;
                taskToUpd.Time_in_Hours__c = 0;
                taskToUpd.Time_in_Days__c = 0;
                tasksToUpdate.add(taskToUpd);
                processedTasks.add(t.Id);
            }
        }
            
        if (!tasksToUpdate.isEmpty()) {
            update tasksToUpdate;
        }
        
    }

    public static void calculateTaskTime(List<ActionPlan> taskList) {
        List<ActionPlan> tasksToUpdate = new List<ActionPlan>();
        Datetime now = Datetime.now();

        // Obtener los WhatId de las tareas
        Set<Id> whatIds = new Set<Id>();
        for (ActionPlan t : taskList) {
            // Solo procesar tareas que no se han actualizado en esta ejecución
            if (t.TargetId != null && !processedTasks.contains(t.Id)) {
                whatIds.add(t.TargetId);
            }
        }

        // Si no hay WhatId, no hacemos nada
        if (whatIds.isEmpty()) {
            return;
        }

        // Consultar oportunidades asociadas a las tareas
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([
            SELECT Id, RecordType.Name, CompanyType__c 
            FROM Opportunity  
            WHERE Id IN :whatIds  
            AND RecordType.Name = 'Onboarding'  
            AND CompanyType__c IN ('EAS', 'SRL', 'SA', 'otros', 'Unipersonal')
        ]);

        for (ActionPlan t : taskList) {
            // Verificamos si la tarea está asociada a una oportunidad válida y no ha sido procesada
            if (oppMap.containsKey(t.TargetId) && t.ActionPlanState == 'En progreso' && t.StartDateTime__c != null &&  !processedTasks.contains(t.Id)) {
                    
                ActionPlan taskToUpdate = new ActionPlan(Id = t.Id);
                
                Datetime startDateTime = t.StartDateTime__c;

                // Cálculo de tiempo en horas y días
                Decimal hoursElapsed = (now.getTime() - startDateTime.getTime()) / (1000 * 60 * 60);
                Decimal daysElapsed = hoursElapsed / 24;
                    
                taskToUpdate.Time_in_Hours__c = hoursElapsed;
                taskToUpdate.Time_in_Days__c = daysElapsed;
                
                tasksToUpdate.add(taskToUpdate);
                
                // Agregar al set de tareas procesadas para evitar recursión
                processedTasks.add(t.Id);
            }
        }

        if (!tasksToUpdate.isEmpty()) {
            update tasksToUpdate;
        }
        
    }
}