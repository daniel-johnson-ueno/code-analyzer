@isTest
public class ActionPlanTriggerHandlerTest {
    @testSetup
    static void setup() {
        Opportunity opp = (Opportunity)TestFactoryFramework.createSObject(new Opportunity());
        opp.StageName = 'Asignación';
        opp.CloseDate = Date.today().addDays(30);
        opp.CompanyType__c = 'EAS';
        insert opp;
        
        Date dateNow =  DateTime.now().date();
        ActionPlan ap = (ActionPlan)TestFactoryFramework.createSObject(new ActionPlan());
        ap.name ='Test Action Plan'; 
        ap.TargetId = opp.Id; 
       	ap.ActionPlanState = 'Nuevo';
        ap.ActionPlanType = 'Industries';
		ap.ActionPlanTemplateVersionId = '0PTVv00000007MTOAY'; 
        ap.StartDate = dateNow; 
        insert ap;
    }
    
    @isTest
    static void testInsertActionPlan() {
        Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE CompanyType__c= 'EAS'];
        Date dateNow =  DateTime.now().date();
        Test.startTest();
        ActionPlan insertedAp = [SELECT StartDateTime__c FROM ActionPlan LIMIT 1];
        Test.stopTest();
        System.assertNotEquals(null, insertedAp.StartDateTime__c, 'El campo StartDateTime__c no debería ser nulo después de la inserción');
    }
    
    @isTest
    static void testUpdateActionPlan() {
        ActionPlan existingAp = [SELECT Id, ActionPlanState FROM ActionPlan LIMIT 1];
        Test.startTest();
        existingAp.ActionPlanState = 'En progreso';
        update existingAp;
        Test.stopTest();
        ActionPlan updatedAp = [SELECT Time_in_Hours__c, Time_in_Days__c FROM ActionPlan WHERE Id = :existingAp.Id];
        System.assertNotEquals(null, updatedAp.Time_in_Hours__c, 'El campo Time_in_Hours__c no debería ser nulo después de la actualización');
        System.assertNotEquals(null, updatedAp.Time_in_Days__c, 'El campo Time_in_Days__c no debería ser nulo después de la actualización');
    }
}