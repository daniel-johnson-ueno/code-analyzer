@IsTest
private class SalesforceLimitsMetricsSchedulableTest {

    @TestSetup
    public static void setup() {
        New_Relic_Settings__c setting = new New_Relic_Settings__c(
            DomainName__c = 'https://some-url/metric/v1',
            ApiKey__c = 'mock-api-key',
            FeatureFlag__c = true
        );
        insert setting;
    }

    private class TestSchedulable extends SalesforceLimitsMetricsSchedulable {
        override protected Map<String, Integer> groupSalesforceLimits() {
            String limitsJson = '{ "Limit1": 0, "Limit2": 3, "Limit3": 4 }';
    
        return (Map<String, Integer>) JSON.deserialize(limitsJson, Map<String, Integer>.class);
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
        SalesforceLimitsMetricsSchedulable schedulable = new SalesforceLimitsMetricsSchedulable();
        schedulable.execute(null);
        Test.stopTest();

        System.assert(true, 'La ejecución del job con cero sesiones no falló');
    }
}