@IsTest
private class LoyaltyControllerTest {

    @TestSetup
    private static void setup(){

        Account person = TestFactory.createPersonAccount();
        Ueno_Service_Domain__c testUrl= new Ueno_Service_Domain__c(ApiKey__c = '555-555-555',DomainName__c='https://kongcloud.ind-dev-sae1.ueno.com.py');
        insert  testUrl;

    }

    @IsTest
    private static void loyaltyCalloutTest(){

        String jsonTest = '{"balance":250,"tier":{"id":424,"businessUnitId":1,"name":"tier 1","level":1,"minimumPoints":0,"maximumPoints":2999}}';

        Account person = [SELECT Id, UniqueId__c FROM Account LIMIT 1];
        person.UniqueId__c = '12394hfha-01909cna';
        update person;

        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok', jsonTest));

        Test.startTest();

        LoyaltyController.LoyaltyWrapper loyalty = LoyaltyController.loyaltyCallout(person.Id);

        System.assertEquals(250, loyalty.balance);

        Test.stopTest();
    }

    @IsTest
    private static void loyaltyCalloutErrorTest(){

        String jsonTest = '{"code":400,"type":"NotFound","message":"Membernotfound","traceId":"42d54977-7dda-49c2-ac7b-492559710db3"}';

        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(400, 'Error', jsonTest));

        Test.startTest();
        Account person = [SELECT Id, UniqueId__c FROM Account LIMIT 1];
        person.UniqueId__c = '12394hfha-01909cna';
        update person;

        LoyaltyController.LoyaltyWrapper loyalty = LoyaltyController.loyaltyCallout(person.Id);

        Test.stopTest();
    }

    @IsTest
    private static void loyaltyCalloutCatchTest(){

        Test.startTest();

        try{
            LoyaltyController.LoyaltyWrapper loyalty = LoyaltyController.loyaltyCallout('Simulate Exception');
        } catch (Exception e){
            System.debug(e);
        }
        Test.stopTest();
    }

    @IsTest
    private static void loyaltyEmptyuniqueId(){

        Test.startTest();
        Account person = [SELECT Id, UniqueId__c FROM Account LIMIT 1];
        person.UniqueId__c = '';
        update person;

        LoyaltyController.LoyaltyWrapper loyalty = LoyaltyController.loyaltyCallout(person.Id);

        Test.stopTest();
    }
}