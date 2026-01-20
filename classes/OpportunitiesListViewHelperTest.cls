@isTest
public class OpportunitiesListViewHelperTest {

    @testSetup
    static void setupData() {
        // Crear una cuenta
        Account acc = (Account)TestFactoryFramework.createSObject(new Account());
        acc.Name = 'Test Account'; 
        insert acc; 

        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        // Crear oportunidades
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 3; i++) {
            Opportunity opp = (Opportunity)TestFactoryFramework.createSObject(new Opportunity());
            opp.Name = 'Test Opportunity ' + i;
            opp.StageName = 'Asignación';
            opp.CloseDate = Date.today().addDays(7);
            opp.AccountId = acc.Id;
            opp.OwnerId = u.Id; 
            opps.add(opp);
        }
        insert opps;
    }

    @isTest
    static void testGetOpportunities() {
        Test.startTest();
        List<Opportunity> opps = OpportunitiesListViewHelper.getOpportunities();
        Test.stopTest();

        System.assertNotEquals(0, opps.size(), 'Debe retornar oportunidades');
        System.assertNotEquals(null, opps[0].StageName, 'StageName debe tener el label del picklist');
    }

    @isTest
    static void testSearchOpportunities() {
        Test.startTest();
        List<Opportunity> results = OpportunitiesListViewHelper.searchOpportunities('Test');
        Test.stopTest();

        System.assert(results.size() > 0, 'Debe encontrar oportunidades con el texto "Test"');
    }

    @isTest
    static void testUpdateOpportunities() {
        List<Opportunity> existingOpps = [SELECT Id FROM Opportunity LIMIT 2];
        List<Id> selectedIds = new List<Id>();
        for (Opportunity opp : existingOpps) {
            selectedIds.add(opp.Id);
        }
        
        List<User> users = [
            SELECT Id, Email 
            FROM User 
            WHERE IsActive = true 
            AND Email LIKE '%.%'
        ];
        
        List<User> validEmails = new List<User>();
        for (User u : users) {
            if (!u.Email.endsWith('.invalid')) {
                validEmails.add(u);
            }
		}

        User newOwner = validEmails[0]; 

        Map<String, Object> updatedValues = new Map<String, Object>();
        updatedValues.put('OwnerId', newOwner.Id);
		
        Test.startTest();
        String baseURL = 'https://ueno--devueno.sandbox.lightning.force.com/lightning/r/Opportunity/';
        Map<String, Object> result = OpportunitiesListViewHelper.updateOpportunities(selectedIds, updatedValues, baseURL);
        Test.stopTest();

        System.assertEquals(true, result.get('success'), 'La actualización debe ser exitosa');
        System.assert(result.get('message') != null);
    }
}