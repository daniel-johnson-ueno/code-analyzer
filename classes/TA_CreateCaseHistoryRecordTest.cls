@isTest
public class TA_CreateCaseHistoryRecordTest {
    @isTest
	public static void testCaseOwnerChangeUserToQueue() {
        Id profIdSU = [SELECT Id FROM Profile LIMIT 1].Id;
        
        List<User> testUsers = [SELECT Id FROM User WHERE ProfileId = :profIdSU AND IsActive = true LIMIT 1];
        User testUser;
        if(!testUsers.isEmpty()){
            System.debug('testUsers[0] '+testUsers[0]);
            testUser = testUsers[0];
        }
        
		Group testQueue;
        List<Group> testGroups = [SELECT Id, DeveloperName from Group WHERE DeveloperName = 'Nomina_Turnero'];
        
		if(!testGroups.isEmpty()){
            testQueue = testGroups[0];
        }

        Case testCase = new Case(
            Subject = 'Test',
            OwnerId = testUser.Id, 
            Origin = 'Turnero'
        );
        insert testCase;
        
		Case testCaseNew = new Case(
            Id = testCase.Id, 
        	OwnerId = testQueue.Id
        );
        
        update testCaseNew;
        
        Test.startTest();
        TA_CreateCaseHistoryRecord.afterUpdate(new List<Case>{ testCaseNew }, new Map<Id, Case>{ testCase.Id => testCase });
        Test.stopTest();
        
        testCase = [SELECT OwnerId FROM Case WHERE Id = :testCase.Id];
        System.assertEquals(testQueue.Id, testCase.OwnerId, 'El propietario del caso debe ser la Queue');
    }
    
    @isTest
	public static void testCaseOwnerChangeQueueToUser() {
        
        Id profIdSU = [SELECT Id FROM Profile LIMIT 1].Id;
        
        List<User> testUsers = [SELECT Id FROM User WHERE ProfileId = :profIdSU AND IsActive = true LIMIT 1];
        User testUser;
        if(!testUsers.isEmpty()){
            testUser = testUsers[0];
        }
        
        Group testQueue;
        List<Group> testGroups = [SELECT Id, DeveloperName from Group WHERE DeveloperName = 'Nomina_Turnero'];
        
		if(!testGroups.isEmpty()){
            System.debug('testGroups[0] '+testGroups[0]);
            testQueue = testGroups[0];
        }
        
        Case testCase = new Case(
            Subject = 'Test',
            OwnerId = testQueue.Id,
            Origin = 'Turnero'
        );
        insert testCase;
        
		Case testCaseNew = new Case(
            Id = testCase.Id, 
        	OwnerId = testUser.Id
        );
        
        update testCaseNew;
        
        Test.startTest();
        TA_CreateCaseHistoryRecord.afterUpdate(new List<Case>{ testCaseNew }, new Map<Id,Case>{ testCase.Id => testCase });
        Test.stopTest();
        
        testCase = [SELECT OwnerId FROM Case WHERE Id = :testCase.Id];
        System.assertEquals(testUser.Id, testCase.OwnerId, 'El propietario del caso debe ser el Usuario');
    }
}