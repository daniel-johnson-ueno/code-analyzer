@isTest
public with sharing class ExecutiveAssistanceControllerTest {

    @isTest
    static void testGetExecutiveAssistanceResponse() {
        User testUser = [SELECT Id, Name FROM User WHERE IsActive = TRUE AND UserType = 'Standard' LIMIT 1];
        System.debug(testUser);

        Shift__c testShift = createTestShift(testUser.Id);
        List<UserServicePresence> userServicePresences = [SELECT Id, CreatedDate, UserId FROM UserServicePresence];
        System.debug(userServicePresences);

        Test.startTest();
        List<ExecutiveAssistanceService.ExecutiveAssistanceWrapper> result = ExecutiveAssistanceController.executiveAssistanceList(Date.today());
        Test.stopTest();

        System.assertNotEquals(result, null, 'El resultado no debe ser nulo');
        System.assert(result.size() > 0, 'Debe haber al menos un resultado');

        ExecutiveAssistanceService.ExecutiveAssistanceWrapper firstResult = result[0];
//        System.assertEquals(firstResult.name, testUser.FirstName + ' ' + testUser.LastName, 'El nombre del ejecutivo no coincide');
    }

    private static Shift__c createTestShift(Id userId) {
        Shift__c shift = new Shift__c(
                Executive__c = userId,
                Start__c = System.now().addHours(-1),
                End__c = System.now().addHours(7)
        );
        insert shift;
        return shift;
    }

//    private static UserServicePresence createTestUserServicePresence(Id userId) {
//
//        UserServicePresence usp = new UserServicePresence(
//                UserId = userId,
//                ServicePresenceStatus = [SELECT Id FROM ServicePresenceStatus WHERE MasterLabel LIKE '%disponible%' LIMIT 1]
//        );
//        insert usp;
//        return usp;
//    }
}