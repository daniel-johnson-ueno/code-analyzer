public with sharing class ServicePresenceDAO {
    
    public static Map<String, List<Object>> getServicePresence(Date searchDate, String channel) {

        DateTime startOfDay = DateTime.newInstance(searchDate, Time.newInstance(0, 0, 0, 0));
        DateTime endOfDay = DateTime.newInstance(searchDate, Time.newInstance(23, 59, 59, 999));

        Map<String, List<Object>> resultMap = new Map<String, List<Object>>();

        List<Id> userIdsFromChannel = retrieveUsersFromChannel(channel);

        List<UserServicePresence> userServicePresences = retrieveUserServicePresences(startOfDay, endOfDay, userIdsFromChannel);

        Set<Id> userIds = new Set<Id>();
        for (UserServicePresence usp : userServicePresences) {
            userIds.add(usp.UserId);
        }

        Map<Id, String> userToContactNameMap = new Map<Id, String>();
        if (!userIds.isEmpty()) {
            for (Contact contact : [
                SELECT Id, Name, UserId__c
                FROM Contact 
                WHERE UserId__c IN :userIds
            ]) {
                if (contact != null) {
                    userToContactNameMap.put(contact.UserId__c, contact.Name);
                }
            }
        }

        List<Shift_Block__c> shiftBlocks = retrieveShiftBlocks(startOfDay, endOfDay, userIdsFromChannel);

        for (UserServicePresence usp : userServicePresences) {
            String contactName = userToContactNameMap.containsKey(usp.UserId) ? userToContactNameMap.get(usp.UserId) : 'Unknown';
            if (!resultMap.containsKey(contactName)) {
                resultMap.put(contactName, new List<Object>());
            }
            resultMap.get(contactName).add(usp);
        }

        for (Shift_Block__c shiftBlock : shiftBlocks) {
            String contactName = shiftBlock.Shift__r.Agent__r.Name;
            if (!resultMap.containsKey(contactName)) {
                resultMap.put(contactName, new List<Object>());
            }
            resultMap.get(contactName).add(shiftBlock);
        }

        return resultMap;
    }

    private static List<Id> retrieveUsersFromChannel(String channel) {
        List<Contact> contacts = [SELECT UserId__c 
                FROM Contact 
                WHERE Channel__c = :channel];

        List<Id> userIds = new List<Id>();
        for (Contact cnt : contacts) {
            userIds.add(cnt.UserId__c);
        }
        return userIds;
    }

    private static List<UserServicePresence> retrieveUserServicePresences(Datetime startOfDay, Datetime endOfDay, List<Id> userIds) {
        return [
            SELECT UserId, 
                    ServicePresenceStatus.MasterLabel, 
                    StatusStartDate, 
                    StatusEndDate, 
                    Idle_Time__c
            FROM UserServicePresence
            WHERE StatusStartDate >=: startOfDay 
                AND StatusEndDate <=: endOfDay
                AND UserId IN :userIds
        ];
    }

    private static List<Shift_Block__c> retrieveShiftBlocks(Datetime startOfDay, Datetime endOfDay, List<Id> userIds) {
        return [
            SELECT Start__c, 
                    End__c, 
                    Type__c, 
                    Shift__c,
                    Shift__r.Agent__r.Name
            FROM Shift_Block__c
            WHERE Start__c >=: startOfDay 
                AND End__c <=: endOfDay
                AND Shift__r.Agent__r.UserId__c IN :userIds
        ];
    }
}