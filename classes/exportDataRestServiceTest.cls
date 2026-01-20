@isTest
public class exportDataRestServiceTest {

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
    public static void testGetDataRecord() {
        SingleRequestMock fakeResponse = new SingleRequestMock(200,'Complete', ' ', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Test.startTest();
            String result = exportDataRestService.getDataRecord('Case');
        Test.stopTest();
        Assert.areNotEqual(null,result, 'Result should not be null');
    }

    @isTest
    public static void testExportData() {
        Test.startTest();
            String result = exportDataRestService.exportData('Case');
        Test.stopTest();
        Assert.areNotEqual(null,result, 'Result should not be null');
    }

    @isTest
    public static void testProcessRecords() {
        SingleRequestMock fakeResponse = new SingleRequestMock(200,'Complete', ' ', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        List<Case> cases = [SELECT Id, CaseNumber, OwnerId, Owner.Profile.Name, CreatedDate, LastModifiedDate FROM Case LIMIT 1];
        Test.startTest();
            Boolean result = exportDataRestService.processRecords(cases, 1, 'Case');
        Test.stopTest();
        Assert.areEqual(true,result, 'Result should be true');
    }

    @isTest
    public static void testProcessRecordsErrorApi() {
        SingleRequestMock fakeResponse = new SingleRequestMock(401,'Complete', ' ', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        List<Case> cases = [SELECT Id, CaseNumber, OwnerId, Owner.Profile.Name, CreatedDate, LastModifiedDate FROM Case LIMIT 1];
        Test.startTest();
            Boolean result = exportDataRestService.processRecords(cases, 1, 'Case');
        Test.stopTest();
        Assert.areEqual(false,result, 'Result should be false');
    }

    @isTest
    public static void testGetDataRecordError() {
        Test.startTest();
            String result = exportDataRestService.getDataRecord('CaseFakeTest');
        Test.stopTest();
        Assert.areEqual('Recurso llamado CaseFakeTest no encontrado.',result, 'Result should be Recurso llamado CaseFakeTest no encontrado.');
    }
}