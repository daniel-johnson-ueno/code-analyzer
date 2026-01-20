@isTest
public class CaseServiceBatchTest {

    @TestSetup static void setup() {

        List<Case> caseList = new List<Case>();
        Account acc = TestFactory.createPersonAccount();
        acc.PersonCode__c = null;
        update acc;
        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Consulta');
        String caseRecordTypeId = recordTypeInfo.getRecordTypeId();
        DateTime yesterdayDay = System.now().adddays(-1);
        Case caseTest = new Case();
        caseTest.Origin = 'Telefono';
        caseTest.Type = 'Reclamo';
        caseTest.Casuistry__c = 'No llega el OTP';
        caseTest.Status = 'Nuevo';
        caseTest.RecordTypeId = caseRecordTypeId;
        caseTest.AccountId = acc.id;
        insert caseTest;
        Test.setCreatedDate(caseTest.Id, yesterdayDay);

    }

    @isTest
    public static void testBatchProcess() {
        SingleRequestMock fakeResponse = new SingleRequestMock(200,'Complete', ' ', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Test.startTest();
        CaseServiceBatch b = new CaseServiceBatch();
        Database.executeBatch(b);
        Test.stopTest();
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob LIMIT 1];
        System.debug(a);
        System.assertEquals('Completed',  a.Status);
    }
}