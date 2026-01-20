trigger ActionPlanTrigger on ActionPlan (after insert, after update) {
    ActionPlanTriggerHandler handler = new ActionPlanTriggerHandler();

    if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
			ActionPlanTriggerHandler.setStartDate(Trigger.new); 
            ActionPlanTriggerHandler.calculateTaskTime(Trigger.new);
        } else if (Trigger.isInsert) {
            ActionPlanTriggerHandler.setStartDate(Trigger.new); 
            ActionPlanTriggerHandler.calculateTaskTime(Trigger.new);
        }
    }
}