public class TaskTriggerHandler {
    private static Set<Id> processedTasks = new Set<Id>();
    public void handleUpdateSkillsByTraining(List<Task> newTasks){
        List<Contact> contactsToUpdate = new List<Contact> ();
        List<Contact> contacts = new List<Contact>();
        Map<Id,Id> contactByTask = new Map<Id,Id>();
        for(Task task :newTasks){
            if(task.WhoId != null && String.valueOf(task.WhoId).startsWith('003') ){
                contactByTask.put(task.id,task.WhoId);
            }
        }
        if(!contactByTask.isEmpty()){
            List<String> contactIds = new List<String>();
            contactIds.addAll(contactByTask.values());
            contacts = [SELECT Id, Skills__c FROM Contact WHERE Id IN :contactIds];
        }
        Id recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = : Label.NameRecordTypeTaskTraining LIMIT 1].Id;
        for(Task task :newTasks) {
            if(recordTypeId != null){
                Integer percentSuccessResult = Integer.valueOf(Label.SuccessfulTrainingResult);
                if(task.RecordTypeId == recordTypeId && task.PercentResults__c >= percentSuccessResult && 
                    contactByTask.get(task.Id) != null && !contacts.isEmpty()){
                    for(Contact con :contacts){
                        if(con.Id == contactByTask.get(task.Id)){
                            Set<String> skillsValuesContact = new Set<String>(con.Skills__c != null ? con.Skills__c.split(';') : new String[]{});
                            Set<String> skillsValuesTask = new Set<String>(task.Skills__c != null ? task.Skills__c.split(';') : new String[]{});
                            skillsValuesContact.addAll(skillsValuesTask);
                            List<String> sortedSkills = new List<String>(skillsValuesContact);
                            sortedSkills.sort();
                            con.Skills__c = String.join(sortedSkills, ';');
                            contactsToUpdate.add(con);
                        }
                    }
                }
            }
        }
        List<Database.SaveResult> resultsDB = new List<Database.SaveResult>();
        if(!contactsToUpdate.isEmpty()){
            resultsDB = Database.update(contactsToUpdate, false);
        }
        List<Error_Log__c> logs = new List<Error_Log__c>();
        for(Database.SaveResult sr :resultsDB){
            if(!sr.isSuccess()){
                for(Database.Error err : sr.getErrors()) {
                    Error_Log__c log = new Error_Log__c();
                    log.Class_Name__c = 'TaskTriggerHandler';
                    log.Error_Message__c = err.getStatusCode() + ': ' + err.getMessage();
                    log.Execution_Date__c = Datetime.now();
                    logs.add(log);
                }    
            }
        }
        if(!logs.isEmpty()){
            Database.insert(logs, false);
        }
    }
    
    public void setStartDate(List<Task> taskList) {
        List<Task> tasksToUpdate = new List<Task>();
        Datetime now = Datetime.now();
        Date dateNow = Date.today();
    
        // Obtener los WhatId de las tareas
        Set<Id> whatIds = new Set<Id>();
        for (Task t : taskList) {
            if (t.WhatId != null && !processedTasks.contains(t.Id)) {
                whatIds.add(t.WhatId);
            }
        }
    
        if (whatIds.isEmpty()) {
            return;
        }
        
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([
            SELECT Id, RecordType.Name, CompanyType__c 
            FROM Opportunity  
            WHERE Id IN :whatIds  
            AND RecordType.Name = 'Onboarding'  
            AND CompanyType__c IN ('EAS', 'SRL', 'SA', 'otros', 'Unipersonal')
        ]);
    
        Id businessHoursId = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE LIMIT 1].Id;
    
        for (Task t : taskList) {
            // Verificamos si la tarea está asociada a una oportunidad válida y no ha sido procesada
            if (oppMap.containsKey(t.WhatId) &&  (t.TaskReopened__c  || t.StartDateTime__c == null) &&  !processedTasks.contains(t.Id)) {
    
                Task taskToUpd = new Task(Id = t.Id);
                if (t.TaskReopened__c) {
                    DateTime currentDateTime = System.now(); 
                    Integer hoursToAdd = 20; 
                    
                    DateTime newActivityDateTime = BusinessHours.add(businessHoursId, currentDateTime, hoursToAdd * 3600000);
                    taskToUpd.ActivityDate = newActivityDateTime.date();
                }
    
                taskToUpd.StartDateTime__c = now;
                taskToUpd.Time_in_Hours__c = 0;
                taskToUpd.Time_in_Days__c = 0;
                tasksToUpdate.add(taskToUpd);
                processedTasks.add(t.Id);
            }
        }
    
        system.debug('final tasksToUpdate values ' + tasksToUpdate);
        if (!tasksToUpdate.isEmpty()) {
            update tasksToUpdate;
        }
    }
    
    
    public void calculateTaskTime(List<Task> taskList) {
        List<Task> tasksToUpdate = new List<Task>();
        Datetime now = Datetime.now();

        // Obtener los WhatId de las tareas
        Set<Id> whatIds = new Set<Id>();
        for (Task t : taskList) {
            // Solo procesar tareas que no se han actualizado en esta ejecución
            if (t.WhatId != null && !processedTasks.contains(t.Id)) {
                whatIds.add(t.WhatId);
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

        for (Task t : taskList) {
            // Verificamos si la tarea está asociada a una oportunidad válida y no ha sido procesada
            if (oppMap.containsKey(t.WhatId) &&  
                (t.Status == 'Open' || t.Status == 'Aprobado') && t.StartDateTime__c != null &&  !processedTasks.contains(t.Id)) {
                Task taskToUpdate = new Task(Id = t.Id);
                
                Datetime startDateTime = t.StartDateTime__c;
                // Cálculo de tiempo en horas y días
                Decimal nowTime = now.getTime(); 
                Decimal startTime = startDateTime.getTime();
                Decimal resultTime = nowTime - startTime;
                Decimal hoursElapsed = resultTime / (1000 * 60 * 60);
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