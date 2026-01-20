@IsTest
private class SearchClientServiceControllerTest {
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
    
    @isTest
    static void testGetAccountWithValidParameters() {
        String documentId = '123456789';
        String documentType = '1';
        String result;
        AccountRemoteSiteConnectionMock fakeResponse = new AccountRemoteSiteConnectionMock(200, '','',AccountRemoteSiteConnectionMock.getPerson_Founded());
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Test.startTest(); 
            result = SearchClientServiceController.getAccountId(documentId, documentType);
        Test.stopTest();
        System.assert(String.isNotBlank(result));
    }

    @IsTest
    static void testgetAccountDataNotFound() {
        String documentId = '123456789';
        String documentType = '999';
        String result;
        AccountRemoteSiteConnectionMock fakeResponse = new AccountRemoteSiteConnectionMock(404, '','', AccountRemoteSiteConnectionMock.getPerson_NotFound());
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Test.startTest(); 
            result = SearchClientServiceController.getAccountId(documentId, documentType);
        Test.stopTest();
        System.debug('results: ' + result);
        System.assert(String.isBlank(result));
    }

    @IsTest
    static void testCreateAccountNotExistSF() {
        SearchClientServiceController.AccountWrapperResult result = new SearchClientServiceController.AccountWrapperResult();
        String documentNumber = '12345678910';
        String documentType = '1';
        String firstName = 'Test';
        String lastName = 'Test';
        String phone = '22123231';
        String email = 'test@testtest.test';
        String company = 'Tuti';
        Test.startTest(); 
            result = SearchClientServiceController.createAccountSF(documentNumber, documentType, firstName, lastName, phone, email, company);
        Test.stopTest();
        Assert.areEqual(true, result.success, 'Result shoud be true');
    }

    @IsTest
    static void testCreateAccountExistSF() {
        SearchClientServiceController.AccountWrapperResult result = new SearchClientServiceController.AccountWrapperResult();
        String documentNumber = '00009999';
        String documentType = '1';
        String firstName = 'Test';
        String lastName = 'Test';
        String phone = '22123231';
        String email = 'test@testtest.test';
        String company = 'tuti';
        Test.startTest(); 
            result = SearchClientServiceController.createAccountSF(documentNumber, documentType, firstName, lastName, phone, email, company);
        Test.stopTest();
        Assert.areEqual(true, result.isDuplicated, 'Result shoud be true');
    }

    @IsTest
    static void testUpdateCaseWithAccount() {
        Case caseTest = [SELECT Id, AccountId FROM Case LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE DocumentNumber__c = '00009999'];
        Test.startTest(); 
            Case c = SearchClientServiceController.updateCaseWithAccount(acc.id, caseTest.id);
        Test.stopTest();
        Assert.areEqual(acc.id, c.accountId, 'Account should be related to Case');
    }
    
    @IsTest
    static void testGetCompanies() {
        Test.startTest(); 
            List<Account> accs = SearchClientServiceController.getCompanies();
        Test.stopTest();
        Assert.areNotEqual(null, accs, 'Accounts should not be null');
    }


    @IsTest
    static void testCreateAccountNotExistSFBussinesAccount() {
        SearchClientServiceController.AccountWrapperResult result = new SearchClientServiceController.AccountWrapperResult();
        String documentNumber = '12345678910';
        String documentType = '6';
        String firstName = 'Test';
        String lastName = 'Test';
        String phone = '22123231';
        String email = 'test@testtest.test';
        String company = 'Tuti';
        Test.startTest(); 
            result = SearchClientServiceController.createAccountSF(documentNumber, documentType, firstName, lastName, phone, email, company);
        Test.stopTest();
        Assert.areEqual(true, result.success, 'Result shoud be true');
    }
}