@IsTest
private class AccountMappingServiceTest {
    
    @testSetup 
    static void testSetup(){
        
        Ueno_Service_Domain__c testUrl= new Ueno_Service_Domain__c(ApiKey__c = '555-555-555',DomainName__c='https://kongcloud.ind-dev-sae1.ueno.com.py');
        insert testUrl;
    }
    
    @isTest
    static void testGetPersonWithValidParameters() {
        List<AccountMappingService.AccountMappingRequest> requestList = new List<AccountMappingService.AccountMappingRequest>();
        AccountMappingService.AccountMappingRequest requestItem = new AccountMappingService.AccountMappingRequest();
        requestItem.documentId = '123456789';
        requestItem.documentType = '1';
        requestList.add(requestItem);
        
        List<AccountMappingService.AccountMappingResult> results = new List<AccountMappingService.AccountMappingResult>();
		
        // Mock remote site connection
        AccountRemoteSiteConnectionMock fakeResponse;
        fakeResponse = new AccountRemoteSiteConnectionMock(200, '','',
                                                           AccountRemoteSiteConnectionMock.getPerson_Founded());
        
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Test.startTest(); 
        results = AccountMappingService.mapAccountData(requestList);
        Test.stopTest(); 
        System.debug('results: ' + results);
        
        System.assertEquals('200', results[0].code);
    }

    @isTest
     static void testGetCompanyWithValidParameters() {
        List<AccountMappingService.AccountMappingRequest> requestList = new List<AccountMappingService.AccountMappingRequest>();
        AccountMappingService.AccountMappingRequest requestItem = new AccountMappingService.AccountMappingRequest();
        requestItem.documentId = '1';
        requestItem.documentType = '6';
        requestList.add(requestItem);
        
        List<AccountMappingService.AccountMappingResult> results = new List<AccountMappingService.AccountMappingResult>();
		
        // Mock remote site connection
        AccountRemoteSiteConnectionMock fakeResponse;
        fakeResponse = new AccountRemoteSiteConnectionMock(200, '','',
                                                           AccountRemoteSiteConnectionMock.getCompany_Founded());
        
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Test.startTest(); 
        results = AccountMappingService.mapAccountData(requestList);
        Test.stopTest(); 
        System.debug('results: ' + results);
        
        System.assertEquals('200', results[0].code);
    }

    @IsTest
    static void testMapAccountDataNotFound() {
        List<AccountMappingService.AccountMappingRequest> requestList = new List<AccountMappingService.AccountMappingRequest>();
        AccountMappingService.AccountMappingRequest request = new AccountMappingService.AccountMappingRequest();
        request.documentId = '';
        request.documentType = '';
        requestList.add(request);
		List<AccountMappingService.AccountMappingResult> results = new List<AccountMappingService.AccountMappingResult>();
        
        // Mock remote site connection
        AccountRemoteSiteConnectionMock fakeResponse;
        fakeResponse = new AccountRemoteSiteConnectionMock(404, '','',
                                                           AccountRemoteSiteConnectionMock.getPerson_NotFound());
        
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Test.startTest(); 
        results = AccountMappingService.mapAccountData(requestList);
        Test.stopTest(); 
        System.debug('results: ' + results);
        
        System.assertEquals('404', results[0].code);
    }

    @IsTest
    static void testMapAccountDataFailure() {
        List<AccountMappingService.AccountMappingRequest> requestList = new List<AccountMappingService.AccountMappingRequest>();
        AccountMappingService.AccountMappingRequest request = new AccountMappingService.AccountMappingRequest();
        request.documentId = '';
        request.documentType = '';
        requestList.add(request);
		List<AccountMappingService.AccountMappingResult> results = new List<AccountMappingService.AccountMappingResult>();
        
        // Mock remote site connection
        AccountRemoteSiteConnectionMock fakeResponse;
        fakeResponse = new AccountRemoteSiteConnectionMock(500, '','',
                                                           AccountRemoteSiteConnectionMock.getPerson_Bad());
        
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Test.startTest(); 
        results = AccountMappingService.mapAccountData(requestList);
        Test.stopTest(); 
        System.debug('results: ' + results);
        
        System.assertEquals('500', results[0].code);

    }

    @isTest
    static void testGetPersonWithPendingOnboarding() {
        List<AccountMappingService.AccountMappingRequest> requestList = new List<AccountMappingService.AccountMappingRequest>();
        AccountMappingService.AccountMappingRequest requestItem = new AccountMappingService.AccountMappingRequest();
        requestItem.documentId = '595911503675';
        requestItem.documentType = '99';
        requestList.add(requestItem);

        List<AccountMappingService.AccountMappingResult> results = new List<AccountMappingService.AccountMappingResult>();

        // Mock remote site connection
        AccountRemoteSiteConnectionMock fakeResponse;
        fakeResponse = new AccountRemoteSiteConnectionMock(200, '','',
                AccountRemoteSiteConnectionMock.getPerson_PendingOnboarding());

        Test.setMock(HttpCalloutMock.class, fakeResponse);

        Test.startTest();
        results = AccountMappingService.mapAccountData(requestList);
        Test.stopTest();
        System.debug('results: ' + results);

        System.assertEquals('200', results[0].code);
    }

}