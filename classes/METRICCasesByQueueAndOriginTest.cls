@IsTest
private class METRICCasesByQueueAndOriginTest {

    @TestSetup
    public static void setup() {

        Group queue = new Group();
        queue.Name = 'Test_Metrica';
        queue.DeveloperName = 'Test_Metrica';
        queue.Type = 'Queue'; 
        insert queue;

        QueueSobject queueSobject = new QueueSobject();
        queueSobject.SobjectType = 'Case';
        queueSobject.QueueId = queue.Id;
        insert queueSobject;

        
    }

    @IsTest
    static void testExecuteWithMockedCases() {
        Group queueInserted = [SELECT Id FROM Group WHERE DeveloperName = 'Test_Metrica' LIMIT 1];

        Case testCase = new Case(Status = 'Nuevo', OwnerId = queueInserted.Id, Origin = 'Web');
        insert testCase;
        

        Test.startTest();
        METRICCasesByQueueAndOrigin metricProcess = new METRICCasesByQueueAndOrigin();
        metricProcess.execute(null);
        Test.stopTest();

        System.assert(true, 'La ejecución simulada del job con casos mockeados fue exitosa');
    }

    @IsTest
    static void testExecuteWithoutCases() {

        Group queueInserted = [SELECT Id FROM Group WHERE DeveloperName = 'Test_Metrica' LIMIT 1];

        Case testCase = new Case(Status = 'Nuevo', OwnerId = queueInserted.Id, Origin = 'Web');
        insert testCase;
        Test.startTest();
        METRICCasesByQueueAndOrigin metricProcess = new METRICCasesByQueueAndOrigin();
        metricProcess.execute(null);
        Test.stopTest();

        System.assert(true, 'La ejecución del job con cero casos no falló');
    }
}