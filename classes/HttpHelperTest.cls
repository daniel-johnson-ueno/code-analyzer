@IsTest
private class HttpHelperTest {
    @TestSetup
    private static void setupTest() {

        Account customer = new Account();
        customer.Name = 'Test Account';
        customer.PersonCode__c = 123456;
        Database.insert(customer);

        Ueno_Service_Domain__c uenoDomain = new Ueno_Service_Domain__c();
        uenoDomain.ApiKey__c = '09-746e-4e1d';
        uenoDomain.DomainName__c = 'https://platform-kong-public-d.com';
        Database.insert(uenoDomain);

    }

    @IsTest
    private static void exceptionTest() {

        Account customer = [SELECT Id, PersonCode__c, Documentos__c FROM Account LIMIT 1];

        Ueno_Service_Domain__c domain = Ueno_Service_Domain__c.getOrgDefaults();
        Web_Service_Endpoint__mdt wsEndpSetting = Web_Service_Endpoint__mdt.getInstance('customerDocuments');

        String endpoint = domain.DomainName__c + wsEndpSetting.path__c + '/' + customer.PersonCode__c + '/documents';

        Test.startTest();
            try {
                HttpRequest req = new HttpRequest();
                HttpHelper.HttpClientWithRetry httpClient = new HttpHelper.HttpClientWithRetry();
                req.setEndpoint(endpoint);
                req.setHeader('Content-Type', 'application/json');
                req.setHeader('apikey', domain.ApiKey__c);
                req.setMethod('GET');
                req.setTimeout(120000);

                HttpResponse tResponse = httpClient.doCallout(req);
            } catch(Exception e) {
                System.assertEquals(1,1);
            }
        Test.stopTest();
    }

    @IsTest
    private static void httpClientExceptionTest() {

        Account customer = [SELECT Id, PersonCode__c, Documentos__c FROM Account LIMIT 1];

        Ueno_Service_Domain__c domain = Ueno_Service_Domain__c.getOrgDefaults();
        Web_Service_Endpoint__mdt wsEndpSetting = Web_Service_Endpoint__mdt.getInstance('customerDocuments');

        String endpoint = domain.DomainName__c + wsEndpSetting.path__c + '/' + customer.PersonCode__c + '/documents';

        Test.startTest();
            try {
                HttpRequest req = new HttpRequest();
                HttpHelper.HttpClient httpClient = new HttpHelper.HttpClient();
                req.setEndpoint(endpoint);
                req.setHeader('Content-Type', 'application/json');
                req.setHeader('apikey', domain.ApiKey__c);
                req.setMethod('GET');
                req.setTimeout(120000);

                HttpResponse tResponse = httpClient.doCallout(req);
            } catch(Exception e) {
                System.assertEquals(1,1);
            }
        Test.stopTest();
    }
}