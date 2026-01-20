@isTest
public without sharing class OnboardingControllerTest {
    @testSetup
    static void setupTestData() {
        
        Account preferenceExperienceCenter =(Account)TestFactoryFramework.createSObject(new Account());
        preferenceExperienceCenter.Name = 'Areguá'; 
        preferenceExperienceCenter.Numero_Oficina__c = 320;
        preferenceExperienceCenter.Servicios_Disponibles__c = 'TED';
        preferenceExperienceCenter.CurrencyIsoCode = 'PYG';
        preferenceExperienceCenter.BillingCountry = 'Paraguay';
        preferenceExperienceCenter.type__c = 'Local ueno bank';
        preferenceExperienceCenter.IsPerson__c = false; 
        preferenceExperienceCenter.Region__c = 'Centro';
        preferenceExperienceCenter.RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Internal_Company' LIMIT 1].Id;
        insert preferenceExperienceCenter;
        
        Id testExperienceCenterId = preferenceExperienceCenter.Id;
        Account testAccount = (Account)TestFactoryFramework.createSObject(new Account());
        testAccount.Name = 'Test Account'; 
        testAccount.DocumentNumber__c = '12345678';
        testAccount.DocumentType__c = '6';
        testAccount.CompanyName__c = 'Test Company';
        testAccount.Preference_Experience_Center__c = testExperienceCenterId;
        insert testAccount;
        
        Account personAccount = (Account)TestFactoryFramework.createSObject(new Account(), 'TestFactoryFrameworkDefaults.PersonAccountDefaults', true);
        personAccount.DocumentNumber__c = '987654321';
        personAccount.DocumentType__c = '1';
        update personAccount;
    
        Case testCase = (Case)TestFactoryFramework.createSObject(new Case());
        testCase.Status = 'Nuevo';
        testCase.Origin = 'Web';
        testCase.Subject = 'Test Case';
        testCase.Description = 'Test Case';
        testCase.AccountId = testAccount.Id;
        testCase.RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Solicitud' LIMIT 1].Id;
        insert testCase;
    
        Lead testLead = (Lead)TestFactoryFramework.createSObject(new Lead());
        testLead.Company = 'Test Company';
        testLead.DocumentNumber__c = '12345678';
        testLead.Document_Type__c = '6';
        testLead.LastName = 'TEST LASTNAME';
        testLead.Status = 'Nuevo';
        testLead.Revenue__c = '250M<2.5MM';
        testLead.Preference_Experience_Center__c = testExperienceCenterId;
        insert testLead;
    
        String recordTypeName = 'Onboarding';
        String objName = 'Opportunity';
        Id oppRtId = OnboardingController.getRecordTypeId(objName, recordTypeName);
    
        Opportunity testOpportunity = (Opportunity)TestFactoryFramework.createSObject(new Opportunity());
        testOpportunity.Name = 'Test Opportunity - ' + testAccount.Name;
        testOpportunity.StageName = 'Asignación';
        testOpportunity.CloseDate = Date.today().addDays(7);
        testOpportunity.AccountId = testAccount.Id;
        testOpportunity.Document_Number__c = '12345678';
        testOpportunity.Document_Type__c = '6';
        testOpportunity.Preference_Experience_Center__c = testExperienceCenterId;
        testOpportunity.RecordTypeId = oppRtId;
        insert testOpportunity;
    
        Id standardPbId = Test.getStandardPricebookId();

        // Crear Product2
        Product2 prod = (Product2)TestFactoryFramework.createSObject(new Product2());
        prod.Name = 'Caja de Ahorro';
        prod.IsActive = true;
        insert prod;
        
        // Crear PricebookEntry en Pricebook estándar (requerido)
        PricebookEntry stdEntry = new PricebookEntry(
            Pricebook2Id = standardPbId,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert stdEntry;
    
        // Agregar OpportunityLineItem
        OpportunityLineItem newOpp = (OpportunityLineItem)TestFactoryFramework.createSObject(new OpportunityLineItem());
        newOpp.UnitPrice = 0; 
        newOpp.Quantity = 1; 
        newOpp.Product2Id = prod.Id; 
        newOpp.OpportunityId = testOpportunity.Id; 
        newOpp.PricebookEntryId = stdEntry.Id; 
        insert newOpp;
    }



    @isTest
    public static void testCreateLeadAndCloseCase() {

        Test.startTest();
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        Account preferenceExperienceCenter = [SELECT Id FROM Account WHERE Name = 'Areguá'];
        Id testExperienceCenterId = preferenceExperienceCenter.Id;
        
        Id caseId = OnboardingController.createLeadAndCloseCase(
            testCase.Id, 
            testExperienceCenterId,
            'Test Company',
            '12345678', 
            '987654321',
            '1', 
            'jm.gomez@globant.com'
        );
        Test.stopTest();

        Case closedCase = [SELECT Id, Status FROM Case WHERE Id = :caseId];
        System.assertEquals('Cerrado', closedCase.Status);

        Lead existingLead = [SELECT Id, Company FROM Lead WHERE DocumentNumber__c = '12345678' LIMIT 1];
        System.assertNotEquals(null, existingLead, 'El Lead debería existir si ya fue creado previamente');
        System.assertEquals('Test Company', existingLead.Company, 'El nombre de la empresa del Lead debería coincidir');
    }

    @isTest
    public static void testCreateLeadAndCloseCaseWithException() {
        try {
            Account preferenceExperienceCenter = [SELECT Id FROM Account WHERE Name = 'Areguá'];
        	Id testExperienceCenterId = preferenceExperienceCenter.Id;
            OnboardingController.createLeadAndCloseCase(
                null,
                testExperienceCenterId, 
                'Test Company', 
                '12345678', 
                '987654321', 
                '6',
                'jm.gomez@globant.com'
            );
            System.assert(false, 'Se esperaba una excepción al pasar un caso nulo');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage(), 'Debería lanzar una excepción con este mensaje.');
        }

        try {
            Case testCase = (Case)TestFactoryFramework.createSObject(new Case());
            testCase.Status = 'Nuevo';
            testCase.Origin = 'Web';
            testCase.Subject = 'Test Case - Account does not exist';
            testCase.Description = 'Test Case';
            testCase.AccountId = null;
            testCase.RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Solicitud' LIMIT 1].Id;
            insert testCase;
            
            OnboardingController.createLeadAndCloseCase(
                testCase.Id, 
                null,
                'Test Company', 
                '12345678', 
                '987654321', 
                '6',
                'jm.gomez@globant.com'
            );
            System.assert(false, 'Se esperaba una excepción al pasar Preference_Experience_Center__c vacío');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage(), 'Debería lanzar una excepción con este mensaje.');
        }
    }

    @isTest
    public static void testCreateLeadAndCloseCaseWhenAccountDoesNotExist() {

        Test.startTest();
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        Account preferenceExperienceCenter = [SELECT Id FROM Account WHERE Name = 'Areguá'];
        Id testExperienceCenterId = preferenceExperienceCenter.Id;
        Id caseId = OnboardingController.createLeadAndCloseCase(
            testCase.Id, 
            testExperienceCenterId,
            'Test Company',
            '123456789', 
            '987654321',
            '6',
            'jm.gomez@globant.com'
        );
        Test.stopTest();

        Case closedCase = [SELECT Id, Status FROM Case WHERE Id = :caseId];
        System.assertEquals('Cerrado', closedCase.Status);

        Lead existingLead = [SELECT Id, Company FROM Lead WHERE DocumentNumber__c = '12345678' LIMIT 1];
        System.assertNotEquals(null, existingLead, 'El Lead debería existir si ya fue creado previamente');
        System.assertEquals('Test Company', existingLead.Company, 'El nombre de la empresa del Lead debería coincidir');
    }
}