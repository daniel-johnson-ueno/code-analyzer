global virtual class MessagingSessionMetricsSchedulable implements Schedulable{

    private static final String METRIC_NAME = 'salesforce.case.integrations.count';
    private static final String METRIC_TYPE = 'count';
    private static final String METRIC_ATTRIBUTE_HAS_CASE = 'hasCase';
    private static final String METRIC_ATTRIBUTE_CHANNEL = 'channel';
    private static final String METRIC_ATTRIBUTE_COMPANY = 'company';
    private static final String METRIC_VALUE_CHANNEL = 'messaging';

    global void execute(SchedulableContext sc) {
        DateTime now = DateTime.now();
        DateTime fifteenMinutesAgo = now.addMinutes(-15);
        Long timestamp = fifteenMinutesAgo.getTime() / 1000;
        Long intervalMs = 15 * 60 * 1000;

        List<MessagingSession> sessions = retrieveMessagingSessions(fifteenMinutesAgo);
        Map<String, Map<Boolean, Integer>> groupedCounts = groupSessionsByCompanyAndCaseStatus(sessions);
        List<NewRelicMetricsSender.MetricsWrapper> payload = buildMetricsPayload(groupedCounts, timestamp, intervalMs);

        if (!payload.isEmpty()) {
            NewRelicMetricsSender.sendMetricsToNewRelic(payload);
        }
    }

    protected virtual List<MessagingSession> retrieveMessagingSessions(DateTime since) {
        return [
            SELECT Id, CaseId, Vazquez_Group_Company__c 
            FROM MessagingSession 
            WHERE CreatedDate >= :since
        ];
    }

    private static Map<String, Map<Boolean, Integer>> groupSessionsByCompanyAndCaseStatus(List<MessagingSession> sessions) {
        Map<String, Map<Boolean, Integer>> groupedCounts = new Map<String, Map<Boolean, Integer>>();

        for (MessagingSession s : sessions) {
            String company = String.isBlank(s.Vazquez_Group_Company__c) ? 'Unknown' : s.Vazquez_Group_Company__c;
            Boolean hasCase = (s.CaseId != null);

            if (!groupedCounts.containsKey(company)) {
                groupedCounts.put(company, new Map<Boolean, Integer>{ true => 0, false => 0 });
            }

            Map<Boolean, Integer> countMap = groupedCounts.get(company);
            countMap.put(hasCase, countMap.get(hasCase) + 1);
        }

        return groupedCounts;
    }

    private static List<NewRelicMetricsSender.MetricsWrapper> buildMetricsPayload(Map<String, Map<Boolean, Integer>> groupedCounts, Long timestamp, Long intervalMs) {
        NewRelicMetricsSender.MetricsWrapperBuilder builder = new NewRelicMetricsSender.MetricsWrapperBuilder();

        for (String company : groupedCounts.keySet()) {
            Map<Boolean, Integer> countMap = groupedCounts.get(company);

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
                            METRIC_ATTRIBUTE_CHANNEL => METRIC_VALUE_CHANNEL,
                            METRIC_ATTRIBUTE_COMPANY => company
                        }
                    );
                }
            }
        }

        return builder.build();
    }
}