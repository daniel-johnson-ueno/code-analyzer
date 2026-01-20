@IsTest
private class DocumentosAdjuntosHelperTest {

    @TestSetup
    private static void setupTest() {

        Account customer = new Account();
        customer.Name = 'Test Account';
        customer.PersonCode__c = 123456;
        Database.insert(customer);

        Ueno_Service_Domain__c uenoDomain = new Ueno_Service_Domain__c();
        uenoDomain.ApiKey__c = '09-746e-4e1d';
        uenoDomain.DomainName__c = 'https://platform-kong-public-d.com';
        Database.insert(uenoDomain);

    }

    @IsTest
    private static void getDocumentsByPersonCode() {

        // Set mock callout class
        String json = '[{"url":"http://192.168.60.90:84/api/Documents/cf8c0ab1-ae95-4e8c-a4fb-43d1db08c915","description":"Test"}]';
        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200,'Ok',json));

        Account customer = [SELECT Id, PersonCode__c, Documentos__c FROM Account LIMIT 1];

        Test.startTest();
            String response = DocumentosAdjuntosHelper.getDocumentsByPersonCode(customer.PersonCode__c);
            System.assertNotEquals('',response);
        Test.stopTest();
    }

}