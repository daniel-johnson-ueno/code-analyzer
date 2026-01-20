/**
 * @description       : 
 * @author            : Noe Vasquez
 * @group             : 
 * @last modified on  : 05-07-2025
 * @last modified by  : Noe Vasquez
**/
@isTest
private class UpdateAccountOwnerBatchTest {
    @testSetup
    static void setupTestData() {
        
        // 1. Obtener los Permission Sets necesarios
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'ByPass_Flow' LIMIT 1];

        // Crear usuarios en contexto sin flujos
        Profile profileAdmin = [SELECT Id FROM Profile WHERE Name IN ('Administrador del sistema', 'System Administrator') LIMIT 1];
        Profile profileGerente = [SELECT Id FROM Profile WHERE Name = 'Gerente operativo' LIMIT 1];

        User adminUser, user1, user2;
        
        User mainUser = new User(Id = UserInfo.getUserId());

        // Verificar si el usuario principal ya tiene el Permission Set antes de asignarlo
        List<PermissionSetAssignment> existingMainAssignments = [
            SELECT Id FROM PermissionSetAssignment 
            WHERE AssigneeId = :mainUser.Id AND PermissionSetId = :ps.Id
            LIMIT 1
        ];


        if(existingMainAssignments.isEmpty()) {
            PermissionSetAssignment mainPermission =  new PermissionSetAssignment(
                AssigneeId = mainUser.Id,
                PermissionSetId = ps.Id
            );
            mainPermission = (PermissionSetAssignment)TestFactoryFramework.createSObject(mainPermission, true);
        }
        

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
            user2 = new User(
                LastName = 'User2', Email = 'user_def@test.com', Username = 'user_def@test.com', 
                Alias = 'u2', TimeZoneSidKey = 'America/New_York', LocaleSidKey = 'en_US', 
                EmailEncodingKey = 'UTF-8', ProfileId = profileGerente.Id, LanguageLocaleKey = 'en_US'
            );
            user1 = (User)TestFactoryFramework.createSObject(user1, true);
            user2 = (User)TestFactoryFramework.createSObject(user2,  true);
            adminUser = (User)TestFactoryFramework.createSObject(adminUser, true);

            List<PermissionSetAssignment> existingUser2Assignments = [
                SELECT Id FROM PermissionSetAssignment 
                WHERE AssigneeId = :user2.Id AND PermissionSetId = :ps.Id
                LIMIT 1
            ];

            if(existingUser2Assignments.isEmpty()) {
                PermissionSetAssignment user2Permission = new PermissionSetAssignment(
                    AssigneeId = user2.Id,
                    PermissionSetId = ps.Id
                );
                user2Permission = (PermissionSetAssignment)TestFactoryFramework.createSObject(user2Permission, true);
            }

    
        }

        
        System.runAs(user2) {
            Test.startTest();
            Account acc = new Account(
                FirstName = 'Test Acc 1',
                LastName = 'mix',
                DocumentNumber__c = '12345678', 
                DocumentType__c = '1', 
                AccountExecutiveEmail__c = 'user_abc@test.com',
                OwnerId = user2.Id
            );
            Account testPersonAccount = (Account)TestFactoryFramework.createSObject(acc, 'TestFactoryFrameworkDefaults.PersonAccountDefaults', true);
            Test.stopTest(); 

        }
    }

    @isTest
    static void testBatchExecution() {
        User user = [SELECT Id FROM User WHERE Username = 'adminabc@test.com' LIMIT 1];

        System.runAs(user) {
            Test.startTest();
            UpdateAccountOwnerBatch batch = new UpdateAccountOwnerBatch();
            Database.executeBatch(batch, 200);
            Test.stopTest();

            List<Account> updatedAccounts = [SELECT Id, Owner.Email, AccountExecutiveEmail__c FROM Account];
            for (Account acc : updatedAccounts) {
                System.assertEquals(acc.AccountExecutiveEmail__c, acc.Owner.Email, 
                    'El propietario de la cuenta no se actualizó correctamente.');
            }
        }
    }

    @isTest
    static void testSchedulableExecution() {
        Test.startTest();
        UpdateAccountOwnerBatch scheduler = new UpdateAccountOwnerBatch();
        scheduler.execute(null);
        Test.stopTest();
    }
}