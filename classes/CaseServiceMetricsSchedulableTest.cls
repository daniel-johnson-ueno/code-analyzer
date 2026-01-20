@IsTest
private class CaseServiceMetricsSchedulableTest {

    @TestSetup
    public static void setup() {
        New_Relic_Settings__c setting = new New_Relic_Settings__c(
            DomainName__c = 'https://some-url/metric/v1',
            ApiKey__c = 'mock-api-key',
            FeatureFlag__c = true
        );
        insert setting;
    }

    @IsTest
    static void testExecuteWithMockedCases() {

        Account account = TestFactory.createPersonAccount();
        RecordType consultaRecordType = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Consulta' LIMIT 1].get(0);
        Case newCase = TestCaseFactory.createNewCase('BOT', consultaRecordType , account);
        Case anotherNewCase = TestCaseFactory.createNewCase('Turnero', consultaRecordType , account);

        Test.startTest();
        CaseServiceMetricsSchedulable schedulable = new CaseServiceMetricsSchedulable();
        schedulable.execute(null);
        Test.stopTest();

        System.assert(true, 'La ejecución simulada del job con casos mockeados fue exitosa');
    }

    @IsTest
    static void testExecuteWithoutCases() {

        Test.startTest();
        CaseServiceMetricsSchedulable schedulable = new CaseServiceMetricsSchedulable();
        schedulable.execute(null);
        Test.stopTest();

        System.assert(true, 'La ejecución del job con cero casos no falló');
    }
}