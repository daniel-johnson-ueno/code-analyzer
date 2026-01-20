@isTest
private class TaskControllerTest {

    @testSetup
    static void setupTestData() {
        Task testTask = (Task) TestFactoryFramework.createSObject(new Task());
        testTask.Subject = 'Test Task';
        testTask.Status = 'Open';
        testTask.Priority = 'Normal';
        testTask.ActivityDate = Date.today();
        testTask.Description = 'Initial Description';
        insert testTask;

    }

    @isTest
    static void testGetTaskById() {
        // Obtener el task creado en @testSetup
        Task task = [SELECT Id FROM Task LIMIT 1];
        User usuario = [SELECT Id FROM User WHERE isActive = true LIMIT 1];

        Test.startTest();
        Task result = TaskController.getTaskById(task.Id);
        TaskController.updateOwner(task.Id, usuario.Id );
        Test.stopTest();

        System.assertNotEquals(null, result, 'La tarea no debe ser null');
        System.assertEquals(task.Id, result.Id, 'El Id de la tarea no coincide');
    }

    @isTest
    static void testUpdateTaskComments() {
        // Obtener el task creado en @testSetup
        Task task = [SELECT Id FROM Task LIMIT 1];
        String updatedDescription = 'Updated Description';

        Test.startTest();
        Task updatedTask = TaskController.updateTaskComments(task.Id, updatedDescription);
        Test.stopTest();

        System.assertEquals(updatedDescription, updatedTask.Description, 'La descripción no se actualizó correctamente');
    }
}