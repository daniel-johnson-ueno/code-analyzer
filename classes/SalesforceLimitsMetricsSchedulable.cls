global virtual class SalesforceLimitsMetricsSchedulable implements Schedulable{
    private static final String METRIC_NAME = 'salesforce.limits';
    private static final String METRIC_TYPE = 'gauge';
    private static final String METRIC_LIMIT_NAME = 'limitName';

    global void execute(SchedulableContext sc) {
        try{
            DateTime now = DateTime.now();
            DateTime fifteenMinutesAgo = now.addMinutes(-15);
            Long timestamp = fifteenMinutesAgo.getTime() / 1000;
            Long intervalMs = 15 * 60 * 1000;

            Map<String, Integer> groupedLimits = groupSalesforceLimits();
            List<NewRelicMetricsSender.MetricsWrapper> payload = buildMetricsPayload(groupedLimits, timestamp, intervalMs);

            if (!payload.isEmpty()) {
                NewRelicMetricsSender.sendMetricsToNewRelic(payload);
            }
        } catch (Exception ex) {
            GenerateLogEvent.generateErrorLogEvent(ex, 'SalesforceLimitsMetricsSchedulable', 'SalesforceLimitsMetricsSchedulable', 'execute');
            System.debug('Error ejecutando ' + 'SalesforceLimitsMetricsSchedulable' + ': ' + ex.getMessage());
        }
    }

    protected virtual Map<String, Integer> groupSalesforceLimits() {
        Map<String, Integer> limitsMap = new Map<String, Integer>();
        List<System.OrgLimit> limits = System.OrgLimits.getAll();
        for (System.OrgLimit lim: limits) {
            if(lim.getLimit() > 0){
                Integer limitUsed = lim.getValue();
                Integer limitMax = lim.getLimit();
                Integer usagePercentage = limitUsed != 0 ? Math.round(((Decimal) limitUsed / limitMax) * 100) : 0;
                limitsMap.put(lim.getName(), usagePercentage);
            }
        }
        return limitsMap;
    }

    private static List<NewRelicMetricsSender.MetricsWrapper> buildMetricsPayload(Map<String, Integer> groupedLimits, Long timestamp, Long intervalMs) {
        NewRelicMetricsSender.MetricsWrapperBuilder builder = new NewRelicMetricsSender.MetricsWrapperBuilder();
        for (String name : groupedLimits.keySet()) {
            Integer count = groupedLimits.get(name);
            builder.addMetric(
                METRIC_NAME,
                METRIC_TYPE,
                count,
                timestamp,
                intervalMs,
                new Map<String, Object>{
                    METRIC_LIMIT_NAME => name
                }
            );
        }
        return builder.build();
    }
}