public class LeadRoundRobinAssignment {

    private static final String QUEUE_NAME = 'Ejecutivos_uela';

    public static void assignLeadRoundRobin(List<Lead> leads) {
        if (leads == null || leads.isEmpty()) return;
        Group queue = [
            SELECT Id 
            FROM Group 
            WHERE Type = 'Queue' AND DeveloperName = :QUEUE_NAME 
            LIMIT 1
        ];

        Set<Id> visitedGroups = new Set<Id>();
        List<Id> userIds = getAllUserIdsInGroup(queue.Id, visitedGroups);

        if (userIds.isEmpty()) {
            System.debug('No hay usuarios válidos en la cola.');
            return;
        }

        RoundRobinSetting__c setting = RoundRobinSetting__c.getOrgDefaults();
        Id lastUserId = setting != null ? setting.LastUserId__c : null;

        Integer lastIndex = -1;
        if (lastUserId != null) {
            lastIndex = userIds.indexOf(lastUserId);
        }

        Integer totalUsers = userIds.size();
        Integer currentIndex = lastIndex;

        List<Lead> leadsToUpdate = new List<Lead>();

        for (Lead ld : leads) {
            if (currentIndex + 1 >= totalUsers) {
                currentIndex = 0;
            } else {
                currentIndex += 1;
            }

            Lead updatedLead = new Lead(Id = ld.Id);
            updatedLead.OwnerId = userIds[currentIndex];
            leadsToUpdate.add(updatedLead);
        }

        try {
            update leadsToUpdate;
        } catch (DmlException e) {
            System.debug('Error actualizando leads: ' + e.getMessage());
        }

        if (setting == null) {
            setting = new RoundRobinSetting__c();
        }

        setting.LastUserId__c = userIds[currentIndex];

        try {
            upsert setting;
        } catch (DmlException e) {
            System.debug('Error actualizando Custom Setting: ' + e.getMessage());
        }
    }

    private static List<Id> getAllUserIdsInGroup(Id groupId, Set<Id> visitedGroups) {
        List<Id> userIds = new List<Id>();
        if (visitedGroups.contains(groupId)) return userIds; // evitar ciclos
        visitedGroups.add(groupId);

        List<GroupMember> members = [
            SELECT UserOrGroupId 
            FROM GroupMember 
            WHERE GroupId = :groupId
        ];

        for (GroupMember gm : members) {
            String idPrefix = String.valueOf(gm.UserOrGroupId).substring(0, 3);
            if (idPrefix == '005') {
                userIds.add(gm.UserOrGroupId); 
            } else if (idPrefix == '00G') {
                userIds.addAll(getAllUserIdsInGroup(gm.UserOrGroupId, visitedGroups));
            }
        }

        return userIds;
    }
}