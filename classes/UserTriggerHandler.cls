/**
 * @description       : 
 * @author            : Noe Vasquez
 * @group             : 
 * @last modified on  : 04-25-2025
 * @last modified by  : Noe Vasquez
**/
public class UserTriggerHandler {
    public static Boolean isTriggerActive = true;

    public static void handler(Boolean isBefore, Boolean isAfter, Boolean isInsert, Boolean isUpdate,
                              List<User> newList, Map<Id, User> oldMap) {
        if (!isTriggerActive) return;


        if (isBefore && isInsert) handleBeforeInsert(newList);
        else if (isBefore && isUpdate) handleBeforeUpdate(newList, oldMap);
        else if (isAfter && isInsert) handleAfterInsert(newList);
        else if (isAfter && isUpdate) handleAfterUpdate(newList, oldMap);
    }

    private static void handleBeforeInsert(List<User> users) {
        // lógica para before insert
    }

    private static void handleBeforeUpdate(List<User> users, Map<Id, User> oldMap) {
        // lógica para before update

    }

    private static void handleAfterInsert(List<User> users) {
        // lógica para after insert

    }

    private static void handleAfterUpdate(List<User> newUsers, Map<Id, User> oldUserMap) {
        // lógica para after update
        Set<Id> deactivatedUserIds = new Set<Id>();
        for (User u : newUsers) {
            User oldUser = oldUserMap.get(u.Id);
            if (oldUser.IsActive && !u.IsActive) {
                deactivatedUserIds.add(u.Id);
            }
        }
        if (!deactivatedUserIds.isEmpty()) {
            UserDeactivationHandler.processDeactivatedUsers(deactivatedUserIds);
        }
        
        
    }


}