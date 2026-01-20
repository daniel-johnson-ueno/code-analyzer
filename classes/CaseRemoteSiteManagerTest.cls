@isTest
public class CaseRemoteSiteManagerTest {
    @testSetup
    static void testSetup(){
        Ueno_Service_Domain__c testUrl= new Ueno_Service_Domain__c(ApiKey__c = '555-555-555',DomainName__c='https://kongcloud.ind-dev-sae1.ueno.com.py');
        insert testUrl;
    }
    @isTest
    static void testGetAccountWithValidParameters() {
        String PaymentMethod = 'TD';
        String OperationNumber = '111111';
        Account account = TestFactory.createPersonAccount();
        Case caseObject = TestFactory.createCase('Escalado', 'Reclamo', account.Id);
        CaseRemoteSiteConnectionMock fakeResponse = new CaseRemoteSiteConnectionMock(200, '', '', CaseRemoteSiteConnectionMock.getVoucher_Founded());
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Test.startTest();
        CaseRemoteSiteManager.getVoucherFromExternalService(PaymentMethod, OperationNumber, caseObject.Id);
        Test.stopTest();
    }
    @isTest
    static void testGetAccountWithInvalidParameters() {
        String PaymentMethod = '';
        String OperationNumber = '';
        Account account = TestFactory.createPersonAccount();
        Case caseObject = TestFactory.createCase('Escalado', 'Reclamo', account.Id);
        CaseRemoteSiteConnectionMock fakeResponse = new CaseRemoteSiteConnectionMock(500, 'Bad Request', '', CaseRemoteSiteConnectionMock.getVoucher_Bad());
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Test.startTest();
        CaseRemoteSiteManager.getVoucherFromExternalService(PaymentMethod, OperationNumber, caseObject.Id);
        Test.stopTest();
    }
    @isTest
    static void testGetAccountWithParameters() {
        String PaymentMethod = 'QR';
        String OperationNumber = '99999999';
        Account account = TestFactory.createPersonAccount();
        Case caseObject = TestFactory.createCase('Escalado', 'Reclamo', account.Id);
        CaseRemoteSiteConnectionMock fakeResponse = new CaseRemoteSiteConnectionMock(404, 'Not Found', 'Customer not found.', CaseRemoteSiteConnectionMock.getVoucher_NotFound());
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Test.startTest();
        CaseRemoteSiteManager.getVoucherFromExternalService(PaymentMethod, OperationNumber, caseObject.Id);
        Test.stopTest();
    }
}