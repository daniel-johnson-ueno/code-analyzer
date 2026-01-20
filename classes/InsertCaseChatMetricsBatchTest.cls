@isTest
private class InsertCaseChatMetricsBatchTest {

   @isTest
    private static void testBatch() {
     
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
        Status = 'Ended',
        CaseId = testCase.Id,
        ConversationId = conversationId,
        MessagingChannelId = messagingChannelId,
        MessagingEndUserId = messagingEndUserId,
        EndTime = Datetime.now().addHours(-1).addMinutes(-2)
        );
        insert testSession;

       ConversationEntry testEntry5 = new ConversationEntry(
               EntryType = 'Text',
               ConversationId = conversationId,
               Seq = 29,
               EntryTime = Datetime.newInstance(2025,01,29,12,23,26),
               ActorType = 'System',
               ActorId = testUser.Id
       );
       insert testEntry5;

       ConversationEntry testEntry2 = new ConversationEntry(
               EntryType = 'Text',
               ConversationId = conversationId,
               Seq = 30,
               EntryTime = Datetime.newInstance(2025,01,29,12,24,26),
               ActorType = 'EndUser',
               ActorId = testUser.Id
       );
       insert testEntry2;

        ConversationEntry testEntry = new ConversationEntry(
        EntryType = 'Text',
        ConversationId = conversationId,
        Seq = 31,
        EntryTime = Datetime.newInstance(2025,01,29,12,25,06),
        ActorType = 'Agent',
        ActorId = testUser.Id
        );
        insert testEntry;

       ConversationEntry testEntry4 = new ConversationEntry(
               EntryType = 'Text',
               ConversationId = conversationId,
               Seq = 32,
               EntryTime = Datetime.newInstance(2025,01,29,12,26,26),
               ActorType = 'EndUser',
               ActorId = testUser.Id
       );
       insert testEntry4;

       ConversationEntry testEntry3 = new ConversationEntry(
               EntryType = 'Text',
               ConversationId = conversationId,
               Seq = 33,
               EntryTime = Datetime.newInstance(2025,01,29,12,27,06),
               ActorType = 'Agent',
               ActorId = testUser.Id
       );
       insert testEntry3;

       ConversationEntry testEntry6 = new ConversationEntry(
               EntryType = 'Text',
               ConversationId = conversationId,
               Seq = 34,
               EntryTime = Datetime.newInstance(2025,01,29,12,27,26),
               ActorType = 'System',
               ActorId = testUser.Id
       );
       insert testEntry6;

        Test.startTest();
        Database.executeBatch(new InsertCaseChatMetricsBatch(), 1);
        Test.stopTest();
    }
}