@isTest(SeeAllData=false)
private class BatchHandleCampaignsOverOppsTest {
    @testSetup
    static void testSetup(){
        RecordType rtAccount = [SELECT Id FROM RecordType WHERE DeveloperName='Internal_Company'];
        Account testAcct1 = new Account (
            Name = 'My Test Account',
            RecordTypeId = rtAccount.Id
        );
        Account testAcct2 = new Account (
            Name = 'Office 1',
            RecordTypeId = rtAccount.Id,
            Numero_Oficina__c = 1,
            Type_and_Document_Number__c = '1_001'
        );
        List<Account> lstAccs = new List<Account>{testAcct1,testAcct2};
        insert lstAccs;
        List<Opportunity> lstOpps = new List<Opportunity>();
        for (Integer i=0;i<8;i++) {
            Opportunity opp = new Opportunity(
                Name = 'Opportunity ' + i,
                StageName = 'Nuevo',
                CloseDate = System.today(),
                OfficeNumber__c = '1',
                TypeAndDocumentNumber__c = '1_001',
                ExecutiveEmail__c = UserInfo.getUserEmail()
            );
            lstOpps.add(opp);
        }
        Opportunity opp = new Opportunity(
            Name = 'Opportunity 10',
            StageName = 'Nuevo',
            CloseDate = System.today()
        );
        lstOpps.add(opp);
        insert lstOpps;
    }
    @isTest
    static void testGetAccountWithValidParameters() {
        BatchHandleCampaignsOverOpportunities batch = new BatchHandleCampaignsOverOpportunities();
        Test.startTest();
        Database.executeBatch(batch, 10);
        Test.stopTest();
        List<Opportunity> lstOpps = [SELECT Id, AccountId, Preference_Experience_Center__c FROM Opportunity WHERE OfficeNumber__c = '1' LIMIT 10];
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Office 1' LIMIT 1];
        Assert.areEqual(lstOpps[0].Preference_Experience_Center__c, acc.Id);
        Assert.areEqual(lstOpps[0].AccountId, acc.Id);
    }
}