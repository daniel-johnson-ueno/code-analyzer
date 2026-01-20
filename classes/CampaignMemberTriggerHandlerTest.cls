@isTest
public class CampaignMemberTriggerHandlerTest {

    @testSetup
    static void setupData() {
        Campaign camp = (Campaign) TestFactoryFramework.createSObject(new Campaign());
        camp.Name = 'Test Campaign';
        camp.IsActive = true;
        insert camp;

       	Contact con = (Contact) TestFactoryFramework.createSObject(new Contact());
        con.LastName = 'Test';
        insert con;

        CampaignMember cm = (CampaignMember) TestFactoryFramework.createSObject(new CampaignMember());
        cm.CampaignId = camp.Id; 
        cm.ContactId = con.Id;
        cm.Status = 'Planned';
        insert cm;
    }

    @isTest
    static void testDeleteAsSystemAdmin() {
        List<CampaignMember> cms = [SELECT Id FROM CampaignMember LIMIT 1];

        Test.startTest();
        try {
            delete cms; 
        } catch (Exception e) {
            System.assert(false, 'No debería lanzar excepción para System Admin: ' + e.getMessage());
        }
        Test.stopTest();
    }
}