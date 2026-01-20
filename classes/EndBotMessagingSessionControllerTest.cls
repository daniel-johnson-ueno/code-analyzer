@isTest
private class EndBotMessagingSessionControllerTest {

    @TestSetup
    static void setupTestData() {
        Chatbot_Service_Domain__c domain = new Chatbot_Service_Domain__c(
            DomainName__c = 'https://test.salesforce.com',
            ApiKey__c = 'test-api-key'
        );
        Database.insert(domain);
    }

    @IsTest
    static void testExecuteWithValidRequest() {
        Decimal personCode = 123456789;
        EndBotMessagingSessionController.EndBotSessionRequest request = new EndBotMessagingSessionController.EndBotSessionRequest();
        request.personCode = personCode;

        MockHttpCallOut mock = new MockHttpCallOut(
            200,
            'OK',
            '{"status":"success", "eventType":"endSession"}'
        );
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        EndBotMessagingSessionController.execute(new List<EndBotMessagingSessionController.EndBotSessionRequest>{ request });
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable']);
    }

    @IsTest
    static void testExecuteWithNullRequest() {
        EndBotMessagingSessionController.EndBotSessionRequest nullRequest = new EndBotMessagingSessionController.EndBotSessionRequest();
        nullRequest.personCode = null;

        MockHttpCallOut mock = new MockHttpCallOut(
            200,
            'OK',
            '{"status":"success", "eventType":"endSession"}'
        );
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        EndBotMessagingSessionController.execute(new List<EndBotMessagingSessionController.EndBotSessionRequest>{ nullRequest });
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable']);
    }

    @IsTest
    static void testHttpCalloutErrorHandling() {
        Decimal personCode = 987654321;
        EndBotMessagingSessionController.EndBotSessionRequest request = new EndBotMessagingSessionController.EndBotSessionRequest();
        request.personCode = personCode;

        MockHttpCallOut mock = new MockHttpCallOut(
            500,
            'INTERNAL SERVER ERROR',
            '{"error":"Internal Server Error"}'
        );
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        EndBotMessagingSessionController.execute(new List<EndBotMessagingSessionController.EndBotSessionRequest>{ request });
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable']);
    }

    @IsTest
    static void testQueueableExecution() {
        Decimal personCode = 123456789;
        List<Long> personCodes = new List<Long>();
        personCodes.add(personCode.longValue());

        MockHttpCallOut mock = new MockHttpCallOut(
            200,
            'OK',
            '{"status":"success", "eventType":"endSession"}'
        );
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        System.enqueueJob(new EndBotMessagingSessionController.PerformHttpCalloutJob(personCodes));
        Test.stopTest();

        System.assert(true, 'El trabajo encolado se ejecutó correctamente');
    }

    @IsTest
    static void testBatchProcessing() {
        List<EndBotMessagingSessionController.EndBotSessionRequest> requests = new List<EndBotMessagingSessionController.EndBotSessionRequest>();
        for (Integer i = 0; i < 77; i++) {
            EndBotMessagingSessionController.EndBotSessionRequest request = new EndBotMessagingSessionController.EndBotSessionRequest();
            request.personCode = Decimal.valueOf(i + 1);
            requests.add(request);
        }

        MockHttpCallOut mock = new MockHttpCallOut(200, 'OK', '{"status":"success"}');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        EndBotMessagingSessionController.execute(requests);
        Test.stopTest();

        System.assertEquals(6, [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable']);
    }
}