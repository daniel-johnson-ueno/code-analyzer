/**
 * @description       : 
 * @author            : Noe Vasquez
 * @group             : 
 * @last modified on  : 04-24-2025
 * @last modified by  : Noe Vasquez
**/
trigger UserTrigger on User (before insert, before update, after insert, after update) {
    UserTriggerHandler.handler(
        Trigger.isBefore,
        Trigger.isAfter,
        Trigger.isInsert,
        Trigger.isUpdate,
        Trigger.new,
        Trigger.oldMap
    );
}