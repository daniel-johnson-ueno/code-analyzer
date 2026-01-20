@isTest
public class IncidentCaseTriggerHandlerTest {

    @TestSetup static void setup() {

        Account testPersonAccount = (Account)TestFactoryFramework.createSObject(new Account(), 'TestFactoryFrameworkDefaults.InternalCompanyAccountDefaults', false);
        testPersonAccount.Name = 'Incidencia Masiva';
        insert testPersonAccount;

        Account testUeno = (Account)TestFactoryFramework.createSObject(new Account(), 'TestFactoryFrameworkDefaults.InternalCompanyAccountDefaults', false);
        testUeno.Name = 'Ueno Bank SA';
        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Vazquez_Group_Company');
        String recordTypeId = recordTypeInfo.getRecordTypeId();
        testUeno.RecordTypeId = recordTypeId;
        insert testUeno;


        Incident inc = new Incident();
        inc.Impact = 'Parcial';
        inc.Tipo__c = 'Ahorro programado';
        inc.Motivo__c = 'Creación';
        inc.Origen__c = 'Casos';
        inc.Priority = 'Baja';
        inc.Status = 'En validación';
        inc.Subject = 'Test';
        inc.Description = 'Test';
        inc.Urgency = 'Low';
        inc.Vazquez_Group_Company__c = 'UENO_BANK';
        insert inc;

        Case caseTest = (Case)TestFactoryFramework.createSObject(new Case(), 'TestFactoryFrameworkDefaults.ConsultaCaseDefaults', false);
        caseTest.Origin = 'Web';
        caseTest.Type = 'Consulta';
        caseTest.Status = 'Nuevo';
        caseTest.AccountId = testPersonAccount.id;
        caseTest.Subject = 'Test Case IM';
        caseTest.Vazquez_Group_Company__c = testUeno.id;
        insert caseTest;

        Case caseTestReclamo = (Case)TestFactoryFramework.createSObject(new Case(), 'TestFactoryFrameworkDefaults.ReclamoCaseDefaults', false);
        caseTestReclamo.Origin = 'Web';
        caseTestReclamo.Type = '';
        caseTestReclamo.Reason = '';
        caseTestReclamo.Status = 'Nuevo';
        caseTestReclamo.AccountId = testPersonAccount.id;
        caseTestReclamo.Description = 'Test Reclamo IM';
        insert caseTestReclamo;
        
    }

    @isTest
    public static void testStatusEnValidacion() {
        Test.startTest();
            List<Case> c = [SELECT Id, Incident__c FROM Case WHERE Subject = 'Test Case IM' LIMIT 1];
            List<Incident> inc = [SELECT Id, Status FROM Incident LIMIT 1];
            c[0].Incident__c = inc[0].Id;
            update c[0];
        Test.stopTest();
        Case result = [SELECT Id, status FROM Case WHERE Id =: c[0].Id];
        Assert.areEqual('En validación',result.status, 'Status shoould be En validación');
    }

    @isTest
    public static void testStatusEnCurso() {
        Test.startTest();
            List<Incident> inc = [SELECT Id, Status FROM Incident LIMIT 1];
            inc[0].Status = 'En Curso';
            update inc[0];
            List<Case> c = [SELECT Id, Incident__c FROM Case WHERE Subject = 'Test Case IM' LIMIT 1];
            c[0].Incident__c = inc[0].Id;
            update c[0];
        Test.stopTest();
        Case result = [SELECT Id, status FROM Case WHERE Id =: c[0].Id];
        Assert.areEqual('Bloqueado',result.status, 'Status shoould be Bloqueado');
    }

    @isTest
    public static void testStatusCerrado() {
        Test.startTest();
            List<Incident> inc = [SELECT Id, Status FROM Incident LIMIT 1];
            inc[0].Status = 'Cerrado';
            update inc[0];
            List<Case> c = [SELECT Id, Incident__c FROM Case WHERE Subject = 'Test Case IM' LIMIT 1];
            c[0].Incident__c = inc[0].Id;
            update c[0];
        Test.stopTest();
        Case result = [SELECT Id, status FROM Case WHERE Id =: c[0].Id];
        Assert.areEqual('Cerrado',result.status, 'Status shoould be Cerrado');
    }

    @isTest
    public static void testGroupCompany() {
        Test.startTest();
            List<Incident> inc = [SELECT Id, Status, Vazquez_Group_Company__c FROM Incident LIMIT 1];
            List<Case> c = [SELECT Id, Incident__c FROM Case WHERE Subject = 'Test Case IM' LIMIT 1];
            c[0].Incident__c = inc[0].Id;
            update c[0];
        Test.stopTest();
        Case result = [SELECT Id, status FROM Case WHERE Id =: c[0].Id];
        Assert.areEqual('En validación',result.status, 'Status shoould be En validación');
    }

    @isTest
    public static void testFilterNotIMRecords() {
        Test.startTest();
            List<Case> c = [SELECT Id, Incident__c, Status, OwnerId FROM Case WHERE Subject = 'Test Case IM' LIMIT 1];
            c[0].Status = 'Derivado';
            system.debug(c[0].OwnerId);
            update c[0];
        Test.stopTest();
        Case result = [SELECT Id, status, OwnerId FROM Case WHERE Id =: c[0].Id];
        system.debug(result.OwnerId);
        Assert.areEqual('Derivado',result.status, 'Status shoould be Derivado');
    }

}