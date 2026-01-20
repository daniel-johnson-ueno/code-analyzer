@isTest
public class exportDataRestServiceBatchTest {

    @TestSetup static void setup() {

        Account testPersonAccount = (Account)TestFactoryFramework.createSObject(new Account(), 'TestFactoryFrameworkDefaults.InternalCompanyAccountDefaults', true);
        Case caseTest = (Case)TestFactoryFramework.createSObject(new Case(), 'TestFactoryFrameworkDefaults.ConsultaCaseDefaults', false);
        caseTest.Origin = 'Web';
        caseTest.Type = 'Reclamo';
        caseTest.Status = 'Nuevo';
        caseTest.AccountId = testPersonAccount.id;
        insert caseTest;
        
    }

    @isTest
    public static void testBatchProcess() {
        SingleRequestMock fakeResponse = new SingleRequestMock(200,'Complete', ' ', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Test.startTest();
            exportDataRestServiceBatch b = new exportDataRestServiceBatch('Case');
            Database.executeBatch(b);
        Test.stopTest();
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob LIMIT 1];
        Assert.areEqual ('Completed',  a.Status, 'Job completed with no errors');
    }

    @isTest
    public static void testBatchProcessSchedule() {
        exportDataRestServiceBatch schedulable = new exportDataRestServiceBatch('Case');
        Test.startTest();        
            schedulable.execute(null);
        Test.stopTest();
        Assert.areNotEqual(null, schedulable, 'Schedulable is not null');
    }
    
}