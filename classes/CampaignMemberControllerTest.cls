/**
 * @description       : 
 * @author            : Noe Vasquez
 * @group             : 
 * @last modified on  : 06-10-2025
 * @last modified by  : Noe Vasquez
**/
@isTest
public class CampaignMemberControllerTest {

    @testSetup
    static void setupData() {
        // Get PermissionSet
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'ByPass_Flow' LIMIT 1];
        
        // Setup user operations in one context
        Profile profileAdmin = [SELECT Id FROM Profile WHERE Name IN ('Administrador del sistema', 'System Administrator') LIMIT 1];
        Profile profileComercial = [SELECT Id FROM Profile WHERE Name = 'Gerente operativo' LIMIT 1];
        Profile profileGerenteUenoX = [SELECT Id FROM Profile WHERE Name = 'Gerente UENO X' LIMIT 1];

        User mainUser = new User(Id = UserInfo.getUserId());
        
        // Check and assign permission set in a separate context
        System.runAs(new User(Id = UserInfo.getUserId())) {
            List<PermissionSetAssignment> existingMainAssignments = [
                SELECT Id FROM PermissionSetAssignment 
                WHERE AssigneeId = :mainUser.Id AND PermissionSetId = :ps.Id
                LIMIT 1
            ];

            if(existingMainAssignments.isEmpty()) {
                PermissionSetAssignment mainPermission = new PermissionSetAssignment(
                    AssigneeId = mainUser.Id,
                    PermissionSetId = ps.Id
                );
                mainPermission = (PermissionSetAssignment)TestFactoryFramework.createSObject(mainPermission, true);
            }
        }
        
        // Create commercial user in separate context
        User userComercial;
        User userComercialUenoX;
        System.runAs(mainUser) {
            userComercial = new User(
                Username = 'test_comercial@example.com',
                Alias = 'tst_com',
                Email = 'test_comercial@example.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Test',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = profileComercial.Id,
                TimeZoneSidKey = 'America/Los_Angeles'
            );
            userComercial = (User)TestFactoryFramework.createSObject(userComercial, true);
            userComercialUenoX = new User(
                Username = 'test_comercialUenoX@example.com',
                Alias = 'unenoX_c',
                Email = 'test_comercialUenoX@example.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Test',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = profileGerenteUenoX.Id,
                TimeZoneSidKey = 'America/Los_Angeles'
            );
            userComercialUenoX = (User)TestFactoryFramework.createSObject(userComercialUenoX, true);
        }
        
        // Now create non-setup objects in main context
        Contact contact = new Contact(FirstName = 'Nuevo', LastName = 'Ejecutivo');
        contact = (Contact)TestFactoryFramework.createSObject(contact, true);

        Contact contact2 = new Contact(FirstName = 'Otro', LastName = 'Ejecutivo');
        contact2 = (Contact)TestFactoryFramework.createSObject(contact2, true);

        

        Campaign campaign = new Campaign(Name = 'Test Campaign', IsActive = true);
        campaign = (Campaign)TestFactoryFramework.createSObject(campaign, true);

        CampaignMember cm = new CampaignMember(
            CampaignId = campaign.Id,
            ContactId = contact.Id,
            Status = 'Convertido',
            AssignedExecutive__c = userComercial.Id
        );
        cm = (CampaignMember)TestFactoryFramework.createSObject(cm, true);

        CampaignMember cm2 = new CampaignMember(
            CampaignId = campaign.Id,
            ContactId = contact2.Id,
            Status = 'No interesado',
            AssignedExecutive__c = userComercial.Id
        );
        cm2 = (CampaignMember)TestFactoryFramework.createSObject(cm2, true);


    
    }

    @isTest
    static void testGetFilteredMembers() {
        Test.startTest();
        CampaignMemberController.getFilteredMembers('AsignadosAmi');
        CampaignMemberController.getFilteredMembers('Convertidos');
        CampaignMemberController.getFilteredMembers('No Interesados');
        CampaignMemberController.getFilteredMembers('Pendientes');
        CampaignMemberController.getFilteredMembers('Todos los Pendientes');
        Test.stopTest();
    }

    @isTest
    static void testSearchCampaignMembersByName() {
        Test.startTest();
        CampaignMemberController.searchCampaignMembersByName('Ejecutivo', 'AsignadosAmi');
        CampaignMemberController.searchCampaignMembersByName('Ejecutivo', 'Convertidos');
        CampaignMemberController.searchCampaignMembersByName('Ejecutivo', 'No Interesados');
        CampaignMemberController.searchCampaignMembersByName('Ejecutivo', 'Pendientes');
        CampaignMemberController.searchCampaignMembersByName('Ejecutivo', 'Todos los Pendientes');
        Test.stopTest();
    }


    @isTest
    static void testGetMetadataProfiles() {
        Test.startTest();
        List<Manager_CampaignMembers__mdt> profiles = CampaignMemberController.getMetadataProfiles();
        System.assert(!profiles.isEmpty(), 'Debe devolver al menos un perfil');
        Test.stopTest();
    }

    @isTest
    static void testHasPermissionSet() {

        Test.startTest();
        List<PermissionSetAssignment>  result = CampaignMemberController.getUserPermissionsSet();
        Test.stopTest();
    }

    @isTest
    static void testUpdateCampaignMembers() {
        CampaignMember member = [SELECT Id FROM CampaignMember LIMIT 1];
        User newEjecutivo = [SELECT Id FROM User WHERE Email = 'test_comercialUenoX@example.com' LIMIT 1];

        Test.startTest();
        CampaignMemberController.updateCampaignMembers(
            new List<Id>{member.Id},
            newEjecutivo.Id
        );
        Test.stopTest();

        List<CampaignMember> updated = [SELECT AssignedExecutive__c FROM CampaignMember WHERE Id =: member.Id];
        for (CampaignMember cm : updated) {
            System.assertEquals(newEjecutivo.Id, cm.AssignedExecutive__c);
        }
    }
}