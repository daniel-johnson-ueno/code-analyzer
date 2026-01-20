@isTest
public class IncidentTriggerHandlerTest {

    @TestSetup static void setup() {

        Account testPersonAccount = (Account)TestFactoryFramework.createSObject(new Account(), 'TestFactoryFrameworkDefaults.InternalCompanyAccountDefaults', false);
        testPersonAccount.Name = 'Incidencia Masiva';
        insert testPersonAccount;

        Incident inc = new Incident();
        inc.Impact = 'Parcial';
        inc.Tipo__c = 'Ahorro programado';
        inc.Motivo__c = 'Creación';
        inc.Origen__c = 'Casos';
        inc.Priority = 'Baja';
        inc.Status = 'Nuevo';
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
        caseTest.Incident__c = inc.Id;
        caseTest.Subject = '';
        caseTest.Description = 'Test Case';
        insert caseTest;

        Case caseTestReclamo = (Case)TestFactoryFramework.createSObject(new Case(), 'TestFactoryFrameworkDefaults.ReclamoCaseDefaults', false);
        caseTestReclamo.Origin = 'Web';
        caseTestReclamo.Type = '';
        caseTestReclamo.Reason = '';
        caseTestReclamo.Status = 'Nuevo';
        caseTestReclamo.AccountId = testPersonAccount.id;
        caseTestReclamo.Incident__c = inc.Id;
        caseTestReclamo.Subject = 'Test Reclamo';
        caseTestReclamo.Description = '';
        insert caseTestReclamo;
        
    }

    @isTest
    public static void testStatusEnValidacion() {
        Test.startTest();
            List<Incident> inc = [SELECT Id, Status FROM Incident LIMIT 1];
            inc[0].Status = 'En validación';
            update inc[0];
        Test.stopTest();
        Incident result = [SELECT Id, status FROM Incident WHERE Id =: inc[0].Id];
        Assert.areEqual('En validación',result.status, 'Status shoould be En validación');
        List<Case> casesRelated = [SELECT Id, Status, Motivo_en_validacion__c, Type, Reason, Subject, RecordType.Name FROM Case WHERE Incident__c =: inc[0].Id];
        Assert.areEqual('En validación',casesRelated[0].Status, 'Status shoould be En validación');
    }

    @isTest
    public static void testStatusEnCurso() {
        Test.startTest();
            List<Incident> inc = [SELECT Id, Status FROM Incident LIMIT 1];
            inc[0].Status = 'En curso';
            update inc[0];
        Test.stopTest();
        Incident result = [SELECT Id, status FROM Incident WHERE Id =: inc[0].Id];
        Assert.areEqual('En curso',result.status, 'Status shoould be En curso');
    }

    @isTest
    public static void testStatusCerrado() {
        Test.startTest();
            List<Incident> inc = [SELECT Id, Status FROM Incident LIMIT 1];
            inc[0].Status = 'Cerrado';
            update inc[0];
        Test.stopTest();
        Incident result = [SELECT Id, status FROM Incident WHERE Id =: inc[0].Id];
        Assert.areEqual('Cerrado',result.status, 'Status shoould be Cerrado');
        List<Case> casesRelated = [SELECT Id, Status, Close_Reason_Automatic__c FROM Case WHERE Incident__c =: inc[0].Id];
        Assert.areEqual('Cerrado por incidente',casesRelated[0].Close_Reason_Automatic__c, 'Status shoould be Cerrado por incidente');
    }

}