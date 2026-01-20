@IsTest
private class CaseIntegrationsMetricsDispatcherTest {

    @IsTest
    static void testDispatcherExecution() {
        Test.startTest();
        CaseIntegrationsMetricsDispatcher dispatcher = new CaseIntegrationsMetricsDispatcher();
        dispatcher.execute(null); 
        Test.stopTest();
    }
}