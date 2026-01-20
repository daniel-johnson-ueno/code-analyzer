/**
 * @description       : 
 * @group             : 
 * @last modified on  : 05-06-2025
 * @last modified by  : Noe Vasquez
**/
trigger OpportunityTrigger on Opportunity (before insert, before update, after insert, after update) {
    OpportunityTriggerHandler.handler(
        Trigger.isBefore,
        Trigger.isAfter,
        Trigger.isInsert,
        Trigger.isUpdate,
        Trigger.new,
        Trigger.oldMap
    );
}