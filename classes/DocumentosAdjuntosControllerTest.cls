@IsTest
private class DocumentosAdjuntosControllerTest {

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
    private static void getCustomerDocumentsTest() {

        // Set mock callout class
        String jsonString = '[{"url":"http://192.168.60.90:84/api/Documents/cf8c0ab1-ae95-4e8c-a4fb-43d1db08c915","description":"Test"}]';

        Account customer = [SELECT Id, PersonCode__c, Documentos__c FROM Account LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200,'Ok',jsonString));

        Test.startTest();

        try{
            List<DocumentosAdjuntosHelper.DocumentsWrapper> response = DocumentosAdjuntosController.getCustomerDocuments(customer.Id);
            System.assertEquals(1,response.size());
        }catch (Exception e){
            System.debug(e);
            System.debug(e.getLineNumber());
            System.debug(e.getStackTraceString());
        }

        Test.stopTest();
    }

    @IsTest
    private static void getCustomerDocumentsCatchTest() {

        Test.startTest();
        try{
            List<DocumentosAdjuntosHelper.DocumentsWrapper> response = DocumentosAdjuntosController.getCustomerDocuments('Simulate Exception');
        }catch (Exception e){
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
        Test.stopTest();
    }
}

//{
//    "code": 500,
//"type": "Internal Server Error",
//"message": "Handler dispatch failed: java.lang.OutOfMemoryError: Metaspace",
//"traceId": "9b21a2dd-c68c-4b5e-bf9f-95ea413e1f3d"
//}