/**
 * @description       : 
 * @group             : 
 * @last modified on  : 05-26-2025
 * @last modified by  : Noe Vasquez
**/
public without sharing class OpportunityTriggerHandler {

    public static Boolean isTriggerActive = true;
    private static final Id RECORDTYPE_ONBOARDING_ID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Onboarding').getRecordTypeId(); 
    private static final Id RECORDTYPE_GENERAL_ID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('General').getRecordTypeId(); 
    private static final Id RECORDTYPE_UPAY_ID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('upay').getRecordTypeId(); 
    public static void handler(Boolean isBefore, Boolean isAfter, Boolean isInsert, Boolean isUpdate,
                              List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        if (!isTriggerActive) return;


        if (isBefore && isInsert) handleBeforeInsert(newList);
        else if (isBefore && isUpdate) handleBeforeUpdate(newList, oldMap);
        else if (isAfter && isInsert) handleAfterInsert(newList);
        else if (isAfter && isUpdate) handleAfterUpdate(newList, oldMap);
    }

    private static void handleBeforeInsert(List<Opportunity> newOpps) {
        // lógica para before insert
        OpportunityTriggerHelper.preventDuplicateOpportunities(newOpps);
        OpportunityTriggerHelper.setPricebookId(newOpps);

    }

    private static void handleBeforeUpdate(List<Opportunity> opps, Map<Id, Opportunity> oldMap) {
        // lógica para before update
        List<Opportunity> oppsWithChangedCurrency = new List<Opportunity>();

            for (Opportunity opp : opps) {
                Opportunity oldOpp = oldMap.get(opp.Id);
                if (opp.CurrencyIsoCode != oldOpp.CurrencyIsoCode) {
                    oppsWithChangedCurrency.add(opp);
                }
            }

            if (!oppsWithChangedCurrency.isEmpty()) {
                OpportunityTriggerHelper.setPricebookId(oppsWithChangedCurrency);
            }
    }


    private static void handleAfterInsert(List<Opportunity> opps) {
        // lógica para after insert
        List<Opportunity> onboardingOppsList = OpportunityTriggerHelper.excludeByRecordType(opps, RECORDTYPE_ONBOARDING_ID);
        OpportunityTriggerHelper.createProductDefaultOnboarding(onboardingOppsList);
        
        List<Opportunity> upayOppsList = OpportunityTriggerHelper.excludeByRecordType(opps, RECORDTYPE_UPAY_ID);
        OpportunityTriggerHelper.createProductDefaultUpay(upayOppsList);

    }
    
	/**
     * @description       : 
     * @group             : 
     * @last modified on  : 06-09-2025
     * @last modified by  : Jessica Gomez
    **/
  public static void handleAfterUpdate(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
      Map<Id, Id> oppIdToNewOwnerId = new Map<Id, Id>();
      for (Opportunity opp : newList) {
          Opportunity oldOpp = oldMap.get(opp.Id);
          if (opp.OwnerId != oldOpp.OwnerId && opp.StageName != 'Exitoso' && opp.StageName != 'No exitoso') {
                  oppIdToNewOwnerId.put(opp.Id, opp.OwnerId);
              }
      }
      
      if (oppIdToNewOwnerId.isEmpty()) return;
      
      List<ActionPlan> relatedActionPlans = [
          SELECT Id, TargetId, OwnerId
          FROM ActionPlan
          WHERE TargetId IN :oppIdToNewOwnerId.keySet()
      ];
      
      if (relatedActionPlans.isEmpty()) return;
      
      List<ActionPlan> updatedActionPlans = new List<ActionPlan>();
      Map<Id, Id> actionPlanIdToNewOwnerId = new Map<Id, Id>();
      Set<Id> actionPlanIds = new Set<Id>();
      
      for (ActionPlan ap : relatedActionPlans) {
          Id newOwnerId = oppIdToNewOwnerId.get(ap.TargetId);
          ap.OwnerId = newOwnerId;
          updatedActionPlans.add(ap);
          actionPlanIdToNewOwnerId.put(ap.Id, newOwnerId);
          actionPlanIds.add(ap.Id);
      }
      
      List<Task> tasksToUpdate = [
          SELECT Id, OwnerId, WhatId
          FROM Task
          WHERE WhatId IN :actionPlanIds
          AND Area__c = 'Comercial'
          AND RecordType.DeveloperName = 'ActionPlanTask'
      ];
      
      List<Task> updatedTasks = new List<Task>();
      for (Task t : tasksToUpdate) {
          Id newOwner = actionPlanIdToNewOwnerId.get(t.WhatId);
          if (newOwner != null) {
              t.OwnerId = newOwner;
              updatedTasks.add(t);
          }
      }
      
      if (!updatedActionPlans.isEmpty()) {
          update updatedActionPlans;
      }
      
      if (!updatedTasks.isEmpty()) {
          update updatedTasks;
      }
  }
}