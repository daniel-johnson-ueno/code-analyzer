/**
 * Created by alexis on 21/02/2025.
 */
@isTest
private class CaseNotificationHandlerTest {
    @TestSetup
    private static void setup(){
        Ueno_Service_Domain__c testUrl= new Ueno_Service_Domain__c(ApiKey__c = '555-555-555',DomainName__c='https://kongcloud.ind-dev-sae1.ueno.com.py');
        insert  testUrl;
    }

    @isTest
    static void testNewCaseSendNotification() {
        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok'));

        Account account = TestFactory.createPersonAccount();

        RecordType consultaRecordType = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Consulta' LIMIT 1].get(0);

        Case newCase = TestCaseFactory.createNewCase('Turnero', consultaRecordType , account);

        Map<Id, Case> oldCases = new Map<Id, Case>{
                newCase.Id => newCase.clone(false, true, false, false)
        };

        RecordType reclamoRecordType = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Reclamo' LIMIT 1].get(0);

        newCase.RecordType = reclamoRecordType;
        newCase.RecordTypeId = reclamoRecordType.Id;
        newCase.Type = 'Loyalty - Reintegro';
        newCase.Reason = 'Reintegro no procesado';
        newCase.Status = 'Asignado';
        update newCase;

        Test.startTest();

        CaseNotificationHandler.handle(new List<Case>{newCase}, new Map<Id,Case>(new List<Case>{newCase}), oldCases);

        Test.stopTest();

        System.assertEquals('Asignado', newCase.Status, 'El caso debería estar Asignado');
    }

    @isTest
    static void testEscalatedCaseSendNotification() {
        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok'));

        Account account = TestFactory.createPersonAccount();

        RecordType consultaRecordType = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Consulta' LIMIT 1].get(0);

        Case newCase = TestCaseFactory.createNewCase('Turnero', consultaRecordType , account);

        Map<Id, Case> oldCases = new Map<Id, Case>{
                newCase.Id => newCase.clone(false, true, false, false)
        };

        RecordType reclamoRecordType = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Reclamo' LIMIT 1].get(0);

        newCase.RecordType = reclamoRecordType;
        newCase.RecordTypeId = reclamoRecordType.Id;
        newCase.Type = 'Loyalty - Reintegro';
        newCase.Reason = 'Reintegro no procesado';
        newCase.Status = 'Escalado';
        update newCase;

        Test.startTest();

        CaseNotificationHandler.handle(new List<Case>{newCase}, new Map<Id,Case>(new List<Case>{newCase}), oldCases);

        Test.stopTest();

        System.assertEquals('Escalado', newCase.Status, 'El caso debería estar Escalado');
    }

    @isTest
    static void testCloseCaseSendNotification() {
        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok'));

        Account account = TestFactory.createPersonAccount();

        RecordType consultaRecordType = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Consulta' LIMIT 1].get(0);

        Case newCase = TestCaseFactory.createNewCase('Turnero', consultaRecordType , account);

        Map<Id, Case> oldCases = new Map<Id, Case>{
                newCase.Id => newCase.clone(false, true, false, false)
        };

        RecordType reclamoRecordType = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Reclamo' LIMIT 1].get(0);

        newCase.RecordType = reclamoRecordType;
        newCase.RecordTypeId = reclamoRecordType.Id;
        newCase.Type = 'Loyalty - Reintegro';
        newCase.Reason = 'Reintegro no procesado';
        newCase.Status = 'Cerrado';
        newCase.Subject = 'Falta de reintegro';
        newCase.Description = 'El cliente dice que no se le realizo el reintegro';
        newCase.Resolution__c = 'Resolución no favorable';
        newCase.Refund_inquiry_made__c = true;
        update newCase;

        Test.startTest();

        CaseNotificationHandler.handle(new List<Case>{newCase}, new Map<Id,Case>(new List<Case>{newCase}), oldCases);

        Test.stopTest();

        System.assertEquals('Cerrado', newCase.Status, 'El caso debería estar Cerrado');
    }

    @isTest
    static void testNoSendNotificationWithoutAccount() {
        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok'));

        RecordType consultaRecordType = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Consulta' LIMIT 1].get(0);

        Case newCase = TestCaseFactory.createNewCase('Turnero', consultaRecordType);

        Map<Id, Case> oldCases = new Map<Id, Case>{
                newCase.Id => newCase.clone(false, true, false, false)
        };

        RecordType reclamoRecordType = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Reclamo' LIMIT 1].get(0);

        newCase.RecordType = reclamoRecordType;
        newCase.RecordTypeId = reclamoRecordType.Id;
        newCase.Type = 'Loyalty - Reintegro';
        newCase.Reason = 'Reintegro no procesado';
        newCase.Status = 'Asignado';
        update newCase;

        Test.startTest();

        CaseNotificationHandler.handle(new List<Case>{newCase}, new Map<Id,Case>(new List<Case>{newCase}), oldCases);

        Test.stopTest();

        System.assertEquals('Asignado', newCase.Status, 'El caso debería estar Asignado');
    }

    @isTest
    static void testNoSendNotificationWithoutAccountPersonCode() {
        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok'));

        Account account = TestFactory.createPersonAccount();
        account.PersonCode__c = null;

        RecordType consultaRecordType = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Consulta' LIMIT 1].get(0);

        Case newCase = TestCaseFactory.createNewCase('Turnero', consultaRecordType , account);

        Map<Id, Case> oldCases = new Map<Id, Case>{
                newCase.Id => newCase.clone(false, true, false, false)
        };

        RecordType reclamoRecordType = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Reclamo' LIMIT 1].get(0);

        newCase.RecordType = reclamoRecordType;
        newCase.RecordTypeId = reclamoRecordType.Id;
        newCase.Type = 'Loyalty - Reintegro';
        newCase.Reason = 'Reintegro no procesado';
        newCase.Status = 'Asignado';
        update newCase;

        Test.startTest();

        CaseNotificationHandler.handle(new List<Case>{newCase}, new Map<Id,Case>(new List<Case>{newCase}), oldCases);

        Test.stopTest();

        System.assertEquals('Asignado', newCase.Status, 'El caso debería estar Asignado');
    }

    @isTest
    static void testNoSendNotificationBecauseRecordTypeWrong() {
        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok'));

        Account account = TestFactory.createPersonAccount();

        RecordType consultaRecordType = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Consulta' LIMIT 1].get(0);

        Case newCase = TestCaseFactory.createNewCase('Turnero', consultaRecordType , account);

        Map<Id, Case> oldCases = new Map<Id, Case>{
                newCase.Id => newCase.clone(false, true, false, false)
        };

        newCase.Status = 'Asignado';
        update newCase;

        Test.startTest();

        CaseNotificationHandler.handle(new List<Case>{newCase}, new Map<Id,Case>(new List<Case>{newCase}), oldCases);

        Test.stopTest();

        System.assertEquals('Asignado', newCase.Status, 'El caso debería estar Asignado');
    }
}