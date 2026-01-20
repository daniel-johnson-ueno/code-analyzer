@IsTest
public with sharing class BenefitsControllerTest {

    @TestSetup
    public static void setup() {
        Ueno_Service_Domain__c testUrl= new Ueno_Service_Domain__c(ApiKey__c = '555-555-555',DomainName__c='https://kongcloud.ind-dev-sae1.ueno.com.py');
        insert  testUrl;
        Account person = TestFactory.createPersonAccount();
        person.UniqueId__c = '12394hfha-01909cna';
        update person;
    }


    @IsTest
    public static void benefitsLevelCalloutTest() {
        Account person = [SELECT Id FROM Account LIMIT 1];
        Date today = Date.today();
        String dateString = today.toString();

        String mock ='[{"memberId":"00000000-0000-0000-0000-000000123abc","businessUnitId":1,"recordDate":"2024-09-21 00:00:00Z","eventId":"f4857d0f-7e68-4d13-98c1-f8f78044afe2","points":300,"movementType":1,"movementReason":"Cuenta Activa"}'+
                ',{"memberId":"00000000-0000-0000-0000-000000123abc","businessUnitId":1,"recordDate":"2024-09-20 00:00:00Z","eventId":"325afa1f-7052-46d6-9810-8cf78472177e","points":600,"movementType":1,"movementReason":"Débito automático","expirationDate":"2024-10-18"}'+
                ',{"memberId":"00000000-0000-0000-0000-000000123abc","businessUnitId":1,"recordDate":"2024-09-19 00:00:00Z","eventId":"01eac763-dff0-4ccc-89e1-8d3f3bf63b86","points":200,"movementType":1,"movementReason":"Préstamo Personal Activo"}'+
                ',{"memberId":"00000000-0000-0000-0000-000000123abc","businessUnitId":1,"recordDate":"2024-09-18 00:00:00Z","eventId":"07eff978-96dd-4d29-8a45-dd2e34039c5b","points":150,"movementType":1,"movementReason":"Transacciones con TC","expirationDate":"2024-10-18"}]';

        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok', mock));

        Test.startTest();
        List<Object> points = BenefitsController.benefitsCallout( person.Id,  'historyPoints',  dateString,  dateString);
        Test.stopTest();

        Assert.areEqual(4, points.size(), 'The number of points returned should be 4');    
    }

    @IsTest
    public static void benefitsPointsCalloutTest() {
        Account person = [SELECT Id FROM Account LIMIT 1];
        Date today = Date.today();
        String dateString = today.toString();

        String mock = '[{"recordDate":"2024-09-17 13:45:59.237Z","tier":{"id":495,"businessUnitId":1,"name":"Nivel 1","level":1,"minimumPoints":0,"maximumPoints":2999}}'+
                ',{"recordDate":"2024-09-17 13:46:14.944Z","tier":{"id":496,"businessUnitId":1,"name":"Nivel 2","level":2,"minimumPoints":3000,"maximumPoints":5999}}'+
                ',{"recordDate":"2024-09-17 13:46:36.382Z","tier":{"id":497,"businessUnitId":1,"name":"Nivel 3","level":3,"minimumPoints":6000,"maximumPoints":7999}}'+
                ',{"recordDate":"2024-09-17 13:46:56.987Z","tier":{"id":499,"businessUnitId":1,"name":"Nivel 5","level":5,"minimumPoints":10000,"maximumPoints":999999999}}'+
                ',{"recordDate":"2024-09-17 14:00:00.587Z","tier":{"id":496,"businessUnitId":1,"name":"Nivel 2","level":2,"minimumPoints":3000,"maximumPoints":5999}}]';

        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok', mock));

        Test.startTest();
        List<Object> levels = BenefitsController.benefitsCallout( person.Id,  'historyLevel',  dateString,  dateString);
        Test.stopTest();

        Assert.areEqual(5, levels.size(), 'The number of levels returned should be 5');       
    }

    @IsTest
    public static void upysSummaryCalloutTest() {
        Account person = [SELECT Id FROM Account LIMIT 1];

        String mock = '{"results":[{"id":25,"name":"Upys por Gs","points":8,"lastEventDate":"2025-06-02 16:34:32Z","lastEventId":"1","pointsToLimit":9992},'+
            '{"id":25,"name":"Upys por Gs 2","points":16,"lastEventDate":"2025-06-02 16:34:32Z","lastEventId":"2","pointsToLimit":9984}]}';  

        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok', mock));

        Test.startTest();
        List<Object> upys = BenefitsController.benefitsCallout( person.Id,  'upysSummary',  null,  null);
        Test.stopTest();

        Assert.areEqual(2, upys.size(), 'The number of levels returned should be 2');        
    }

    @IsTest
    public static void benefitsErrorCalloutTest() {
        Date today = Date.today();
        String dateString = today.toString();
        String errorMessage;

        Test.startTest();
        try{
            List<Object> levels = BenefitsController.benefitsCallout('Simulate Exception',  'historyLevel',  dateString,  dateString);
        } catch(Exception e){
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        Assert.areNotEqual(null, errorMessage, 'An error message should be returned when simulating an exception');
    }
}