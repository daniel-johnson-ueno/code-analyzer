@IsTest
private class AccountCreationServiceTest {
    @testSetup 
    static void testSetup(){
        Ueno_Service_Domain__c uenoDomain = (Ueno_Service_Domain__c)TestFactoryFramework.createSObject(new Ueno_Service_Domain__c(), 'TestFactoryFrameworkDefaults.UenoServiceDomainDefaults', true);
        Account testUenoAcc = (Account)TestFactoryFramework.createSObject(new Account(), 'TestFactoryFrameworkDefaults.InternalCompanyAccountDefaults', false);
        testUenoAcc.Name = 'Tuti';
        testUenoAcc.GroupCompaniesUeno__c = 'Tuti';
        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Vazquez_Group_Company');
        String recordTypeId = recordTypeInfo.getRecordTypeId();
        testUenoAcc.RecordTypeId = recordTypeId;
        insert testUenoAcc;

        Account testPersonAccount = (Account)TestFactoryFramework.createSObject(new Account(), 'TestFactoryFrameworkDefaults.PersonAccountDefaults', false);
        testPersonAccount.DocumentNumber__c = '00009999';
        testPersonAccount.DocumentType__c = '1';
        testPersonAccount.Phone = '99999111';
        testPersonAccount.PersonEmail = 'test@test.test';
        insert testPersonAccount;

        Case caseTest = (Case)TestFactoryFramework.createSObject(new Case(), 'TestFactoryFrameworkDefaults.ConsultaCaseDefaults', false);
        caseTest.Origin = 'Web';
        caseTest.Type = 'Reclamo';
        caseTest.Status = 'Nuevo';
        caseTest.AccountId = testPersonAccount.id;
        insert caseTest;

    }
    
    @IsTest
    static void testCreateAccountNotExistSF() {
        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount');
        String accRtId = recordTypeInfo.getRecordTypeId();
        List<AccountCreationService.AccountWrapperInput> input = new List<AccountCreationService.AccountWrapperInput>();
        AccountCreationService.AccountWrapperInput inputWrapper = new AccountCreationService.AccountWrapperInput();
        inputWrapper.documentNumber = '12345678910';
        inputWrapper.documentType = '1';
        inputWrapper.firstName = 'Test';
        inputWrapper.lastName = 'Test';
        inputWrapper.phone = '22123231';
        inputWrapper.email = 'test@testtest.test';
        inputWrapper.company = 'Tuti';
        inputWrapper.originOfCreation = 'SF - Buscador de clientes';
        inputWrapper.originOfLastModification = 'SF - Buscador de clientes';
        inputWrapper.recordType = accRtId;
        input.add(inputWrapper);
        Test.startTest(); 
            List<AccountCreationService.AccountWrapperResult> result = AccountCreationService.createAccountSF(input);
        Test.stopTest();
        Assert.areEqual(true, result[0].success, 'Result shoud be true');
    }

    @IsTest
    static void testCreateAccountExistSF() {
        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount');
        String accRtId = recordTypeInfo.getRecordTypeId();
        List<AccountCreationService.AccountWrapperInput> input = new List<AccountCreationService.AccountWrapperInput>();
        AccountCreationService.AccountWrapperInput inputWrapper = new AccountCreationService.AccountWrapperInput();
        inputWrapper.documentNumber = '00009999';
        inputWrapper.documentType = '1';
        inputWrapper.firstName = 'Test';
        inputWrapper.lastName = 'Test';
        inputWrapper.phone = '22123231';
        inputWrapper.email = 'test@testtest.test';
        inputWrapper.company = 'Tuti';
        inputWrapper.recordType = accRtId;
        input.add(inputWrapper);
        Test.startTest(); 
            List<AccountCreationService.AccountWrapperResult> result = AccountCreationService.createAccountSF(input);
        Test.stopTest();
        Assert.areEqual(false, result[0].success, 'Result shoud be false');
    }

    @IsTest
     static void testCreateBussinesAccountNotExistSF() {
        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount');
        String accRtId = recordTypeInfo.getRecordTypeId();
        AccountCreationService.AccountWrapperInput inputWrapper = new AccountCreationService.AccountWrapperInput();
        inputWrapper.documentNumber = '123456789103';
        inputWrapper.documentType = '6';
        inputWrapper.phone = '22123231';
        inputWrapper.email = 'test@testtest.test';
        inputWrapper.company = 'Tuti';
        inputWrapper.originOfCreation = 'SF - Buscador de clientes';
        inputWrapper.originOfLastModification = 'SF - Buscador de clientes';
        inputWrapper.externalId = '12345';
        inputWrapper.recordType = accRtId;
        Test.startTest(); 
            Account result = AccountCreationService.mapBusinessAccount(inputWrapper);
        Test.stopTest();
        Assert.areNotEqual(null, result, 'Result shoud not be null');
    }

    
   
}