@IsTest
private class AccountMappingServiceLWCTest {
    @testSetup 
    static void testSetup(){
        
        Ueno_Service_Domain__c testUrl= new Ueno_Service_Domain__c(ApiKey__c = '555-555-555',DomainName__c='https://kongcloud.ind-dev-sae1.ueno.com.py');
        insert testUrl;
    }
    
    @isTest
    static void testGetAccountWithValidParameters() {
        String documentId = '123456789';
        String documentType = '1';
        
        String result;
		
        // Mock remote site connection
        AccountRemoteSiteConnectionMock fakeResponse;
        fakeResponse = new AccountRemoteSiteConnectionMock(200, '','',
                                                           AccountRemoteSiteConnectionMock.getPerson_Founded());
        
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Test.startTest(); 
        result = AccountMappingServiceLWC.getAccountId(documentId, documentType);
        Test.stopTest(); 
        System.debug('results: ' + result);
        
        System.assert(String.isNotBlank(result));
    }

    @IsTest
    static void testgetAccountDataNotFound() {
        String documentId = '';
        String documentType = '';
        String result;
        
        // Mock remote site connection
        AccountRemoteSiteConnectionMock fakeResponse;
        fakeResponse = new AccountRemoteSiteConnectionMock(404, '','',
                                                           AccountRemoteSiteConnectionMock.getPerson_NotFound());
        
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Test.startTest(); 
        result = AccountMappingServiceLWC.getAccountId(documentId, documentType);
        Test.stopTest(); 
        System.debug('results: ' + result);
        
        System.assert(String.isBlank(result));
    }

}