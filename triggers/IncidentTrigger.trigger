trigger IncidentTrigger on Incident (before insert, before update, after insert, after update) {
    IncidentTriggerHandler.handle(Trigger.new, Trigger.oldMap);
}