trigger TaskTrigger on Task (after insert, after update) {
    TaskTriggerHandler handler = new TaskTriggerHandler();

    if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            for (Task oldTask : Trigger.old) {
                for (Task newTask : Trigger.new) {
                    if (oldTask.Status != newTask.Status) {
                        if (newTask.Status == 'Completed') {
                            handler.handleUpdateSkillsByTraining(Trigger.new);
                        }
                        if (newTask.Status == 'Open' || newTask.Status == 'Devuelto' || newTask.Status == 'Aprobado'){
                            handler.setStartDate(Trigger.new); 
                            
                        }
                    }
                }
            }
            handler.calculateTaskTime(Trigger.new);
        } else if (Trigger.isInsert) {
            handler.handleUpdateSkillsByTraining(Trigger.new);
            handler.setStartDate(Trigger.new); 
            handler.calculateTaskTime(Trigger.new);
        }
    }
}