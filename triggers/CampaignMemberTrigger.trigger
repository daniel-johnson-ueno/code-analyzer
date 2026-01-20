trigger CampaignMemberTrigger on CampaignMember (before delete) {
    if (Trigger.isBefore && Trigger.isDelete) {
        CampaignMemberTriggerHandler.handleBeforeDelete(Trigger.old);
    }
}