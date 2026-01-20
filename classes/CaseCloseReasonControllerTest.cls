@isTest
public class CaseCloseReasonControllerTest {

    @TestSetup static void setup() {
        Case caseTestReclamo = (Case)TestFactoryFramework.createSObject(new Case(), 'TestFactoryFrameworkDefaults.ReclamoCaseDefaults', false);
        caseTestReclamo.Type = 'Ahorro programado';
        caseTestReclamo.Reason = 'Creación';
        caseTestReclamo.Description = 'testDescription';
        caseTestReclamo.Subject = 'TestCaseCloseReason';
        insert caseTestReclamo;
    }

    @isTest
    public static void testGetTipificadorCloseReason(){
        List<Case> c = [SELECT Id, Type, Reason, Vazquez_Group_Company__c FROM Case WHERE Subject = 'TestCaseCloseReason' LIMIT 1];
        String company = 'UENO_BANK';
        String typeName = c[0].Type;
        String reasonName = c[0].Reason;
        Test.startTest();
            List<CaseCloseReasonController.picklistValues> tip = CaseCloseReasonController.getCloseReason(company,typeName,reasonName, c[0].Id);
        Test.stopTest();
		Assert.areEqual(true, !tip.isEmpty(), 'Debe obtener registros de Valores');
    }

    @isTest
    public static void testGetTipificadorSavePreferredCloseReason(){
        List<Case> c = [SELECT Id FROM Case WHERE Subject = 'TestCaseCloseReason' LIMIT 1];
        Test.startTest();
            CaseCloseReasonController.savePreferredCloseReason(c[0].Id,'Solicitud aprobada','','Resolución a favor');
        Test.stopTest();
        Case result = [SELECT CloseReason__c FROM Case WHERE Id = :c[0].Id LIMIT 1];
        Assert.areEqual('Solicitud aprobada', result.CloseReason__c, 'Debe obtener valores en Close Reason');
    }

    @isTest
    public static void testGetTipificadorCleanCloseReason(){
        List<Case> c = [SELECT Id FROM Case WHERE Subject = 'TestCaseCloseReason' LIMIT 1];
        Test.startTest();
            CaseCloseReasonController.cleanCloseReason(c[0].Id);
        Test.stopTest();
        Case result = [SELECT CloseReason__c FROM Case WHERE Id = :c[0].Id LIMIT 1];
        Assert.areEqual(null, result.CloseReason__c, 'No Debe obtener valores en Close Reason');
    }

    @isTest
    public static void testGetTipificadorCloseReasonDescription(){
        List<Case> c = [SELECT Id, Type, Reason, Vazquez_Group_Company__c FROM Case WHERE Subject = 'TestCaseCloseReason' LIMIT 1];
        String company = 'UENO_BANK';
        String typeName = c[0].Type;
        String reasonName = c[0].Reason;
        Test.startTest();
            String result = CaseCloseReasonController.getCloseReasonDescription(company,typeName,reasonName,'Solicitud aprobada');
        Test.stopTest();
		Assert.areNotEqual(null, result, 'Debe obtener registros de Descripcion');
    }

}