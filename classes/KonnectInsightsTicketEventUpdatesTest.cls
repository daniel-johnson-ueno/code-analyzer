@isTest
public class KonnectInsightsTicketEventUpdatesTest {

    @TestSetup
    private static void setup(){
        Ueno_Service_Domain__c testUrl= new Ueno_Service_Domain__c(ApiKey__c = '555-555-555',DomainName__c='https://kongcloud.ind-dev-sae1.ueno.com.py');
        insert  testUrl;
    }
    
    @isTest  
    public static void testhandleKonnectInsightsCases(){
        RecordType solicitud  = [SELECT Id, DeveloperName,SObjectType FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Solicitud' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        Account person = TestFactory.createPersonAccount();
        Case oldCase = new Case(
            OwnerId = testUser.Id,
            AccountId = person.Id,
            RecordTypeId =  solicitud.Id,
            Status = 'Nuevo',
            Origin = 'Konnect Insights - Facebook',
            Description = 'Test description',
            Subject = 'Test subject'
        );
        insert oldCase;
        Case newCase = new Case(
            Id = oldCase.Id,
            OwnerId = testUser.Id,
            AccountId = person.Id,
            RecordTypeId =  solicitud.Id,
            Status = 'Asignado'
        );
        Test.startTest();
        update newCase;
        Test.stopTest();
    }
}