global class CaseServiceMetricsSchedulable implements Schedulable {
    private static final String METRIC_NAME = 'salesforce.case.service.count';
    private static final String METRIC_TYPE = 'count';
    private static final String METRIC_ATTRIBUTE_HAS_ACCOUNT = 'hasAccount';
    private static final String METRIC_ATTRIBUTE_ORIGIN = 'origin';
    private static final String METRIC_ATTRIBUTE_COMPANY = 'company';


    global void execute(SchedulableContext sc) {
        DateTime now = DateTime.now();
        DateTime fifteenMinutesAgo = now.addMinutes(-15);
        Long timestamp = fifteenMinutesAgo.getTime() / 1000;
        Long intervalMs = 15 * 60 * 1000;

        List<Case> cases = retrieveCases(fifteenMinutesAgo);
        Map<String, Map<String, Map<Boolean, Integer>>> groupedCounts = groupCasesByOriginCompanyAndClientStatus(cases);
        List<NewRelicMetricsSender.MetricsWrapper> payload = buildMetricsPayload(groupedCounts, timestamp, intervalMs);

        if (!payload.isEmpty()) {
            NewRelicMetricsSender.sendMetricsToNewRelic(payload);
        }
    }

    private static List<Case> retrieveCases(DateTime since) {
        return [
            SELECT AccountId, Origin, Vazquez_Group_Company__r.Name, CreatedDate 
            FROM Case 
            WHERE CreatedDate >= :since
        ];
    }

    private static Id getNoClienteId() {
        String orgId15 = UserInfo.getOrganizationId().substring(0, 15);
        General_Setting__mdt generalSettings = [
            SELECT No_Cliente_Id__c 
            FROM General_Setting__mdt 
            WHERE Id__c = :orgId15 
            LIMIT 1
        ];
        return generalSettings.No_Cliente_Id__c;
    }

    private static Map<String, Map<String, Map<Boolean, Integer>>> groupCasesByOriginCompanyAndClientStatus(List<Case> cases) {
        Id noClienteId = getNoClienteId();
        Map<String, Map<String, Map<Boolean, Integer>>> groupedCounts = new Map<String, Map<String, Map<Boolean, Integer>>>();

        for (Case c : cases) {
            String origin = resolveOrigin(c);
            String company = resolveCompany(c);
            Boolean hasAccount = determineHasAccount(c, noClienteId);

            incrementCount(groupedCounts, origin, company, hasAccount);
        }

        return groupedCounts;
    }

    private static String resolveOrigin(Case c) {
        return String.isBlank(c.Origin) ? 'Unknown' : c.Origin;
    }

    private static String resolveCompany(Case c) {
        return (c.Vazquez_Group_Company__r != null && !String.isBlank(c.Vazquez_Group_Company__r.Name))
            ? c.Vazquez_Group_Company__r.Name
            : 'Unknown';
    }

    private static Boolean determineHasAccount(Case c, Id noClienteId) {
        return c.AccountId != null && c.AccountId != noClienteId;
    }

    private static void incrementCount(
        Map<String, Map<String, Map<Boolean, Integer>>> groupedCounts,
        String origin,
        String company,
        Boolean hasAccount
    ) {
        if (!groupedCounts.containsKey(origin)) {
            groupedCounts.put(origin, new Map<String, Map<Boolean, Integer>>());
        }

        Map<String, Map<Boolean, Integer>> companyMap = groupedCounts.get(origin);

        if (!companyMap.containsKey(company)) {
            companyMap.put(company, new Map<Boolean, Integer>{ true => 0, false => 0 });
        }

        Map<Boolean, Integer> accountMap = companyMap.get(company);
        accountMap.put(hasAccount, accountMap.get(hasAccount) + 1);
    }

    private static List<NewRelicMetricsSender.MetricsWrapper> buildMetricsPayload(Map<String, Map<String, Map<Boolean, Integer>>> groupedCounts, Long timestamp, Long intervalMs) {
        NewRelicMetricsSender.MetricsWrapperBuilder builder = new NewRelicMetricsSender.MetricsWrapperBuilder();

        for (String origin : groupedCounts.keySet()) {
            Map<String, Map<Boolean, Integer>> companyMap = groupedCounts.get(origin);
            for (String company : companyMap.keySet()) {
                Map<Boolean, Integer> accountMap = companyMap.get(company);
                for (Boolean hasAccount : accountMap.keySet()) {
                    Integer count = accountMap.get(hasAccount);
                    if (count > 0) {
                        builder.addMetric(
                            METRIC_NAME,
                            METRIC_TYPE,
                            count,
                            timestamp,
                            intervalMs,
                            new Map<String, Object>{
                                METRIC_ATTRIBUTE_ORIGIN => origin,
                                METRIC_ATTRIBUTE_COMPANY => company,
                                METRIC_ATTRIBUTE_HAS_ACCOUNT => hasAccount
                            }
                        );
                    }
                }
            }
        }

        return builder.build();
    }
}