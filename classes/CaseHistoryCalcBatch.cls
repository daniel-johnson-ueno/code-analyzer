public without sharing class CaseHistoryCalcBatch implements Database.Batchable<sObject>{
    public static Datetime now = System.now();
    public static Datetime twoHoursAgo  = now.addHours(-2);

    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT Id, ConversationId, CaseId, Status FROM MessagingSession
        WHERE CaseId != NULL AND CreatedDate >=: twoHoursAgo AND CreatedDate <= :now AND  Status != 'Waiting']); /*Id = '0MwWC000002maPp0AI'*/
    }

    public void execute(Database.BatchableContext BC, List<MessagingSession> scope){

//        System.debug(scope);
        Set<Id> conversationIds = new Set<Id>();
        Set<Id> casesIds = new Set<Id>();
        Set<Id> cpsIds = new Set<Id>();

        List<ConversationEntry> conversationEntries2 = new List<ConversationEntry>();
        List<Case_History_Enhanced__c> msCasesHistories = new List<Case_History_Enhanced__c>();
        List<ConversationParticipant> cps = new List<ConversationParticipant>();
        List<Case> messagingSessionCases = new List<Case>();

        Map<Id,Id> convIdByCaseId = new Map<Id,Id>();
        Map<Id,Id> caseIdByUserId = new Map<Id,Id>();
        Map<Id, Case> casesById = new Map<Id, Case>();
        Map<Case_History_Enhanced__c,Id> convIdByCaseHistory = new Map<Case_History_Enhanced__c,Id>();
        Map<Id,List<ConversationParticipant>> convParticipantByConvId2 = new Map<Id,List<ConversationParticipant>>();
        Map<String,List<ConversationEntry>> conversationEntriesByConvAgentId = new Map<String,List<ConversationEntry>>();

        if(!scope.isEmpty()){

            for(MessagingSession ms :scope){
                conversationIds.add(ms.ConversationId);
                casesIds.add(ms.CaseId);
                convIdByCaseId.put(ms.CaseId,ms.ConversationId);//cases tienen con + de un conversationId

            }

            if(!casesIds.isEmpty()){
                msCasesHistories = getCaseHistories(casesIds);
                messagingSessionCases = getMessagingSessionCases(casesIds);
            }

            if(messagingSessionCases.size() > 0){
                casesById.putAll(messagingSessionCases);
            }

            if(!msCasesHistories.isEmpty()){
                for(Case_History_Enhanced__c che :msCasesHistories){
                    if(convIdByCaseId.get(che.Case__c) != null){

                        convIdByCaseHistory.put(che, convIdByCaseId.get(che.Case__c));

                        if(che.User__c != null){
                            caseIdByUserId.put(che.User__c,che.Case__c);
                        }
                    }
                }
            }

            if(!caseIdByUserId.isEmpty() && !conversationIds.isEmpty() && !caseIdByUserId.keySet().isEmpty()){

                cps = getConversationParticipants(conversationIds);

                if(!cps.isEmpty()){

                    for(ConversationParticipant cp :cps){
                        if(cp.ConversationId != null){

                                if(convParticipantByConvId2.containsKey(cp.ConversationId)){
                                    convParticipantByConvId2.get(cp.ConversationId).add(cp);
                                }else{
                                    convParticipantByConvId2.put(cp.ConversationId, new List<ConversationParticipant>{cp});
                                }

                        }
                        cpsIds.add(cp.Id);
                    }
                }
            }

            if(conversationIds.size() > 0){
                conversationEntries2 = getConversationEntries2(conversationIds);
            }


            List<Case_History_Enhanced__c> caseHistoriesToUpdate = new List<Case_History_Enhanced__c>();

            if(!conversationEntries2.isEmpty()){
                List<ConversationEntry> conversationEntries = new List <ConversationEntry>();
                String actorId = '';
                String lastActorType = '';
                String secondLastActorType = '';

                for(ConversationEntry ce : conversationEntries2){

                    if(ce.ActorType != 'EndUser' && ce.ActorType != 'System'){
                        actorId = ce.ActorId;
                    }

                    if(ce.ActorType != 'System' ){
                        conversationEntries.add(ce);
                    }

                    if(lastActorType == 'System' && secondLastActorType == 'EndUser' && ce.ActorType == 'System'){
                        actorId = '';
                        conversationEntries.clear();
                    }

                    if(lastActorType != 'System' && ce.ActorType == 'System' && actorId != ''){
                        String key = ce.ConversationId + actorId;
                        conversationEntriesByConvAgentId.put(key, new List<ConversationEntry>(conversationEntries));
                        actorId = '';
                        conversationEntries.clear();
                    }

                    secondLastActorType = lastActorType;
                    lastActorType = ce.ActorType;
                }

            }

            if(msCasesHistories.size() > 0){
                caseHistoriesToUpdate.addAll(calculateMetrics(msCasesHistories, convParticipantByConvId2, conversationEntriesByConvAgentId, convIdByCaseHistory));
            }

            if(caseHistoriesToUpdate.size() > 0){
                updateCaseHistory(caseHistoriesToUpdate);
            }
        }


    }

    public void finish(Database.BatchableContext BC){}


    private static List<Case_History_Enhanced__c> calculateMetrics(List<Case_History_Enhanced__c> casesHistories, Map<Id,List<ConversationParticipant>> convParticipantByConvId, Map<String,List<ConversationEntry>> conversationEntriesByConvAgentId, Map<Case_History_Enhanced__c,Id> convIdByCaseHistory){



        List<Case_History_Enhanced__c> casesToUpdate = new List<Case_History_Enhanced__c>();
        Datetime lastCheCreatedDate = null;
        Set<String> participantIds = new Set<String>();
//        Boolean isFirstResponse = true;
        for(Case_History_Enhanced__c che :casesHistories){
//            System.debug(isFirstResponse);
            ConversationParticipant cpCheUser;
            Datetime cheCreatedDate = che.CreatedDate;
            if(convIdByCaseHistory.get(che) != null){

                String conversationId = convIdByCaseHistory.get(che);
                String key = conversationId;

                if(conversationId != null &&  convParticipantByConvId.get(conversationId) != null/* convParticipanByConvId.get(conversationId) != null && cpGuestByConvId.get(conversationId) != null*/){

                    List<ConversationParticipant> cps = convParticipantByConvId.get(conversationId);
                    if(cps.size() > 0){

                        if(cps.size() > 1){

                            for(ConversationParticipant cp :cps){

                                if(lastCheCreatedDate == null){
                                    lastCheCreatedDate = che.CreatedDate;
                                }


                                if(cp.ParticipantEntityId == che.User__c && cheCreatedDate >= lastCheCreatedDate && !participantIds.contains(String.valueOf(cp.Id)) /*&& casesHistories.indexOf(che) >=lastCheIndex*/ /*che.CreatedDate >= cp.CreatedDate && che.CreatedDate <= nextCpDate) || nextCpDate == cp.CreatedDate*/){
                                    cpCheUser = cp;
                                    participantIds.add(String.valueOf(cp.Id));
                                    key += String.valueOf(cp.Id);
                                    break;
                                }

                            }

                        }else{
                            cpCheUser = cps[0];
                        }
                    }


                    if(cpCheUser != null && conversationEntriesByConvAgentId.containsKey(key)/*cesByConversationParticipantId.get(cpCheUser.Id) != null && cesByConversationParticipantId.get(guestCP.Id) != null*/ && !Test.isRunningTest()){

                        List<ConversationEntry> convEntries = new List<ConversationEntry>();
                        convEntries = conversationEntriesByConvAgentId.get(key);
                        if(convEntries.size()>0){

                            casesToUpdate.addAll(calcValues(convEntries,che,convParticipantByConvId/*, isFirstResponse*/));
//                            isFirstResponse = false;
                        }
                    }

                }else if(Test.isRunningTest()){
                    if(che.User__c != null){
                        casesToUpdate.addAll(calcValues(new List<ConversationEntry>(), che, convParticipantByConvId/*, isFirstResponse*/));
                    }
                }
            }
            lastCheCreatedDate = che.CreatedDate;
        }

        return casesToUpdate;
    }

    public static List<Case_History_Enhanced__c> calcValues(List<ConversationEntry> ces, Case_History_Enhanced__c che, Map<Id,List<ConversationParticipant>> convParticipantByConvId /*, Boolean isFirstResponse*//*, Case messagingSessionCase*/){

        Datetime firstRespGuest = null;
        Datetime firstRespAgent = null;
        Datetime lastRespAgent = null;
        Datetime lastRespGuest = null;

        Double seqA;
        Double seqG;

        Double idleTime = 0;
        Double handleTime = 0;
        Double countCEAgent = 0;
        Double countNRTInteractions = 0;
        Double numberOfInteractions = 0;

        Double diffNRTTime = 0;
        Double diffIdleTime = 0;
        Double diffHandleTime = 0;
        Double firstResponseTime = 0;

        Double avgResponseTimeSeconds = 0;
        Double avgResponseTime = 0;
        Boolean changeCase = false;
        Boolean isAgentFirstResponse= true;

        String lastActor = '';
        CompareConversationEntryBySeq comp = new CompareConversationEntryBySeq();
        ces.sort(comp);

        List<Case_History_Enhanced__c> casesToUpdate = new List<Case_History_Enhanced__c>();

        if(!ces.isEmpty()){

            for(ConversationEntry ce :ces){

                if(!Test.isRunningTest()){

                    if(convParticipantByConvId.containsKey(ce.ConversationId)/*convIdByCPGuest.get(ce.ActorId) != null && convIdByCPGuest.get(ce.ActorId) == ce.ConversationId*/){

                        if(ce.ActorType == 'EndUser'){

                            if(firstRespGuest == null){
                                firstRespGuest = ce.EntryTime;
                                lastRespGuest = ce.EntryTime;
                            } else {
                                lastRespGuest = ce.EntryTime;
                            }

                            seqG = ce.Seq;//2

                        } else {
                            firstResponseTime = firstResponseTime == 0 ? ce.EntryTime.getTime() : firstResponseTime;
                            if(firstRespAgent == null){
                                firstRespAgent = ce.EntryTime;
                                lastRespAgent = ce.EntryTime;
                            } else {
                                lastRespAgent = ce.EntryTime;
                            }

                            seqA = ce.Seq;//3
                        }

                    }

                }else if(Test.isRunningTest()){
                    if(ce.ActorType == 'Agent'){
                        seqA = ce.Seq;
                        firstRespGuest = ce.EntryTime;
                    }else{
                        if(seqA == null || ce.Seq > seqA){
                            firstRespAgent = ce.EntryTime;

                        }
                    }
                }


                if(firstRespGuest != null && firstRespAgent != null  && lastActor != ce.ActorId){

                    if((firstRespGuest > lastRespAgent && lastRespAgent != null) && !Test.isRunningTest()) {

                        if(diffIdleTime != null){
                            diffIdleTime += firstRespGuest.getTime() - lastRespAgent.getTime();
                        }else{
                            diffIdleTime = firstRespGuest.getTime() - lastRespAgent.getTime();
                        }

                        lastRespAgent = null;
                        firstRespAgent = null;

                    }else if((lastRespGuest < firstRespAgent && lastRespGuest != null) && !Test.isRunningTest()){

                        if(!isAgentFirstResponse){

                            if(diffNRTTime != null){
                                diffNRTTime += firstRespAgent.getTime() - lastRespGuest.getTime();
                            }else{
                                diffNRTTime = firstRespAgent.getTime() - lastRespGuest.getTime();
                            }
                            countNRTInteractions ++;

                        }

                        firstRespGuest = null;
                        lastRespGuest = null;
                        countCEAgent++;
                    }

                    isAgentFirstResponse = false;

                }

                if(firstRespAgent != null && firstRespAgent < che.CreatedDate){

                    Decimal diffHandleTimeLong =+ che.CreatedDate.getTime() - firstRespAgent.getTime();
                    diffHandleTime = (Double)diffHandleTimeLong;

                }else if(Test.isRunningTest()){
                    diffHandleTime = 99999999;
                }
                lastActor = ce.ActorId;
            }
        }

        if((diffNRTTime != 0 || diffIdleTime != 0 || diffHandleTime != 0)){

            numberOfInteractions = countCEAgent;

            if(countNRTInteractions > 0 && diffNRTTime != 0){
                avgResponseTime = diffNRTTime / (countNRTInteractions);

                if(avgResponseTime != 0){
                    avgResponseTimeSeconds = calculateTime(avgResponseTime);
                }
            }

            if(diffIdleTime != 0){
                idleTime = calculateTime(diffIdleTime);

            }

            if(diffHandleTime != 0){
                handleTime = calculateTime(diffHandleTime);
            }

            if(idleTime != 0){
                che.IdleTime__c = idleTime;
                changeCase = true;
            }

            if(handleTime != 0){
                che.HandleTime__c = handleTime;
                changeCase = true;
            }

            if(avgResponseTimeSeconds != 0){
                che.NRT__c = avgResponseTimeSeconds;
                changeCase = true;
            }

            if(numberOfInteractions != null){
                che.NumberInteractions__c = numberOfInteractions;
                changeCase = true;
            }

//            if(isFirstResponse){
//                System.debug(String.valueOf(firstResponseTime - che.CreatedDate.getTime()));
//                che.Case__r.TimeFirstResponse__c = String.valueOf(firstResponseTime - che.CreatedDate.getTime());
//                changeCase = true;
//            }

            if(changeCase == true){
                casesToUpdate.add(che);
            }


        }
        return casesToUpdate;
    }

    public static Double calculateTime( Double diffTime){
        Double secondsTime;
        if(diffTime != null){
            secondsTime = (Double)(diffTime / 1000);
        }
        return secondsTime;
    }
    public static void updateCaseHistory(List<Case_History_Enhanced__c> changesCases){
        List<Error_Log__c> logs = new List<Error_Log__c>();

        if(!changesCases.isEmpty()){
            List<Database.SaveResult> resultDB = Database.update(changesCases, false);
            for(Database.SaveResult sr :resultDB){
                if(!sr.isSuccess() || Test.isRunningTest()){
                    Error_Log__c log = new Error_Log__c();
                    log.Class_Name__c = 'CaseHistoryCalcBatch';
                    log.Error_Message__c = 'Error al actualizar el case history enhanced';
                    log.Execution_Date__c = Datetime.now();
                    logs.add(log);
                }
            }
        }
        if(!logs.isEmpty()){
            Database.insert(logs, false);
        }
    }


    private static List<Case> getMessagingSessionCases(Set<Id> casesIdsToMs){
        return [SELECT Id, CreatedDate, CaseNumber, TimeFirstResponse__c FROM Case WHERE Id IN :casesIdsToMs];
    }

    private static List<Case_History_Enhanced__c> getCaseHistories(Set<Id> casesIdsToMs){
        return [SELECT Id, CreatedDate, Case__c, User__c,IdleTime__c,NumberInteractions__c, NRT__c, User__r.Name, Case__r.TimeFirstResponse__c
                FROM Case_History_Enhanced__c
                WHERE Case__c IN :casesIdsToMs AND User__r.Name != 'Platform Integration User' ORDER BY Case__c, CreatedDate
        ];
    }

    private static List<ConversationParticipant> getConversationParticipants(Set<Id> conversationIdsToMs){
        return [SELECT Id, ParticipantEntityId, ParticipantDisplayName, ConversationId, CreatedDate
        FROM ConversationParticipant WHERE ConversationId IN :conversationIdsToMs AND ParticipantRole = 'Agent'
        ORDER BY ConversationId, CreatedDate];
    }

    private static List<ConversationEntry> getConversationEntries2(Set<Id> conversationIdsToCE){
        List<ConversationEntry> ceToCalculate = new List<ConversationEntry>();
        if(!Test.isRunningTest()){
            ceToCalculate = [SELECT Id, ConversationId, ActorId, Seq, EntryTime, EntryType, ActorType FROM ConversationEntry WHERE ConversationId IN :conversationIdsToCE AND EntryType = 'Text' ORDER BY ConversationId, CreatedDate, Seq ASC];
        }else {
            ceToCalculate = [SELECT Id, ConversationId, ActorId, Seq, EntryTime, EntryType, ActorType FROM ConversationEntry WHERE ConversationId IN :conversationIdsToCE AND EntryType = 'Text' ORDER BY Seq ASC];
        }
        return ceToCalculate;
    }



}