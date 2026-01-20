/**
 * @description       : 
 * @group             : 
 * @last modified on  : 03-18-2025
 * @last modified by  : Noe Vasquez
**/
@isTest 
public class TA_ChangeCaseAreaTest{
    @isTest
    public static void testHandleChangeCaseAreaGroup(){
        Group supportQueue = new Group(Name = 'Soporte_TI', Type = 'Queue', Description = 'Cola de prueba');
        insert supportQueue;
        
        User testUser = [SELECT Id, Division FROM User WHERE IsActive = true LIMIT 1 ];

        Case oldCase = new Case(
            OwnerId = testUser.Id
        );
        insert oldCase;

        Case newCase = new Case(
            Id = oldCase.Id,
            OwnerId = supportQueue.Id
        );
        
        List<Case> newCases = new List<Case>{newCase};
        Map<Id, Case> oldCaseMap = new Map<Id, Case>{oldCase.Id => oldCase};

        Test.startTest();
        TA_ChangeCaseArea.handleChangeCaseArea(newCases, oldCaseMap);
        Test.stopTest();
    }
 
    @isTest
    public static void testHandleChangeCaseAreaUser(){
        
       User testUser = [SELECT Id, Division FROM User WHERE IsActive = true LIMIT 1 ];
		System.debug('testUser.Division '+testUser.Division);
        User testUser2 = [SELECT Id, Division FROM User WHERE IsActive = true AND Id != :testUser.Id LIMIT 1 ];
		System.debug('testUser2.Division '+testUser2.Division);
        Case oldCase = new Case(
            OwnerId = testUser.Id
        );
        insert oldCase;

        Case newCase = new Case(
            Id = oldCase.Id,
            OwnerId = testUser2.Id
        );
        
        List<Case> newCases = new List<Case>{newCase};
        Map<Id, Case> oldCaseMap = new Map<Id, Case>{oldCase.Id => oldCase};

        Test.startTest();
        TA_ChangeCaseArea.handleChangeCaseArea(newCases, oldCaseMap);
        Test.stopTest();
    }

    @isTest
    public static void testCompleteCaseAreaGroup(){
        Group supportQueue = new Group(Name = 'Soporte_TI', Type = 'Queue', Description = 'Cola de prueba');
        insert supportQueue;

        Case newCase = new Case(
            OwnerId = supportQueue.Id
        );
        
        List<Case> newCases = new List<Case>{newCase};

        Test.startTest();
        TA_ChangeCaseArea.handleChangeCaseArea(newCases, null);
        Test.stopTest();
    }

    @isTest
    public static void testCompleteCaseAreaUser(){
        User testUser = [SELECT Id, Division FROM User WHERE IsActive = true LIMIT 1 ];

        Case newCase = new Case(
            OwnerId = testUser.Id
        );
        
        List<Case> newCases = new List<Case>{newCase};

        Test.startTest();
        TA_ChangeCaseArea.handleChangeCaseArea(newCases, null);
        Test.stopTest();
    }

}