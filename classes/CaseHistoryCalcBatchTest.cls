@isTest
public class CaseHistoryCalcBatchTest {

    @isTest
    public static void testBatch() {
     
    Id profIdSU = [SELECT Id FROM Profile LIMIT 1].Id;
  
    List<User> testUsers = [SELECT Id FROM User WHERE ProfileId = :profIdSU AND IsActive = true LIMIT 1];
    User testUser;
    if(!testUsers.isEmpty()){
        System.debug('testUsers[0] '+testUsers[0]);
        testUser = testUsers[0];
    }
    
    Id conversationId = Label.ConversationId;
    Id messagingChannelId = Label.MessagingChannelId;
    Id messagingEndUserId = Label.MessagingEndUserId;

    Case testCase = new Case(
    Status = 'Nuevo',
    Subject = 'Test de Conversación',
    Description = 'Test', 
    Origin = 'BOT', 
    OwnerId = testUser.Id    
    );
    insert testCase;
        
    MessagingSession testSession = new MessagingSession(
    Status = 'Active',
    CaseId = testCase.Id,
    ConversationId = conversationId,
    MessagingChannelId = messagingChannelId,
    MessagingEndUserId = messagingEndUserId   
    );
    insert testSession;

    ConversationEntry testEntry = new ConversationEntry(
    EntryType = 'Text',
    ConversationId = conversationId,
    Seq = 30,
    EntryTime = Datetime.newInstance(2025,01,29,12,25,06),
    ActorType = 'Agent'
    );
    insert testEntry;
        
    ConversationEntry testEntry2 = new ConversationEntry(
    EntryType = 'Text',
    ConversationId = conversationId,
    Seq = 31,
    EntryTime = Datetime.newInstance(2025,01,29,12,24,26),
    ActorType = 'EndUser'
    );
    insert testEntry2;

    Case_History_Enhanced__c che = new Case_History_Enhanced__c(
        User__c = testUser.Id,
        Case__c = testCase.Id
    );
	insert che;

    Test.startTest();
      CaseHistoryCalcBatch btch = new CaseHistoryCalcBatch();
        Database.executeBatch(btch);
    Test.stopTest();
    }

//    @isTest
//    public static void testCalcValues(){
//        Id profIdSU = [SELECT Id FROM Profile LIMIT 1].Id;
//        Id conversationId = Label.ConversationId;
//        Id messagingChannelId = Label.MessagingChannelId;
//        Id messagingEndUserId = Label.MessagingEndUserId;
//        Map<String, List<ConversationParticipant>> conversationParticipantsByConvId = new Map<String, List<ConversationParticipant>>
//
//        List<User> testUsers = [SELECT Id FROM User WHERE ProfileId = :profIdSU AND IsActive = true LIMIT 1];
//
//        User testUser;
//        if(!testUsers.isEmpty()){
//            System.debug('testUsers[0] '+testUsers[0]);
//            testUser = testUsers[0];
//        }
//
//
//
//        Case testCase = new Case(
//        Status = 'Nuevo',
//        Subject = 'Test de Conversación',
//        Description = 'Test',
//        Origin = 'BOT',
//        OwnerId = testUser.Id
//        );
//        insert testCase;
//
//        MessagingSession testSession = new MessagingSession(
//        Status = 'Active',
//        CaseId = testCase.Id,
//        ConversationId = conversationId,
//        MessagingChannelId = messagingChannelId,
//        MessagingEndUserId = messagingEndUserId
//        );
//        insert testSession;
//
//        ConversationEntry testEntry = new ConversationEntry(
//        EntryType = 'Text',
//        ConversationId = conversationId,
//        Seq = 30,
//        EntryTime = Datetime.newInstance(2025,01,29,12,25,06),
//        ActorType = 'Agent'
//        );
//        insert testEntry;
//
//        ConversationEntry testEntry2 = new ConversationEntry(
//        EntryType = 'Text',
//        ConversationId = conversationId,
//        Seq = 31,
//        EntryTime = Datetime.newInstance(2025,01,29,12,24,26),
//        ActorType = 'EndUser'
//        );
//        insert testEntry2;
//
//        Case_History_Enhanced__c che = new Case_History_Enhanced__c(
//            User__c = testUser.Id,
//            Case__c = testCase.Id
//        );
//        insert che;
//
////        conversationParticipantsByConvId.put(conversationId, new List<ConversationParticipant>());
////        conversationParticipantsByConvId.get(conversationId).add(new ConversationParticipant(
////            ConversationId = conversationId,
////            ParticipantDisplayName = 'Guest'
////        ))
//
//
//            Test.startTest();
//            CaseHistoryCalcBatch.calcValues(new List<ConversationEntry> {testEntry,testEntry2}, che);
//            Test.stopTest();
//    }
    
    @isTest
    public static void testUpdateCaseHistory(){
        
        Id profIdSU = [SELECT Id FROM Profile LIMIT 1].Id;
  
    	List<User> testUsers = [SELECT Id FROM User WHERE ProfileId = :profIdSU AND IsActive = true LIMIT 1];
    	User testUser;
    	if(!testUsers.isEmpty()){
        	System.debug('testUsers[0] '+testUsers[0]);
        	testUser = testUsers[0];
    	}
        Case testCase = new Case(
   		 Status = 'Nuevo',
        Subject = 'Test de Conversación',
    	Description = 'Test', 
    	Origin = 'BOT', 
    	OwnerId = testUser.Id    
    	);
        insert testCase;
        Case_History_Enhanced__c che = new Case_History_Enhanced__c(
        Case__c = testCase.Id
        );
		insert che;
        Test.startTest();
        che.User__c = null;
        CaseHistoryCalcBatch.updateCaseHistory(new List<Case_History_Enhanced__c> {che});
        Test.stopTest();
    }
}