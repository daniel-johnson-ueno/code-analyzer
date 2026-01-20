@isTest
public class LeadTriggerHandlerTest {
    private static final Id RECORDTYPE_UELA_ID = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('uela').getRecordTypeId(); 

    @testSetup
    static void setupData() {

        Group queue;
        List<Group> existingQueues = [
            SELECT Id FROM Group WHERE DeveloperName = 'Ejecutivos_uela' LIMIT 1
        ];
        
        if (!existingQueues.isEmpty()) {
            queue = existingQueues[0];
        } else {
            queue = (Group)TestFactoryFramework.createSObject(new Group());
            queue.Name = 'Ejecutivos_uela';
            queue.DeveloperName = 'Ejecutivos_uela';
            queue.Type = 'Queue';
            insert queue;
        }

    }
    
    @isTest
    static void testInsertLeadTriggerHandler() {
        Group queue = [ SELECT Id FROM Group WHERE DeveloperName = 'Ejecutivos_uela' LIMIT 1];
        Lead lead = (Lead)TestFactoryFramework.createSObject(new Lead());
        lead.FirstName = 'Test';
        lead.LastName = 'Insert';
        lead.Company = 'Test Company';
        lead.Status = 'New';
        lead.recordtypeId =RECORDTYPE_UELA_ID;
        lead.OwnerId = queue.Id;

        Test.startTest();
        insert lead;
        Test.stopTest();

        // Verifica que el lead cambió de dueño
        Lead updatedLead = [SELECT Id, OwnerId FROM Lead WHERE Id = :lead.Id];
        Assert.areNotEqual(queue.Id, updatedLead.OwnerId, 'El Lead debería haber sido reasignado por round robin');
    }

   
    
}