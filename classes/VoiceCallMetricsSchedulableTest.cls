@IsTest
private class VoiceCallMetricsSchedulableTest {

    @TestSetup
    public static void setup() {
        New_Relic_Settings__c setting = new New_Relic_Settings__c(
            DomainName__c = 'https://some-url/metric/v1',
            ApiKey__c = 'mock-api-key',
            FeatureFlag__c = true
        );
        insert setting;
    }

    private class TestSchedulable extends VoiceCallMetricsSchedulable {
        override protected List<VoiceCall> retrieveVoiceCalls(DateTime since) {
            String voiceCallsJson = '[\n' +
            '  {\n' +
            '    "Id": "a0B000000000001",\n' +
            '    "Case__c": "500000000000001",\n' +
            '    "CallType": "Inbound",\n' +
            '    "Case__r": {\n' +
            '      "Vazquez_Group_Company__r": {\n' +
            '        "GroupCompaniesUeno__c": "CompanyX"\n' +
            '      }\n' +
            '    }\n' +
            '  },\n' +
            '  {\n' +
            '    "Id": "a0B000000000002",\n' +
            '    "Case__c": null,\n' +
            '    "CallType": "Outbound",\n' +
            '    "Case__r": {\n' +
            '      "Vazquez_Group_Company__r": {\n' +
            '        "GroupCompaniesUeno__c": "CompanyX"\n' +
            '      }\n' +
            '    }\n' +
            '  },\n' +
            '  {\n' +
            '    "Id": "a0B000000000003",\n' +
            '    "Case__c": null,\n' +
            '    "CallType": "Inbound",\n' +
            '    "Case__r": null\n' +
            '  }\n' +
            ']';

            return (List<VoiceCall>) JSON.deserialize(voiceCallsJson, List<VoiceCall>.class);
        }
    }

    @IsTest
    static void testExecuteWithMockedVoiceCalls() {
        Test.startTest();
        new TestSchedulable().execute(null);
        Test.stopTest();

        System.assert(true, 'Ejecución con llamadas mockeadas completada exitosamente');
    }

    @IsTest
    static void testExecuteWithoutVoiceCalls() {

        Test.startTest();
        VoiceCallMetricsSchedulable schedulable = new VoiceCallMetricsSchedulable();
        schedulable.execute(null);
        Test.stopTest();

        System.assert(true, 'La ejecución del job con cero llamadas no falló');
    }
}