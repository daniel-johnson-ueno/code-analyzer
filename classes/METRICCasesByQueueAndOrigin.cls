global class METRICCasesByQueueAndOrigin implements Schedulable{
    private static final String METRIC_NAME = 'salesforce.case.service.queueActivity.count';
    private static final String METRIC_TYPE = 'count';
    private static final String METRIC_ATTRIBUTE_HAS_PEOPLE = 'hasPeople';
    private static final String METRIC_ATTRIBUTE_ORIGIN = 'origin';
    private static final String METRIC_ATTRIBUTE_QUEUE = 'queue';
    private static final String METRIC_ATTRIBUTE_HAS_OMNI = 'hasOmni';
    
    List<GroupMember> groupMembers;
    List<Group> queues;
    List<Group> publicGroups;
    List<User> activeUsers;
    Long timestamp;
    Long intervalMs;
    List<String> emptyQueues = new List<String>();
    Set<String> groupsSet = new Set<String>();
    Set<String> queuesNamesWithPersons = new Set<String>();
    Set<String> publicGroupsWithPersons = new Set<String>();
    List<AggregateResult> casesGroupedByQueueAndOrigin;
    
    global void execute(SchedulableContext sc) {
        DateTime now = DateTime.now();
        timestamp = now.getTime() / 1000;
        intervalMs = 15 * 60 * 1000;
        getInitialData();
        queuesWithPublicGroups();
        processQueuesWithPersons();
        List<NewRelicMetricsSender.MetricsWrapper> payload = finalValues();
        if (!payload.isEmpty()) {
            NewRelicMetricsSender.sendMetricsToNewRelic(payload);
        }
    }

    private void getInitialData(){
        getGroupMembers();
        retrieveCases();
        getPublicGroups();
        getQueues();
        getActiveUsers();
    }

    private void getPublicGroups(){
        this.publicGroups =[SELECT Id FROM Group where Type = 'Regular'];
    }

    private void getGroupMembers() {
        this.groupMembers = [SELECT FIELDS(STANDARD) FROM GroupMember];
    }
    
    private void retrieveCases() {
        this.casesGroupedByQueueAndOrigin = [SELECT Count(Id) cant, OwnerId, Origin FROM Case WHERE Status != 'Cerrado' and Owner.Type = 'Queue' group by OwnerId, Origin ];
    }

    private void getQueues(){
        this.queues = [SELECT QueueRoutingConfigId,Id,Name,DeveloperName FROM Group WHERE Group.Type = 'QUEUE'];
    }

    private void getActiveUsers(){
        this.activeUsers = [SELECT Id FROM User where IsActive = true];
    }
    
    
    void queuesWithPublicGroups(){
        for(GroupMember gm: groupMembers){
            for(Group publicG : publicGroups){
                if(publicG.Id == gm.GroupId){
                    publicGroupsWithPersons.add(publicG.id);
                    break;
                }
                queuesNamesWithPersons.add(gm.GroupId);
            }
        }
    }
    
    
    void processQueuesWithPersons(){
        for(GroupMember gm: groupMembers){
            if(publicGroupsWithPersons.contains(gm.UserOrGroupId)){
                queuesNamesWithPersons.add(gm.GroupId);
            }
        }
    }
    
    List<NewRelicMetricsSender.MetricsWrapper> finalValues(){
        NewRelicMetricsSender.MetricsWrapperBuilder builder = new NewRelicMetricsSender.MetricsWrapperBuilder();
        for(Group queue : queues){
            Boolean hasPeople =  true;
            Boolean hasOmni = false;
            if(!queuesNamesWithPersons.contains(queue.Id)){
                emptyQueues.add(queue.Name.toString());
                hasPeople = false;
            }
            if(queue.QueueRoutingConfigId!=null){
                hasOmni = true;
            }
            for(AggregateResult result : casesGroupedByQueueAndOrigin){
                Integer count = (Integer)result.get('cant');
                String origin = (String)result.get('Origin');
                String queueName = queue.DeveloperName;
                if(result.get('OwnerId') == queue.Id){
                    builder.addMetric(
                        METRIC_NAME,
                        METRIC_TYPE,
                        count,
                        timestamp,
                        intervalMs,
                        new Map<String, Object>{
                            METRIC_ATTRIBUTE_QUEUE => queueName,
                            METRIC_ATTRIBUTE_ORIGIN => origin,
                            METRIC_ATTRIBUTE_HAS_PEOPLE => hasPeople,
                            METRIC_ATTRIBUTE_HAS_OMNI=> hasOmni
                        }
                    );
                }
            }
        }
        return builder.build();
    }
    
}