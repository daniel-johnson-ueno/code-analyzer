@isTest
public class AsyncDMLOperationsUtilityTest {
    
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
        Account testAccount = new Account(
            Name = 'CDE I',
            RecordTypeId = rtAccount.Id
        );
        List<SObject> lstAccounts = new List<SObject>();
        lstAccounts.add(testAccount);
        AsyncDMLOperationsUtility asyncDML = new AsyncDMLOperationsUtility(lstAccounts, 'insert');
        Id idJob = System.enqueueJob(asyncDML);
        Assert.isNotNull(idJob);
    }
    @isTest
    private static void executeUpdateTest() {
        Contact objContactToUpdate = [SELECT Id, Title FROM Contact WHERE Email = 'tester.man@test.com'];
        objContactToUpdate.Title = 'Title test update';
        List<SObject> lstContacts = new List<SObject>();
        lstContacts.add(objContactToUpdate);
        AsyncDMLOperationsUtility asyncDML = new AsyncDMLOperationsUtility(lstContacts, 'update');
        Id idJob = System.enqueueJob(asyncDML);
        Assert.isNotNull(idJob);
    }
    @isTest
    private static void executeDeleteTest() {
        Contact objContactToDelete = [SELECT Id, Title FROM Contact WHERE Email = 'tester.man@test.com'];
        List<SObject> lstContacts = new List<SObject>();
        lstContacts.add(objContactToDelete);
        AsyncDMLOperationsUtility asyncDML = new AsyncDMLOperationsUtility(lstContacts, 'delete');
        Id idJob = System.enqueueJob(asyncDML);
        Assert.isNotNull(idJob);
    }
    
}