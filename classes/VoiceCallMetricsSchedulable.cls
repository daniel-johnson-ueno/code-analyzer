global virtual class VoiceCallMetricsSchedulable implements Schedulable{

    private static final String METRIC_NAME = 'salesforce.case.integrations.count';
    private static final String METRIC_TYPE = 'count';
    private static final String METRIC_ATTRIBUTE_HAS_CASE = 'hasCase';
    private static final String METRIC_ATTRIBUTE_CHANNEL = 'channel';
    private static final String METRIC_ATTRIBUTE_COMPANY = 'company';
    private static final String METRIC_VALUE_CHANNEL_INBOUND = 'voicecall.inbound';
    private static final String METRIC_VALUE_CHANNEL_OUTBOUND = 'voicecall.outbound';

    global void execute(SchedulableContext sc) {
        DateTime now = DateTime.now();
        DateTime fifteenMinutesAgo = now.addMinutes(-15);
        Long timestamp = fifteenMinutesAgo.getTime() / 1000;
        Long intervalMs = 15 * 60 * 1000;

        List<VoiceCall> calls = retrieveVoiceCalls(fifteenMinutesAgo);
        Map<String, Map<String, Map<Boolean, Integer>>> groupedCounts = groupVoiceCallsByCompanyCallTypeAndCaseStatus(calls);
        List<NewRelicMetricsSender.MetricsWrapper> payload = buildMetricsPayload(groupedCounts, timestamp, intervalMs);
        
        if (!payload.isEmpty()) {
            NewRelicMetricsSender.sendMetricsToNewRelic(payload);
        }
    }

    protected virtual List<VoiceCall> retrieveVoiceCalls(DateTime since) {
        return [
            SELECT Id, Case__c, CallType, Case__r.Vazquez_Group_Company__r.GroupCompaniesUeno__c
            FROM VoiceCall
            WHERE CreatedDate >= :since
        ];
    }

    private static Map<String, Map<String, Map<Boolean, Integer>>> groupVoiceCallsByCompanyCallTypeAndCaseStatus(List<VoiceCall> calls) {
        Map<String, Map<String, Map<Boolean, Integer>>> groupedCounts = new Map<String, Map<String, Map<Boolean, Integer>>>();

        for (VoiceCall vc : calls) {
            String company = vc.Case__r != null && !String.isBlank(vc.Case__r.Vazquez_Group_Company__r.GroupCompaniesUeno__c)
                ? vc.Case__r.Vazquez_Group_Company__r.GroupCompaniesUeno__c
                : 'Unknown';
            String channel = vc.CallType == 'Inbound' ? METRIC_VALUE_CHANNEL_INBOUND : METRIC_VALUE_CHANNEL_OUTBOUND;
            Boolean hasCase = (vc.Case__c != null);

            if (!groupedCounts.containsKey(company)) {
                groupedCounts.put(company, new Map<String, Map<Boolean, Integer>>());
            }

            Map<String, Map<Boolean, Integer>> companyMap = groupedCounts.get(company);
            if (!companyMap.containsKey(channel)) {
                companyMap.put(channel, new Map<Boolean, Integer>{ true => 0, false => 0 });
            }

            Map<Boolean, Integer> countMap = companyMap.get(channel);
            countMap.put(hasCase, countMap.get(hasCase) + 1);
        }

        return groupedCounts;
    }

    private static List<NewRelicMetricsSender.MetricsWrapper> buildMetricsPayload(
        Map<String, Map<String, Map<Boolean, Integer>>> groupedCounts,
        Long timestamp,
        Long intervalMs
    ) {
        NewRelicMetricsSender.MetricsWrapperBuilder builder = new NewRelicMetricsSender.MetricsWrapperBuilder();

        for (String company : groupedCounts.keySet()) {
            Map<String, Map<Boolean, Integer>> callTypeMap = groupedCounts.get(company);

            for (String channel : callTypeMap.keySet()) {
                Map<Boolean, Integer> countMap = callTypeMap.get(channel);

                for (Boolean hasCase : countMap.keySet()) {
                    Integer count = countMap.get(hasCase);
                    if (count > 0) {
                        builder.addMetric(
                            METRIC_NAME,
                            METRIC_TYPE,
                            count,
                            timestamp,
                            intervalMs,
                            new Map<String, Object>{
                                METRIC_ATTRIBUTE_HAS_CASE => hasCase,
                                METRIC_ATTRIBUTE_CHANNEL => channel,
                                METRIC_ATTRIBUTE_COMPANY => company
                            }
                        );
                    }
                }
            }
        }

        return builder.build();
    }
}