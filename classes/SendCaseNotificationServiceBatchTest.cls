@isTest
public class SendCaseNotificationServiceBatchTest {

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
    public static void testBatch(){
        SingleRequestMock fakeResponse = new SingleRequestMock(200,'Complete', ' ', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        List<Case> cases = [SELECT Id, CaseNumber, Subject, Description, Status, Account.PersonCode__c, RecordType.Name, RecordTypeId, Braze_Description__c, Origin FROM Case];
        List<CaseNotificationRequestDto> dataInput = new List<CaseNotificationRequestDto>();
        for(Case c : cases){
            //CaseNotificationRequestDto data = new CaseNotificationRequestDto('12345', c.Origin, c.CaseNumber, c.RecordType.Name, c.Braze_Description__c, 'SF_CASE_EVENT_CASE_CLOSED');
            CaseNotificationRequestDto request = new CaseNotificationRequestDto();
            request.personCode = '12345';
            request.origin = c.Origin;
            request.event = 'SF_CASE_EVENT_CASE_CLOSED';
            request.caseId = c.Id;
            request.caseNumber = c.CaseNumber;

            CaseNotificationRequestDto.Typology typo = new CaseNotificationRequestDto.Typology();
            typo.type = c.RecordType.Name;
            typo.reason = c.Braze_Description__c;
            request.typology = typo;

            dataInput.add(request);
        }
        Test.startTest();
            SendCaseNotificationServiceBatch b = new SendCaseNotificationServiceBatch(dataInput);
            Database.executeBatch(b);
        Test.stopTest();
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob LIMIT 1];
        Assert.areEqual('Completed', a.Status);
    }

}