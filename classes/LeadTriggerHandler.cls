public class LeadTriggerHandler {
    private static final Id RECORDTYPE_UELA_ID = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('uela').getRecordTypeId(); 
    
    public static void handle(
        Boolean isBefore,
        Boolean isAfter,
        Boolean isInsert,
        Boolean isUpdate,
        List<Lead> newList,
        Map<Id, Lead> oldMap
    ) {
        List<Lead> leadsToAssign = new List<Lead>();
        Boolean shouldQueryQueue = false;

        if ((isAfter && isInsert) || (isAfter && isUpdate)) {
            for (Lead ld : newList) {
                if (ld.RecordTypeId == RECORDTYPE_UELA_ID) {
                    if (isInsert && ld.OwnerId != null) {
                        shouldQueryQueue = true;
                    } else if (isUpdate && oldMap != null) {
                        Lead oldLead = oldMap.get(ld.Id);
                        if (oldLead != null && ld.OwnerId != oldLead.OwnerId) {
                            shouldQueryQueue = true;
                        }
                    }
                }
            }
        }

        Id queueId;
        if (shouldQueryQueue) {
            Group queue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Ejecutivos_uela' LIMIT 1];
            queueId = queue.Id;

            for (Lead ld : newList) {
                if (ld.RecordTypeId == RECORDTYPE_UELA_ID) {
                    if (isInsert && ld.OwnerId == queueId) {
                        leadsToAssign.add(ld);
                    } else if (isUpdate) {
                        Lead oldLead = oldMap.get(ld.Id);
                        if (ld.OwnerId != oldLead.OwnerId && ld.OwnerId == queueId) {
                            leadsToAssign.add(ld);
                        }
                    }
                }
            }
        }

        if (!leadsToAssign.isEmpty()) {
            LeadRoundRobinAssignment.assignLeadRoundRobin(leadsToAssign);
        }
    }
}