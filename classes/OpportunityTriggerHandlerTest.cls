/**
 * @description       : 
 * @group             : 
 * @last modified on  : 06-02-2025
 * @last modified by  : Noe Vasquez
**/
@isTest
public class OpportunityTriggerHandlerTest {

    @testSetup
    static void setupTestData() {
        // Pricebooks
        Pricebook2 uenoPersonas = new Pricebook2(Name = 'ueno personas', IsActive = true);
        Pricebook2 uenoEmpresas = new Pricebook2(Name = 'ueno empresas', IsActive = true);
        Pricebook2 upay = new Pricebook2(Name = 'upay', IsActive = true);
    
        uenoPersonas = (Pricebook2)TestFactoryFramework.createSObject(uenoPersonas, true);
        uenoEmpresas = (Pricebook2)TestFactoryFramework.createSObject(uenoEmpresas, true);
        upay = (Pricebook2)TestFactoryFramework.createSObject(upay, true);
    
        Id standardPBId = Test.getStandardPricebookId();
    
        // Productos
        Product2 prod1 = new Product2(Name = 'Caja de Ahorro', IsActive = true);
        Product2 prod2 = new Product2(Name = 'Pos upay', IsActive = true);
        prod1 = (Product2)TestFactoryFramework.createSObject(prod1, true);
        prod2 = (Product2)TestFactoryFramework.createSObject(prod2, true);
    
        // Primero, el PricebookEntry estándar para cada producto
        PricebookEntry standardPBE1 = new PricebookEntry(Pricebook2Id = standardPBId, Product2Id = prod1.Id, UnitPrice = 2000, IsActive = true);
        standardPBE1 = (PricebookEntry)TestFactoryFramework.createSObject(standardPBE1, true);
    
        PricebookEntry standardPBE2 = new PricebookEntry(Pricebook2Id = standardPBId, Product2Id = prod2.Id, UnitPrice = 1000, IsActive = true);
        standardPBE2 = (PricebookEntry)TestFactoryFramework.createSObject(standardPBE2, true);
    
        PricebookEntry pbeOnboarding = new PricebookEntry(Pricebook2Id = uenoEmpresas.Id, Product2Id = prod1.Id, UnitPrice = 1000, IsActive = true);
        pbeOnboarding = (PricebookEntry)TestFactoryFramework.createSObject(pbeOnboarding, true);
        
        PricebookEntry pbeOnboardingPersonas = new PricebookEntry(Pricebook2Id = uenoPersonas.Id, Product2Id = prod1.Id, UnitPrice = 1000, IsActive = true);
        pbeOnboardingPersonas = (PricebookEntry)TestFactoryFramework.createSObject(pbeOnboardingPersonas, true);
    
        PricebookEntry pbeUpay = new PricebookEntry(Pricebook2Id = upay.Id, Product2Id = prod2.Id, UnitPrice = 1000, IsActive = true);
        pbeUpay = (PricebookEntry)TestFactoryFramework.createSObject(pbeUpay, true);
    
        // Cuenta y oportunidad
        RecordType onboardingRT_Acc = [SELECT Id FROM RecordType WHERE DeveloperName = 'PersonAccount' AND SObjectType = 'Account' LIMIT 1];
        //RecordType onboardingRT_Acc_Negocio = [SELECT Id FROM RecordType WHERE DeveloperName = 'IndustriesBusiness' AND SObjectType = 'Account' LIMIT 1];
        
        Account acc = new Account(Name = 'Test Corp');
        acc = (Account)TestFactoryFramework.createSObject(acc, true);
        
        Account accPersonal = new Account(LastName = 'Test Account', RecordTypeId = onboardingRT_Acc.Id);
        accPersonal = (Account)TestFactoryFramework.createSObject(accPersonal, true);


        RecordType onboardingRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'Onboarding' AND SObjectType = 'Opportunity' LIMIT 1];
        RecordType upayRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'Upay' AND SObjectType = 'Opportunity' LIMIT 1];
    
        Opportunity oppOnboarding = new Opportunity(
            Name = 'Oportunidad Test',
            AccountId = acc.Id,
            StageName = 'Asignación',
            CloseDate = Date.today(),
            RecordTypeId = onboardingRT.Id
        );
        
        oppOnboarding = (Opportunity)TestFactoryFramework.createSObject(oppOnboarding, true);
        
        Opportunity oppUpay = new Opportunity(
            Name = 'Oportunidad Test Upay',
            AccountId = acc.Id,
            StageName = 'Nuevo',
            CloseDate = Date.today(),
            RecordTypeId = upayRT.Id
        );
        
        oppUpay = (Opportunity)TestFactoryFramework.createSObject(oppUpay, true);
        
        
    }

    @isTest
    static void testDuplicateOpportunity() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Corp' LIMIT 1];
        RecordType onboardingRT = [SELECT Id FROM RecordType WHERE Name = 'Onboarding' AND SObjectType = 'Opportunity' LIMIT 1];
		
        Opportunity dupOpp = (Opportunity)TestFactoryFramework.createSObject(new Opportunity());
        dupOpp.Name = 'Oportunidad Test';
        dupOpp.AccountId = acc.Id;
        dupOpp.StageName = 'Asignación';
        dupOpp.CloseDate = Date.today();
        dupOpp.RecordTypeId = onboardingRT.Id;
        
        Test.startTest();
        Boolean errorThrown = false;
        try {
            insert dupOpp;
        } catch (DmlException e) {
            errorThrown = true;
            System.assert(e.getMessage().contains('Ya existe una oportunidad de tipo "Onboarding"'), 'No se mostró el mensaje de error esperado.');
        }
        Test.stopTest();

        System.assert(errorThrown, 'No se lanzó una excepción al intentar insertar una oportunidad duplicada.');
    }

    @IsTest
    static void testUpayOpp() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Corp' LIMIT 1];
        RecordType generalRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'General' AND SObjectType = 'Opportunity' LIMIT 1];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'ByPass_Flow' LIMIT 1];

        User mainUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        // Asignación de PermissionSet encapsulada en runAs, sin Test.startTest()
        List<PermissionSetAssignment> existingMainAssignments = [
            SELECT Id FROM PermissionSetAssignment 
            WHERE AssigneeId = :mainUser.Id AND PermissionSetId = :ps.Id
        ];

        if (existingMainAssignments.isEmpty()) {
            System.runAs(mainUser) {
                PermissionSetAssignment mainPermission = new PermissionSetAssignment(
                    AssigneeId = mainUser.Id,
                    PermissionSetId = ps.Id
                );
                insert mainPermission;
            }
        }

        // Cambiar campo en User (esto también es "setup object")
        System.runAs(mainUser) {
            User userAdmin = [SELECT Id, CompanyName FROM User WHERE Id = :mainUser.Id];
            userAdmin.CompanyName = 'Upay';
            update userAdmin;
        }

        // Ahora probamos la lógica con objetos "non-setup" (Opportunity)
        Test.startTest();
        Opportunity oppGeneral = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Nuevo',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id,
            RecordTypeId = generalRT.Id
        );
        oppGeneral = (Opportunity)TestFactoryFramework.createSObject(oppGeneral, true);
        Test.stopTest();
    }

    @IsTest
    static void testOnboardingOpp() {
        Account accPersonal = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        RecordType onboardingRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'Onboarding' AND SObjectType = 'Opportunity' LIMIT 1];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'ByPass_Flow' LIMIT 1];

        User mainUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        // Asignación de PermissionSet encapsulada en runAs, sin Test.startTest()
        List<PermissionSetAssignment> existingMainAssignments = [
            SELECT Id FROM PermissionSetAssignment 
            WHERE AssigneeId = :mainUser.Id AND PermissionSetId = :ps.Id
        ];

        if (existingMainAssignments.isEmpty()) {
            System.runAs(mainUser) {
                PermissionSetAssignment mainPermission = new PermissionSetAssignment(
                    AssigneeId = mainUser.Id,
                    PermissionSetId = ps.Id
                );
                insert mainPermission;
            }
        }

        // Cambiar campo en User (esto también es "setup object")
        System.runAs(mainUser) {
            User userAdmin = [SELECT Id, CompanyName FROM User WHERE Id = :mainUser.Id];
            userAdmin.CompanyName = 'Ueno Bank';
            update userAdmin;
        }

        // Ahora probamos la lógica con objetos "non-setup" (Opportunity)
        Test.startTest();
        Opportunity oppOnboardingPerson = new Opportunity(
            Name = 'Oportunidad Test',
            AccountId = accPersonal.Id,
            StageName = 'Asignación',
            CloseDate = Date.today(),
            RecordTypeId = onboardingRT.Id
        );
        
        oppOnboardingPerson = (Opportunity)TestFactoryFramework.createSObject(oppOnboardingPerson, true);
        Test.stopTest();
    }
    
    @isTest
    static void testHandleAfterUpdate_OwnerChangeOnly() {
        User existingUser = new User(Id = UserInfo.getUserId());
        
		System.runAs(existingUser) {           
            Opportunity opp = (Opportunity)TestFactoryFramework.createSObject(new Opportunity());
            opp.StageName = 'Asignación';
            opp.Name = 'Test Opp';
            opp.CloseDate = Date.today().addDays(30);
            opp.CompanyType__c = 'EAS';
            opp.OwnerId = existingUser.Id; 
            insert opp;

             ActionPlanTemplate plantemplate = (ActionPlanTemplate)TestFactoryFramework.createSObject(new ActionPlanTemplate());
            plantemplate.ActionPlanType = 'Industries';
            plantemplate.Name = 'Test template';
            plantemplate.TargetEntityType = 'Opportunity';
            insert plantemplate;
            
            List<ActionPlanTemplateVersion> versions = [
                SELECT Id, Status FROM ActionPlanTemplateVersion WHERE ActionPlanTemplateId = :plantemplate.Id
            ];

            ActionPlanTemplateVersion version = versions[0];


            ActionPlanTemplateItem item = new ActionPlanTemplateItem(
                ActionPlanTemplateVersionId = version.Id,
                Name = 'Tarea de prueba',
                DisplayOrder = 1,
                ItemEntityType = 'Task'
            );
            insert item;
            

            ActionPlanTemplateItemValue templateValue = new ActionPlanTemplateItemValue(
                ActionPlanTemplateItemId = item.Id,
                ItemEntityFieldName = 'Task.Subject',
                ValueLiteral = 'ValueLiteral Test'
            );
            insert templateValue;

            version.Status = 'Final';
            update version;


            Date dateNow =  DateTime.now().date();
            ActionPlan ap = (ActionPlan)TestFactoryFramework.createSObject(new ActionPlan());
            ap.name ='Test Action Plan'; 
            ap.TargetId = opp.Id; 
            ap.ActionPlanState = 'Nuevo';
            ap.ActionPlanType = 'Industries';
            ap.ActionPlanTemplateVersionId = version.Id; 
            ap.StartDate = dateNow; 
            insert ap;
            
            User newOwner = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1];

            Opportunity op = [SELECT Id, Name FROM Opportunity WHERE CompanyType__c= 'EAS'];
            op.OwnerId = newOwner.Id;
            
            Test.startTest();
            update op;
            Test.stopTest();
            Opportunity oportunidad = [SELECT Id, OwnerId FROM Opportunity WHERE CompanyType__c= 'EAS'];
            ActionPlan planAccion = [SELECT Id, OwnerId FROM ActionPlan LIMIT 1];
            Assert.areEqual(newOwner.Id, oportunidad.OwnerId, 'El propietario debe ser el nuevo usuario asignado');
            Assert.areEqual(newOwner.Id, planAccion.OwnerId, 'El propietario debe ser el nuevo usuario asignado');
		}
    }
}