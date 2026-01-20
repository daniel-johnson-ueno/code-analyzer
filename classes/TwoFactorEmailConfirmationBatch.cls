global class TwoFactorEmailConfirmationBatch implements Database.Batchable<SObject>, Database.Stateful, schedulable {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        if (Test.isRunningTest()) {
            return Database.getQueryLocator([SELECT Id FROM User WHERE Id =: UserInfo.getUserId()]);
        } else {
            // Regular query for production
            return Database.getQueryLocator([
                SELECT Id, UserId
                FROM TwoFactorMethodsInfo
                WHERE HasUserVerifiedEmailAddress = false AND User.IsActive = true
            ]);
        }
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        for (SObject record : scope) {
            Id userId = (Test.isRunningTest()) ? ((User) record).Id : ((TwoFactorMethodsInfo) record).UserId;
            System.UserManagement.sendAsyncEmailConfirmation(userId, null, null, null);
        }
    }

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new TwoFactorEmailConfirmationBatch(), 200);
    }

    public void finish(Database.BatchableContext BC) {}
}