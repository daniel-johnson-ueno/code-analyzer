@isTest
private class ContactBotCustomerControllerTest {
    

    @TestSetup
    static void setupTestData() {
        Ueno_Service_Domain__c testUrl= new Ueno_Service_Domain__c(ApiKey__c = '555-555-555',DomainName__c='https://kongcloud.ind-dev-sae1.ueno.com.py');
        insert  testUrl;

        Chatbot_Service_Domain__c domain = new Chatbot_Service_Domain__c(
            DomainName__c = 'https://test.salesforce.com',
            ApiKey__c = 'test-api-key'
        );
        Database.insert(domain);

        Account acc = new Account();
        acc.FirstName = 'Test';
        acc.LastName = 'Person Account';
        acc.PersonCode__c = 123456;
        Database.insert(acc);

        Case caseTest = new Case();
        caseTest.Origin = 'BOT';
        caseTest.Type = 'Reclamo';
        caseTest.Casuistry__c = 'No llega el OTP';
        caseTest.Status = 'Nuevo';
        caseTest.AccountId = acc.id;
        Database.insert(caseTest);
    }

    @IsTest
    static void executeSuccess() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        MockHttpCallOut mock = new MockHttpCallOut(
            200,
            'OK',
            '{"status":"Success", "eventType":"agentContact", "isError":false}'
        );
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        ContactBotCustomerController.ContactResponseWrapper response = ContactBotCustomerController.execute(testCase.Id);
        Test.stopTest();

        System.assertEquals('Success', response.status);
        System.assertEquals('agentContact', response.eventType);
        System.assertEquals(false, response.isError);
    }

    @IsTest
    static void executeErrorResponse() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        MockHttpCallOut mock = new MockHttpCallOut(
            400,
            'Bad Request',
            '{"status":"Error", "eventType":"agentContact", "isError":true}'
        );
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        ContactBotCustomerController.ContactResponseWrapper response = ContactBotCustomerController.execute(testCase.Id);
        Test.stopTest();

        System.assertEquals('Error', response.status);
        System.assertEquals('No se pudo contactar al cliente. Error en el servicio', response.eventType);
        System.assertEquals(true, response.isError);
    }
}