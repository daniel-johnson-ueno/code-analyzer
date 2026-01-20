@IsTest
private class UpdateAccountSelfieControllerTest {

    @TestSetup
    private static void setup() {
        Account testAccount = TestFactory.createPersonAccount();

        Ueno_Service_Domain__c serviceDomain = new Ueno_Service_Domain__c(
            ApiKey__c = 'test-api-key',
            DomainName__c = 'https://test.domain.com'
        );
        insert serviceDomain;

    }

    @IsTest
    private static void testUploadAccountSelfieSuccess() {
        String jsonResponse = 'TestImageBlobData';

        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'OK', jsonResponse));

        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();

        String result = UpdateAccountSelfieController.uploadAccountSelfie(testAccount.Id, 'testPersonCode', 'testSelfieId');

        Test.stopTest();

        System.assertNotEquals('', result, 'La URL de la foto de perfil no debería estar vacía');
    }

    @IsTest
    private static void testUploadAccountSelfieNoImage() {
        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(404, 'Not Found', ''));

        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();

        String result = UpdateAccountSelfieController.uploadAccountSelfie(testAccount.Id, 'testPersonCode', 'testSelfieId');

        Test.stopTest();

        System.assertEquals('', result, 'Si no se encuentra la imagen, el resultado debería ser una cadena vacía');
    }
}