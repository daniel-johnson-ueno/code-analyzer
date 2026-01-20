/**
 * @description       : Trigger de Lead para asignación Round Robin desde la cola Comercial_Uela
 * @group             : UELA
 * @last modified on  : 13-06-2025
 * @last modified by  : Jessica Gomez
**/
trigger LeadTrigger on Lead (before insert, before update, after insert, after update) {
    LeadTriggerHandler.handle(
        Trigger.isBefore,
        Trigger.isAfter,
        Trigger.isInsert,
        Trigger.isUpdate,
        Trigger.new,
        Trigger.oldMap
    );
}