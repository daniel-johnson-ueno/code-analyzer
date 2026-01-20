public with sharing class TaskController {
    @AuraEnabled(cacheable=true)
    public static Task getTaskById(Id taskId) {
        return [SELECT  Id, Subject, Status, Priority, ActivityDate, 
                        Owner.Name, CreatedDate, CreatedBy.Name, LastModifiedDate, 
                        LastModifiedBy.Name, What.Name, Who.Name, Description, Time_in_Hours__c, Time_in_Days__c, StartDateTime__c
                FROM Task 
                WHERE Id = :taskId LIMIT 1];
    }

    @AuraEnabled
    public static Task updateTaskComments(String taskId, String newDescription) {
        // Obtener la tarea por ID
        Task taskToUpdate = [SELECT Id, Description FROM Task WHERE Id = :taskId LIMIT 1];
        
        // Actualizar el campo de comentarios
        taskToUpdate.Description = newDescription;
        
        // Actualizar la tarea
        try {
            update taskToUpdate;
            return taskToUpdate;
        } catch (DmlException e) {
            throw new AuraHandledException('Error al actualizar la tarea: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateOwner(Id taskId, Id newOwnerId) {
        Task taskToUpdate = [SELECT Id, OwnerId FROM Task WHERE Id = :taskId LIMIT 1];
        taskToUpdate.OwnerId = newOwnerId;
        update taskToUpdate;
    }


}