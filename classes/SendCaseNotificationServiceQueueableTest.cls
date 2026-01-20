@isTest
public class SendCaseNotificationServiceQueueableTest {

    @TestSetup static void setup() {

        Account testPersonAccount = (Account)TestFactoryFramework.createSObject(new Account(), 'TestFactoryFrameworkDefaults.PersonAccountDefaults', true);
        Case caseTestReclamo = (Case)TestFactoryFramework.createSObject(new Case(), 'TestFactoryFrameworkDefaults.ReclamoCaseDefaults', false);
        caseTestReclamo.Origin = 'Web';
        caseTestReclamo.Type = '';
        caseTestReclamo.Reason = '';
        caseTestReclamo.Status = 'Nuevo';
        caseTestReclamo.AccountId = testPersonAccount.id;
        caseTestReclamo.Description = 'Test Reclamo IM';
        caseTestReclamo.Subject = 'Test Reclamo';
        caseTestReclamo.AutomaticClosure__c = false;
        insert caseTestReclamo;
        Ueno_Service_Domain__c uenoDomain = (Ueno_Service_Domain__c)TestFactoryFramework.createSObject(new Ueno_Service_Domain__c(), 'TestFactoryFrameworkDefaults.UenoServiceDomainDefaults', true);
        
    }

    @IsTest
    public static void testQueueable(){
        SingleRequestMock fakeResponse = new SingleRequestMock(200,'Complete', ' ', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        List<Case> cases = [SELECT Id, CaseNumber, Subject, Description, Status, Account.PersonCode__c, RecordType.Name, RecordTypeId, MilestoneStatus, Braze_Description__c, AutomaticClosure__c, Origin FROM Case];
        Map<String, Case> caseByCaseId = new Map<String, Case>();
        Map<Id, Case> oldCases = new Map<Id, Case>();
        caseByCaseId.put(cases[0].Id, cases[0]);
        oldCases.put(cases[0].Id, cases[0]);
        SendCaseNotificationServiceQueueable queueable = new SendCaseNotificationServiceQueueable(cases, caseByCaseId, oldCases);
        Test.startTest();
            System.enqueueJob(queueable);
        Test.stopTest();
        Assert.areEqual(true, queueable != null);
    }

    @IsTest
    public static void testQueueableStatusCerrado(){
        SingleRequestMock fakeResponse = new SingleRequestMock(200,'Complete', ' ', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        List<Case> cases = [SELECT Id, CaseNumber, Subject, Description, Status, Account.PersonCode__c, RecordType.Name, RecordTypeId, MilestoneStatus, Braze_Description__c FROM Case];
        Test.startTest();
            cases[0].Status = 'Cerrado';
            cases[0].Subject = 'Test Subject';
            cases[0].Description = 'Test Desc';
            cases[0].Resolution__c='Resolución a favor';
            update cases[0];
        Test.stopTest();
        List<Case> caseUpdated = [SELECT Id, Status FROM Case WHERE id = :cases[0].Id];
        Assert.areEqual('Cerrado', caseUpdated[0].Status, 'Status should be Cerrado.');
    }

}