/**
 * @description       : 
 * @author            : Noe Vasquez
 * @group             : 
 * @last modified on  : 07-01-2025
 * @last modified by  : Noe Vasquez
**/
@isTest
private class UserTriggerHandlerTest {

    @testSetup
    static void setupTestData() {

        // 1. Obtener los Permission Sets necesarios
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'ByPass_Flow' LIMIT 1];

    
        // Crear usuarios en contexto sin flujos
        Profile profileAdmin = [SELECT Id FROM Profile WHERE Name IN ('Administrador del sistema', 'System Administrator') LIMIT 1];
        Profile profileGerente = [SELECT Id FROM Profile WHERE Name = 'Gerente operativo' LIMIT 1];

        User adminUser, user1, userGerente;
        
        
        User mainUser = new User(Id = UserInfo.getUserId());


        PermissionSetAssignment mainPermission =  new PermissionSetAssignment(
            AssigneeId = mainUser.Id,
            PermissionSetId = ps.Id
        );
        mainPermission = (PermissionSetAssignment)TestFactoryFramework.createSObject(mainPermission, true);

        System.runAs(mainUser) {
            adminUser = new User(
                LastName = 'Admin', Email = 'adminabc@test.com', Username = 'adminabc@test.com', 
                Alias = 'admin', TimeZoneSidKey = 'America/New_York', LocaleSidKey = 'en_US', 
                EmailEncodingKey = 'UTF-8', ProfileId = profileAdmin.Id, LanguageLocaleKey = 'en_US'
            );
            user1 = new User(
                LastName = 'User1', Email = 'user_abc@test.com', Username = 'user_abc@test.com', 
                Alias = 'u1', TimeZoneSidKey = 'America/New_York', LocaleSidKey = 'en_US', 
                EmailEncodingKey = 'UTF-8', ProfileId = profileGerente.Id, LanguageLocaleKey = 'en_US'
            );
            userGerente = new User(
                LastName = 'Gerente de sucursal', Email = 'gerente@example.com', Username = 'gerente@example.com', 
                Alias = 'u1', TimeZoneSidKey = 'America/New_York', LocaleSidKey = 'en_US', 
                EmailEncodingKey = 'UTF-8', ProfileId = profileGerente.Id, LanguageLocaleKey = 'en_US'
            );
             user1 = (User)TestFactoryFramework.createSObject(user1, true);
             adminUser = (User)TestFactoryFramework.createSObject(adminUser, true);
             userGerente = (User)TestFactoryFramework.createSObject(userGerente, true);

            Account internalAcc = new Account(Name = 'Internal_Company', RecordTypeId = getRecordTypeId('Account', 'Internal_Company'));
            internalAcc = (Account)TestFactoryFramework.createSObject(internalAcc, 'TestFactoryFrameworkDefaults.InternalCompanyAccountDefaults', true);

            Contact gerenteContact = new Contact(
                LastName = 'Gerente',
                Email = userGerente.Email,
                AccountId = internalAcc.Id,
                RecordTypeId = getRecordTypeId('Contact', 'Internal_Contact'),
                User__c = userGerente.Id
            );
            gerenteContact = (Contact)TestFactoryFramework.createSObject(gerenteContact, true);
            
            internalAcc.Manager_UenoX__c = gerenteContact.Id;
            update internalAcc;

            Account secondaryOffice = new Account(Name = 'Test Account', Manager_UenoX__c = gerenteContact.Id);
            secondaryOffice = (Account)TestFactoryFramework.createSObject(secondaryOffice, true);

            Contact contactoEjecutivo = new Contact(
                LastName = 'Test Contact',
                Email = user1.Email,
                AccountId = internalAcc.Id,
                RecordTypeId = getRecordTypeId('Contact', 'Internal_Contact'),
                User__c = user1.Id,
                SecondaryOffice__c = secondaryOffice.Id
            );
            contactoEjecutivo = (Contact)TestFactoryFramework.createSObject(contactoEjecutivo, true);

            Opportunity opp = new Opportunity(
                Name = 'Oportunidad 1',
                StageName = 'Nuevo',
                CloseDate = Date.today().addDays(10),
                OwnerId = user1.Id,
                RecordTypeId = getRecordTypeId('Opportunity', 'General')
            );
            opp = (Opportunity)TestFactoryFramework.createSObject(opp, true);

            Lead lead = new Lead(
                LastName = 'Lead Test',
                Company = 'Empresa X',
                OwnerId = user1.Id,
                Status = 'Asignado',
                Preference_Experience_Center__c = internalAcc.Id,
                Revenue__c = '<250M'
            );
            lead = (Lead)TestFactoryFramework.createSObject(lead, true);
    
        }

    }

    @isTest
    static void testHandleAfterUpdate_UserDeactivation() {
        // Recuperar usuario original
        User userToDeactivate = [SELECT Id, IsActive FROM User WHERE Email = 'user_abc@test.com' LIMIT 1];

        // Desactivar usuario
        userToDeactivate.IsActive = false;

        Test.startTest();
        update userToDeactivate;
        Test.stopTest();

        // Verificar que la oportunidad y lead fueron reasignados al gerente
        Id gerenteId = [SELECT Id FROM User WHERE Email = 'gerente@example.com' LIMIT 1].Id;

        for (Opportunity opp : [SELECT Id, OwnerId FROM Opportunity WHERE Name = 'Oportunidad 1']) {
            System.assertEquals(gerenteId, opp.OwnerId, 'El Owner de la oportunidad debe ser el gerente');
        }

        for (Lead lead : [SELECT Id, OwnerId FROM Lead WHERE LastName = 'Lead Test']) {
            System.assertEquals(gerenteId, lead.OwnerId, 'El Owner del lead debe ser el gerente');
        }
    }

    private static User createTestUser(String email, String alias, String profileName) {
        Profile p = [SELECT Id FROM Profile WHERE Name =: profileName LIMIT 1];
        return new User(
            Username = email,
            Email = email,
            LastName = 'Test',
            Alias = alias.length() > 8 ? alias.substring(0, 8) : alias,
            TimeZoneSidKey = 'America/Mexico_City',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
    }

    private static Id getRecordTypeId(String sObjectType, String developerName) {
        return [SELECT Id FROM RecordType WHERE SObjectType = :sObjectType AND DeveloperName = :developerName LIMIT 1].Id;
    }

}