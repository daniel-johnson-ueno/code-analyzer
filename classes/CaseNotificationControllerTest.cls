@IsTest
private class CaseNotificationControllerTest {
    @TestSetup
    private static void setup(){
        Ueno_Service_Domain__c testUrl= new Ueno_Service_Domain__c(ApiKey__c = '555-555-555',DomainName__c='https://kongcloud.ind-dev-sae1.ueno.com.py');
        insert  testUrl;
    }

    @IsTest
    private static void newCaseNotificationCalloutTest(){
        Account account = TestFactory.createPersonAccount();
        Case caseObject = TestFactory.createCase('Escalado', 'Reclamo', account.Id);
        CaseNotificationController.TestCase testCase = new CaseNotificationController.TestCase();
        testCase.caseObject = caseObject;
        testCase.isNew = true;

        List<CaseNotificationController.TestCase> listTestCases = new List<CaseNotificationController.TestCase>();
        listTestCases.add(testCase);

        Test.startTest();

        CaseNotificationController.sendCaseNotification(listTestCases);

        Test.stopTest();
    }

    @IsTest
    private static void closedCaseNotificationCalloutTest() {
        Account account = TestFactory.createPersonAccount();
        Case caseObject = TestFactory.createCase('Escalado', 'Reclamo', account.Id);
        caseObject.Description = 'Descripcion de prueba';
        caseObject.Subject = 'Asunto de prueba';
        caseObject.Status = 'Cerrado';
        caseObject.Resolution__c = 'Resolución a favor';
        update caseObject;

        CaseNotificationController.TestCase testCase = new CaseNotificationController.TestCase();
        testCase.caseObject = caseObject;
        testCase.isNew = false;

        List<CaseNotificationController.TestCase> listTestCases = new List<CaseNotificationController.TestCase>();
        listTestCases.add(testCase);

        Test.startTest();
        CaseNotificationController.sendCaseNotification(listTestCases);
        Test.stopTest();
    }
}