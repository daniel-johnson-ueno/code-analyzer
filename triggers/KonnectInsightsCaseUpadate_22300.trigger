trigger KonnectInsightsCaseUpadate_22300 on Case (after update) {
    public static String KI_ENDPOINT = Label.KonnectInsightsEndPoint;
    for(Case caseOld: Trigger.old){
        if(caseOld.Origin != null && caseOld.Origin.contains('Konnect Insights')){
            for(Case caseNew: Trigger.new){
                if(caseOld.CaseNumber==CaseNew.CaseNumber && caseOld.Status!=CaseNew.Status){
                    String url = KI_ENDPOINT;
                    String content = KonnectInsightsTicketEventUpdates.JsonContentFromObject(caseNew);
                    KonnectInsightsTicketEventUpdates.callout(url, content);
                }
            }
        }
    }
}