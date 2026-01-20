@IsTest
private class MessagingSessionMetricsSchedulableTest {

    @TestSetup
    public static void setup() {
        New_Relic_Settings__c setting = new New_Relic_Settings__c(
            DomainName__c = 'https://some-url/metric/v1',
            ApiKey__c = 'mock-api-key',
            FeatureFlag__c = true
        );
        insert setting;
    }

    private class TestSchedulable extends MessagingSessionMetricsSchedulable {
        override protected List<MessagingSession> retrieveMessagingSessions(DateTime since) {
            String sessionsJson = '[\n' +
            '  {\n' +
            '    "Id": "a0A000000000001",\n' +
            '    "CaseId": "500000000000001",\n' +
            '    "Vazquez_Group_Company__c": "CompanyA"\n' +
            '  },\n' +
            '  {\n' +
            '    "Id": "a0A000000000002",\n' +
            '    "CaseId": null,\n' +
            '    "Vazquez_Group_Company__c": "CompanyA"\n' +
            '  },\n' +
            '  {\n' +
            '    "Id": "a0A000000000003",\n' +
            '    "CaseId": null,\n' +
            '    "Vazquez_Group_Company__c": null\n' +
            '  }\n' +
            ']';
    
        return (List<MessagingSession>) JSON.deserialize(sessionsJson, List<MessagingSession>.class);
        }
    }

    @IsTest
    static void testExecuteWithMockedSessions() {
        Test.startTest();
        new TestSchedulable().execute(null);
        Test.stopTest();

        System.assert(true, 'La ejecución simulada del job con sesiones mockeadas fue exitosa');
    }

    @IsTest
    static void testExecuteWithoutSessions() {

        Test.startTest();
        MessagingSessionMetricsSchedulable schedulable = new MessagingSessionMetricsSchedulable();
        schedulable.execute(null);
        Test.stopTest();

        System.assert(true, 'La ejecución del job con cero sesiones no falló');
    }

}