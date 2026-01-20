@isTest
public class TwoFactorEmailConfirmationBatchTest {
    @isTest
    static void testExecuteBatchMethod() {
        TwoFactorEmailConfirmationBatch batch = new TwoFactorEmailConfirmationBatch();
        Test.startTest();
            Database.executeBatch(batch);
        Test.stopTest();
    }

    @isTest
    static void testExecuteScheduledMethod() {
        TwoFactorEmailConfirmationBatch schedule = new TwoFactorEmailConfirmationBatch();
        Test.startTest();
            schedule.execute(null);
        Test.stopTest();
    }
}