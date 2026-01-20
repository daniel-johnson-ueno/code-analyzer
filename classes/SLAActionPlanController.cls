public with sharing class SLAActionPlanController {
    public class ActionPlanSLAInfo {
        @AuraEnabled public String name;
        @AuraEnabled public DateTime createdDate;
        @AuraEnabled public Long elapsedSeconds;  
        @AuraEnabled public Long slaSeconds;    
        @AuraEnabled public Integer slaDays;    
        @AuraEnabled public Boolean isExpired;
    }

    public class OpportunitySLAInfo {
        @AuraEnabled public Long elapsedSeconds;
        @AuraEnabled public Long slaSeconds;
        @AuraEnabled public Boolean isExpired;
    }

    @AuraEnabled(cacheable=true)
    public static List<ActionPlanSLAInfo> getActionPlansWithSLA(Id opportunityId) {
        Opportunity opp = [
            SELECT Id, RecordType.Name, CompanyType__c,
                   (SELECT Id, Name, CreatedDate FROM ActionPlans ORDER BY CreatedDate ASC)
            FROM Opportunity
            WHERE Id = :opportunityId
        ];

        if (opp.RecordType.Name != 'Onboarding') {
            return new List<ActionPlanSLAInfo>();
        }

        Integer slaDays; 
        if (new List<String>{'EAS', 'SRL', 'SA', 'otros'}.contains(opp.CompanyType__c)) {
            slaDays = 8; 
        } else if (opp.CompanyType__c == 'Unipersonal') {
            slaDays = 4; 
        } else {
            slaDays = 0;
        }

        List<ActionPlanSLAInfo> result = new List<ActionPlanSLAInfo>();
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE LIMIT 1];

        for (ActionPlan ap : opp.ActionPlans) {
            Long millis = BusinessHours.diff(bh.Id, ap.CreatedDate, DateTime.now());
            Long elapsedSeconds = (millis != null) ? millis / 1000 : 0;
            Long slaSeconds = getSLASeconds(ap.CreatedDate, slaDays, bh.Id);

            ActionPlanSLAInfo info = new ActionPlanSLAInfo();
            info.name = ap.Name;
            info.createdDate = ap.CreatedDate;
            info.elapsedSeconds = elapsedSeconds;
            info.slaSeconds = slaSeconds;
            info.slaDays = slaDays;
            info.isExpired = elapsedSeconds > slaSeconds;

            result.add(info);
        }

        return result;
    }

    @AuraEnabled(cacheable=true)
    public static OpportunitySLAInfo getOpportunitySLA(Id opportunityId) {
        List<OpportunityFieldHistory> histories = [
            SELECT OldValue, NewValue, CreatedDate, Field
            FROM OpportunityFieldHistory
            WHERE OpportunityId = :opportunityId
            ORDER BY CreatedDate ASC
        ];

        DateTime assignedDate;
        DateTime nextStageDate;

        for (Integer i = 0; i < histories.size(); i++) {
            OpportunityFieldHistory h = histories[i];
            if ((String.valueOf(h.NewValue) == 'Asignación' && String.valueOf(h.Field) == 'StageName') || String.valueOf(h.Field) == 'opportunityCreatedFromLead'|| String.valueOf(h.Field) == 'created' ) {
                assignedDate = h.CreatedDate;

                for (Integer j = i + 1; j < histories.size(); j++) {
                    OpportunityFieldHistory next = histories[j];
                    if (String.valueOf(next.OldValue) == 'Asignación') {
                        nextStageDate = next.CreatedDate;
                        break;
                    }
                }
                break;
            }
        }

        OpportunitySLAInfo info = new OpportunitySLAInfo();
        if (assignedDate != null) {
            DateTime endDate = (nextStageDate != null) ? nextStageDate : DateTime.now();
            Long diffMillis = endDate.getTime() - assignedDate.getTime();
            Long elapsedSeconds = diffMillis / 1000;
            Long slaSeconds = 2 * 24 * 60 * 60;

            info.elapsedSeconds = elapsedSeconds;
            info.slaSeconds = slaSeconds;
            info.isExpired = elapsedSeconds > slaSeconds;
        } else {
            info.elapsedSeconds = 0;
            info.slaSeconds = 2 * 24 * 60 * 60;
            info.isExpired = false;
        }

        return info;
    }

    /**-----------------------------------------------------------------------------------------------
    * @description Método para obtener el SLA en segundos y teniendo en cuenta el horario de oficina
    * @param DateTime startDate: fecha de inicio del SLA
    * @param Integer intSLAdays: SLA en dias
    * @param String businessHoursId: Id del business hours
    * @return Long: Tiempo del SLA en segundos teniendo en cuenta el horario de oficina 
    -----------------------------------------------------------------------------------------------**/
    public static Long getSLASeconds(DateTime startDate, Integer intSLAdays, String businessHoursId){
        if(startDate == null || intSLAdays <= 0 || String.isBlank(businessHoursId)){
            return 0;
        }

        DateTime endDate = startDate;
        for(Integer i = 0; i < intSLAdays; i++){
            if(BusinessHours.isWithin(businessHoursId, endDate)){
                endDate = endDate.addDays(1);
                endDate = BusinessHours.isWithin(businessHoursId, endDate) ? endDate : BusinessHours.nextStartDate(businessHoursId, endDate);
            }
            else{
                endDate = BusinessHours.nextStartDate(businessHoursId, endDate);
            }
        }
        endDate = DateTime.newInstance(endDate.date(), startDate.time());
        Long millis = BusinessHours.diff(businessHoursId, startDate, endDate);
        return (millis != null) ? millis / 1000 : 0;
    }
}