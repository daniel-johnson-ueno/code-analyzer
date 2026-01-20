@isTest
private class RegisterActionPlanControllerTest {
    @testSetup
    static void setup() {
        // Crear una oportunidad de prueba
        Opportunity opp = (Opportunity)TestFactoryFramework.createSObject(new Opportunity());
        opp.Name = 'Test Opportunity';
        opp.StageName = 'Asignación';
        opp.CloseDate = Date.today();
        insert opp;
        
        // Crear una tarea de prueba relacionada con la oportunidad
        Task task = (Task)TestFactoryFramework.createSObject(new Task());
        task.Subject = 'Test Task';
        task.Status = 'Open';
        task.WhatId = opp.Id;
        insert task;
    }
    
    @isTest
    static void testGetWhatIdFromTask() {
        // Obtener la tarea de prueba
        Task t = [SELECT Id FROM Task LIMIT 1];
        
        // Llamar al método y verificar el resultado
        Test.startTest();
        Task tarea = RegisterActionPlanController.getTaskById(t.Id);
        String whatId = tarea.whatId;   
        Test.stopTest();
        
        System.assertNotEquals(null, whatId, 'El WhatId no debería ser nulo');
        System.assertEquals(whatId.startsWith('006'), true, 'El WhatId debería ser una oportunidad');
    }
    
    @isTest
    static void testUpdateTaskStatusRechazar() {
        Task t = [SELECT Id FROM Task LIMIT 1];
        
        Test.startTest();
        RegisterActionPlanController.getWhatIdFromTask(t.Id);
        RegisterActionPlanController.getCurrentUserId();
        RegisterActionPlanController.updateTaskStatus(t.Id, null, 'rechazar');
        Test.stopTest();
        
        Task updatedTask = [SELECT Status, StatusReview__c FROM Task WHERE Id = :t.Id];
        System.assertEquals('Rechazado', updatedTask.Status);
    }
    
    @isTest
    static void testUpdateTaskStatusDevolver() {
        Task t = [SELECT Id FROM Task LIMIT 1];
        
        Test.startTest();
        RegisterActionPlanController.updateTaskStatus(t.Id, null, 'devolver');
        Test.stopTest();
        
        Task updatedTask = [SELECT Status, StatusReview__c FROM Task WHERE Id = :t.Id];
        System.assertEquals('Devuelto', updatedTask.Status);
    }
     @isTest
    static void testUpdateTaskStatusAprobar() {
        Task t = [SELECT Id FROM Task LIMIT 1];
        
        Test.startTest();
        RegisterActionPlanController.updateTaskStatus(t.Id, null, 'aprobar');
        Test.stopTest();
        
        Task updatedTask = [SELECT Status, StatusReview__c FROM Task WHERE Id = :t.Id];
        System.assertEquals('Aprobado', updatedTask.Status);
    }
}