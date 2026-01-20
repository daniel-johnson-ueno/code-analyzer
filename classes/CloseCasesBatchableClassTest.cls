@isTest
private class CloseCasesBatchableClassTest {

    @isTest
    static void closeCasesTest() {
        List<Case> testCases = new List<Case>();

        Account account = new Account(
            Name = 'Test Account '
        );

        insert account;

        for (Integer i = 0; i < 5; i++) {
            testCases.add(new Case(
                ClientProduct__c = 'ClientProduct ' + i,
                ClientSubproduct__c = 'ClientSubproduct ' + i,
                AccountId = account.Id,
                Status = 'Nuevo',
                Origin = 'Teléfono'
            ));
        }

        insert testCases;

        Test.startTest();
        CloseCasesBatchableClass closeCasesBatchableClass = new CloseCasesBatchableClass();
        Database.executeBatch(closeCasesBatchableClass, 10);
        Test.stopTest();
    }
}