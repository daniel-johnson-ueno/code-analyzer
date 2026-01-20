/*Clase batch que inserta registros de Métricas de agentes*/

public class InsertCaseChatMetricsBatch implements Database.Batchable<SObject>, Schedulable {

    public static Datetime now = System.now();
    public static Datetime toTime = now.addHours(Integer.valueOf(System.Label.APX_ToTimeValue));
    public static Datetime fromTime  = toTime.addHours(Integer.valueOf(System.Label.APX_FromTimeValue));

    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT Id, ConversationId, CaseId, Status, CreatedDate FROM MessagingSession WHERE CreatedDate >= :fromTime AND EndTime <= :toTime  AND CaseId != NULL AND CaseChatMetricsCount__c = 0]); /*Id IN ('0MwWK000003gSz30AE','0MwWK000003jqyQ0AQ','0MwWK000003jqf40AA','0MwWK000003gUMX0A2') AND   Id = '0MwWK000003gUMX0A2'*/
    }

    public void execute(Database.BatchableContext BC, List<MessagingSession> scope){

        if(!scope.isEmpty()){

            Set<Id> conversationIds = new Set<Id>();
            Map<String, MessagingSession> sessionByConversationId = new Map<String, MessagingSession>();
            Set<Id> messagingSessionIds = new Set<Id>();

            for(MessagingSession ms : scope){

                conversationIds.add(ms.ConversationId);
                sessionByConversationId.put(ms.ConversationId, ms);
                messagingSessionIds.add(ms.Id);

            }

            if(!conversationIds.isEmpty()){

                Map<String,ConversationParticipant> conversationParticipants = new Map <String, ConversationParticipant> (getConversationParticipants(conversationIds));
                Map<String, List<ConversationEntry>> conversationEntriesByConvAgentId = new Map<String, List<ConversationEntry>>();
                List<ConversationEntry> conversationEntries = getConversationEntries(conversationIds);

                if(!conversationEntries.isEmpty()){
                    conversationEntriesByConvAgentId = filterAndGroupConversationEntries(conversationEntries);

                    if(!conversationEntriesByConvAgentId.isEmpty() && !conversationParticipants.isEmpty()){
                        processConversationEntries(conversationEntriesByConvAgentId, conversationParticipants, sessionByConversationId);

                    }

                }

            }

        }

    }

    public void finish(Database.BatchableContext BC){
        System.debug('InsertCaseChatMetricsBatch finish');
    }

    private static Map<String, List<ConversationEntry>> filterAndGroupConversationEntries(List<ConversationEntry> conversationEntries) {
        Map<String, List<ConversationEntry>> conversationEntriesByConvAgentId = new Map<String, List<ConversationEntry>>();
        List<ConversationEntry> convEntries = new List<ConversationEntry>();
        String conversationId = '';
        String agentId = '';
        String lastActorType = '';
        String secondLastActorType = '';

        for (ConversationEntry conversationEntry : conversationEntries) {

            conversationId = conversationEntry.ConversationId;

            if (conversationEntry.ActorType != 'System') {

                if (conversationEntry.ActorType != 'EndUser') {
                    agentId = conversationEntry.ActorId;
                }
                convEntries.add(conversationEntry);
            }

            if(lastActorType == 'System' && secondLastActorType != 'System' && conversationEntry.ActorType == 'System'){
                agentId = '';
                convEntries.clear();
            }

            if(lastActorType != 'System' && conversationEntry.ActorType == 'System' && agentId != ''){
                String key = conversationEntry.ConversationId + agentId;
                conversationEntriesByConvAgentId.put(key, new List<ConversationEntry>(convEntries));
                agentId = '';
                convEntries.clear();
            }



            secondLastActorType = lastActorType;
            lastActorType = conversationEntry.ActorType;
        }

        return conversationEntriesByConvAgentId;
    }

    private static void processConversationEntries(Map<String, List<ConversationEntry>> conversationEntriesByConvAgentId, Map<String, ConversationParticipant> conversationParticipantByConvId, Map<String, MessagingSession> sessionByConversationId) {
        List<AgentChatMetrics__c> metricsToInsert = new List<AgentChatMetrics__c>();
        List<AgentChatMetrics__c> metricsToUpdate = new List<AgentChatMetrics__c>();

        for (List<ConversationEntry> conversationEntries : conversationEntriesByConvAgentId.values()) {
            AgentChatMetrics__c metric = new AgentChatMetrics__c();
            ConversationParticipant cp = null;
            MessagingSession ms = null;

            Decimal agentNRT = 0;
            Decimal interactionsNRT = 0;
            Boolean agentParticipates = false;
            Boolean isFRT = true;

            ConversationEntry firstGuestResponse = null;
            ConversationEntry firstAgentResponse = null;

            for (ConversationEntry conversationEntry : conversationEntries) {

                if (conversationEntry.ActorType == 'Agent' && conversationParticipantByConvId.containsKey(conversationEntry.ActorId) && (cp == null || cp.Id != conversationParticipantByConvId.get(conversationEntry.ActorId).Id)) {
                    cp = conversationParticipantByConvId.get(conversationEntry.ActorId);
                }

                if (ms == null /*|| ms.Id != sessionByConversationId.get(conversationEntry.ConversationId).Id*/) {
                    ms = sessionByConversationId.get(conversationEntry.ConversationId);
                }

                if (ms != null) {

                    if (conversationEntry.ActorType == 'EndUser' && firstGuestResponse == null) {
                        firstGuestResponse = conversationEntry;
                    } else if (conversationEntry.ActorType == 'Agent' && firstAgentResponse == null) {
                        firstAgentResponse = conversationEntry;
                        agentParticipates = true;
                    }

                    if (firstAgentResponse != null && firstGuestResponse != null) {

                        if (isFRT && firstAgentResponse.EntryTime > firstGuestResponse.EntryTime) {
                            isFRT = false;
                            firstAgentResponse = null;
                            firstGuestResponse = null;
                        } else {

                            if (firstAgentResponse.EntryTime > firstGuestResponse.EntryTime) {
                                agentNRT += (firstAgentResponse.EntryTime.getTime() - firstGuestResponse.EntryTime.getTime()) / 1000;
                                interactionsNRT++;
                                firstAgentResponse = null;
                                firstGuestResponse = null;
                            } else {
                                firstAgentResponse = null;
                            }
                        }
                    }
                }
            }

            if (metric != null) {

                metric.MessagingSession__c = ms.Id;
                metric.Case__c = ms.CaseId;
                metric.Agent__c = cp.ParticipantEntityId;
                metric.NRT__c = agentNRT;
                metric.NRTInteractions__c = interactionsNRT;
                metric.AgentParticipates__c = agentParticipates;

                if (cp != null && cp.JoinedTime != null && cp.LeftTime != null) {
                    metric.TotalChattedTime__c = (cp.LeftTime.getTime() - cp.JoinedTime.getTime()) / 1000;
                }

                if (metric.Id != null) {
                    metricsToUpdate.add(metric);
                } else {
                    metricsToInsert.add(metric);
                }
            }
        }

        if (!metricsToInsert.isEmpty()) {
            insert metricsToInsert;
        }

    }

    private static List<ConversationEntry> getConversationEntries(Set<Id> conversationIds){
        List<ConversationEntry> ceToCalculate = new List<ConversationEntry>();
        if(!Test.isRunningTest()){
            ceToCalculate = [SELECT Id, ConversationId, ActorId, Seq, EntryTime, EntryType, ActorType FROM ConversationEntry WHERE ConversationId IN :conversationIds AND EntryType = 'Text' ORDER BY ConversationId, CreatedDate, Seq ASC];
        }else {
            ceToCalculate = [SELECT Id, ConversationId, ActorId, Seq, EntryTime, EntryType, ActorType FROM ConversationEntry WHERE ConversationId IN :conversationIds AND EntryType = 'Text' ORDER BY Seq ASC];
        }
        return ceToCalculate;
    }

    private static List<ConversationParticipant> getConversationParticipants(Set<Id> conversationIds){
        if(Test.isRunningTest()){
            return testData();
        }
        return [SELECT Id, ParticipantEntityId, ParticipantDisplayName, ConversationId, CreatedDate, JoinedTime, LeftTime
        FROM ConversationParticipant WHERE ConversationId IN :conversationIds AND ParticipantRole = 'Agent'
        ORDER BY ConversationId, CreatedDate];
    }

    private static List<ConversationParticipant> testData(){
        Id profIdSU = [SELECT Id FROM Profile LIMIT 1].Id;
        List<User> testUsers = [SELECT Id FROM User WHERE ProfileId = :profIdSU AND IsActive = true LIMIT 1];
        Id conversationId = Label.ConversationId;
        User testUser;
        if(!testUsers.isEmpty()){
            testUser = testUsers[0];
        }
        String participantsJson = '[\n' +
                    '  {\n' +
                    '    "Id": "' + testUser.Id + '",\n' +
                    '    "ConversationId": "' + conversationId + '",\n' +
                    '    "ParticipantEntityId": "' + testUser.Id + '",\n' +
                    '    "ParticipantRole": "Agent" \n' +
                    '  }\n' +
                    ']';
        return (List<ConversationParticipant>) JSON.deserialize(participantsJson, List<ConversationParticipant>.class);
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new InsertCaseChatMetricsBatch(), 100);
    }
}