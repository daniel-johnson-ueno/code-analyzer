@isTest
private class GenerateLogEventTest {

    @TestSetup
    private static void setup(){
        Account company = TestFactory.createCompanyAccount();
    }

    @isTest
    static void generateErrorLogEventTest() {

        String testUserId = UserInfo.getUserId();

        Exception testException;

        try {
            Account account = AccountDAO.getAccountById('Simulate Exception');
        } catch (Exception e) {
            testException = e;
        }

        Test.startTest();

        GenerateLogEvent.generateErrorLogEvent(testException, testUserId, 'AccountDAO', 'getAccountById');

        Test.stopTest();

        List<Error_Log__c> errorLog = [SELECT Id FROM Error_Log__c WHERE Class_Name__c = 'AccountDAO'];

        System.assertEquals(1, errorLog.size());
    }



    @IsTest
    static void generateIntegrationLogEventTest() {

        HttpRequest mockRequest = new HttpRequest();
        mockRequest.setEndpoint('https://api.example.com/resource');
        mockRequest.setMethod('POST');

        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody('{"traceId": "12345", "message": "success"}');
        mockResponse.setStatusCode(200);

        Test.startTest();
        GenerateLogEvent.generateIntegrationLogEvent(mockRequest, mockResponse);
        Test.stopTest();

        List<Integration_Log__c> logEvents = [SELECT EndPoint__c, Request_Type__c, Response__c, Trace_Id__c, Response_Status_Code__c FROM Integration_Log__c];//

        System.assertEquals(1, logEvents.size());
        Integration_Log__c logEvent = logEvents[0];

        System.assertEquals('https://api.example.com/resource', logEvent.EndPoint__c);
        System.assertEquals('{"traceId": "12345", "message": "success"}', logEvent.Response__c);
        System.assertEquals(200, logEvent.Response_Status_Code__c);
    }

}