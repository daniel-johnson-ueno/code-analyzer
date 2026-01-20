@isTest
private class NewRelicMetricsSenderTest {

    @TestSetup
    public static void setup() {
        New_Relic_Settings__c setting = new New_Relic_Settings__c(
            DomainName__c = 'https://some-url/metric/v1',
            ApiKey__c = 'mock-api-key',
            FeatureFlag__c = true
        );
        insert setting;
    }

    private static List<NewRelicMetricsSender.MetricsWrapper> buildValidPayload() {
        Map<String, Object> attributes = new Map<String, Object>{ 'env' => 'test', 'region' => 'us' };
        return new NewRelicMetricsSender.MetricsWrapperBuilder()
            .addMetric('salesforce.test.login.count', 'COUNT', 1, Datetime.newInstance(2025,01,01,01,01,01).getTime(), 60000L, attributes)
            .build();
    }

    private static List<NewRelicMetricsSender.MetricsWrapper> buildInValidPayload() {
        Map<String, Object> attributes = new Map<String, Object>{ 'env' => 'test', 'region' => 'us' };
        return new NewRelicMetricsSender.MetricsWrapperBuilder()
            .addMetric('salesforce.test.login.count', 'INVALID', 1, Datetime.newInstance(2025,01,01,01,01,01).getTime(), 60000L, attributes)
            .build();
    }

    @IsTest
    public static void testSendMetricsSuccess() {
        
        String mock = '[{"metrics":[{"value":1,"type":"COUNT","timestamp":1735693261,"name":"salesforce.test.login.count","interval.ms":60000,"attributes":{"region":"us","env":"test"}}]}]';
        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(202, 'Ok', mock));

        Test.startTest();
        NewRelicMetricsSender.sendMetricsToNewRelic(buildValidPayload());
        Test.stopTest();
    }

    @IsTest
    public static void testInvalidMetricType() {
        List<NewRelicMetricsSender.MetricsWrapper> invalidMetricPayload = buildInValidPayload();

        Test.startTest();
        try {
            NewRelicMetricsSender.sendMetricsToNewRelic(invalidMetricPayload);
            System.assert(false, 'Se esperaba excepción por tipo de métrica inválido');
        } catch (NewRelicMetricsSender.InvalidMetricTypeException e) {
            System.assert(e.getMessage().contains('Tipo de métrica inválido'));
        }
        Test.stopTest();
    }


    @IsTest
    public static void testMetricsWrapperBuilder() {
        List<NewRelicMetricsSender.MetricsWrapper> built = new NewRelicMetricsSender.MetricsWrapperBuilder()
            .addMetric('salesforce.test.metric', 'COUNT', 2.5, DateTime.now().getTime(), 5000L, new Map<String, Object>())
            .build();

        System.assertEquals(1, built.size());
        System.assertEquals(1, built[0].metrics.size());
        System.assertEquals('salesforce.test.metric', built[0].metrics[0].name);
    }
}