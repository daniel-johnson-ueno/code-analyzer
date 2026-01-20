@isTest
public class CasesHandleAsyncDMLTest {
    @TestSetup
    private static void setupTest() {
        Account account = TestFactory.createPersonAccount();
        Case caseObject = TestFactory.createCase('Escalado', 'Reclamo', account.Id);
    }
    @isTest
    private static void executeInsertTest() {
        Account account = TestFactory.createPersonAccount();
        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Reclamo');
        String caseRecordTypeId = recordTypeInfo.getRecordTypeId();
        Case caseTest = new Case();
        caseTest.Origin = 'Telefono';
        caseTest.Type = 'Reclamo';
        caseTest.Casuistry__c = 'No llega el OTP';
        caseTest.Status = 'Escalado';
        caseTest.RecordTypeId = caseRecordTypeId;
        caseTest.AccountId = account.Id;
        
        CasesHandleAsyncDML.Requests request = new CasesHandleAsyncDML.Requests();
        request.objCase = caseTest;
        request.strDMLOpperation = 'insert';
        List<CasesHandleAsyncDML.Requests> lstRequest = new List<CasesHandleAsyncDML.Requests>{ request };
        Test.startTest();
        List<CasesHandleAsyncDML.Results> lstResults = CasesHandleAsyncDML.execute(lstRequest);
        Test.stopTest();
    }
    @isTest
    private static void executeUpdateTest() {
        Case objCaseToUpdate = [SELECT Id, Subject FROM Case LIMIT 1];
        objCaseToUpdate.Subject = 'Subject test update';
        CasesHandleAsyncDML.Requests request = new CasesHandleAsyncDML.Requests();
        request.objCase = objCaseToUpdate;
        request.strDMLOpperation = 'update';
        List<CasesHandleAsyncDML.Requests> lstRequest = new List<CasesHandleAsyncDML.Requests>{ request };
        Test.startTest();
        List<CasesHandleAsyncDML.Results> lstResults = CasesHandleAsyncDML.execute(lstRequest);
        Test.stopTest();
    }
    @isTest
    private static void executeDeleteTest() {
        Case objCaseToDelete = [SELECT Id, Subject FROM Case LIMIT 1];
        CasesHandleAsyncDML.Requests request = new CasesHandleAsyncDML.Requests();
        request.objCase = objCaseToDelete;
        request.strDMLOpperation = 'delete';
        List<CasesHandleAsyncDML.Requests> lstRequest = new List<CasesHandleAsyncDML.Requests>{ request };
        Test.startTest();
        List<CasesHandleAsyncDML.Results> lstResults = CasesHandleAsyncDML.execute(lstRequest);
        Test.stopTest();
    }
}