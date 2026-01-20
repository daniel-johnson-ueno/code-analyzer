@isTest
public class ContactsHandleAsyncDMLTest {
    @TestSetup
    private static void setupTest() {
        RecordType rtAccount = [SELECT Id FROM RecordType WHERE DeveloperName='Internal_Company'];
        RecordType rtContact = [SELECT Id FROM RecordType WHERE DeveloperName='Internal_Contact'];
        Account testAccount = new Account(
            Name = 'CDE I',
            RecordTypeId = rtAccount.Id
        );
        insert testAccount;
        Contact con = new Contact(
            FirstName = 'FirstNameTest',
            LastName = 'LastNameTest',
            Email = 'tester.man@test.com',
            Title = 'test',
            RecordTypeId = rtContact.Id,
            AccountId = testAccount.Id
        );
        insert con;
    }
    @isTest
    private static void executeInsertTest() {
        RecordType rtAccount = [SELECT Id FROM RecordType WHERE DeveloperName='Internal_Company'];
        RecordType rtContact = [SELECT Id FROM RecordType WHERE DeveloperName='Internal_Contact'];
        Account testAccount = new Account(
            Name = 'CDE I',
            RecordTypeId = rtAccount.Id
        );
        insert testAccount;
        Contact objContact1 = new Contact(
            FirstName = 'FirstNameTest1',
            LastName = 'LastNameTest1',
            Email = 'tester.man1@test.com',
            Title = 'test1',
            RecordTypeId = rtContact.Id,
            AccountId = testAccount.Id
        );
        ContactsHandleAsyncDML.Requests request1 = new ContactsHandleAsyncDML.Requests();
        request1.objContact = objContact1;
        request1.strDMLOpperation = 'insert';
        Contact objContact2 = new Contact(
            FirstName = 'FirstNameTest2',
            LastName = 'LastNameTest2',
            Email = 'tester.man2@test.com',
            Title = 'test2',
            RecordTypeId = rtContact.Id,
            AccountId = testAccount.Id
        );        
        ContactsHandleAsyncDML.Requests request2 = new ContactsHandleAsyncDML.Requests();
        request2.objContact = objContact2;
        request2.strDMLOpperation = 'insert';
        List<ContactsHandleAsyncDML.Requests> lstRequest = new List<ContactsHandleAsyncDML.Requests>{ request1, request2 };
        Test.startTest();
        List<ContactsHandleAsyncDML.Results> lstResults = ContactsHandleAsyncDML.execute(lstRequest);
        Test.stopTest();
    }
    @isTest
    private static void executeUpdateTest() {
        Contact objContactToUpdate = [SELECT Id, Title FROM Contact WHERE Email = 'tester.man@test.com'];
        objContactToUpdate.Title = 'Title test update';
        ContactsHandleAsyncDML.Requests request = new ContactsHandleAsyncDML.Requests();
        request.objContact = objContactToUpdate;
        request.strDMLOpperation = 'update';
        List<ContactsHandleAsyncDML.Requests> lstRequest = new List<ContactsHandleAsyncDML.Requests>{ request };
        Test.startTest();
        List<ContactsHandleAsyncDML.Results> lstResults = ContactsHandleAsyncDML.execute(lstRequest);
        Test.stopTest();
    }
    @isTest
    private static void executeDeleteTest() {
        Contact objContactToDelete = [SELECT Id, Title FROM Contact WHERE Email = 'tester.man@test.com'];
        ContactsHandleAsyncDML.Requests request = new ContactsHandleAsyncDML.Requests();
        request.objContact = objContactToDelete;
        request.strDMLOpperation = 'delete';
        List<ContactsHandleAsyncDML.Requests> lstRequest = new List<ContactsHandleAsyncDML.Requests>{ request };
        Test.startTest();
        List<ContactsHandleAsyncDML.Results> lstResults = ContactsHandleAsyncDML.execute(lstRequest);
        Test.stopTest();
    }
}