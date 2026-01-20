/**
 * @description       : 
 * @author            : Noe Vasquez
 * @group             : 
 * @last modified on  : 06-18-2025
 * @last modified by  : Noe Vasquez
**/
@IsTest
public class CloseExpiredCampaignMembersBatchTest {

    @testSetup
    static void setupTestData() {
        Account acct = new Account(Name = 'Cuenta de Prueba');
        acct = (Account)TestFactoryFramework.createSObject(acct, 'TestFactoryFrameworkDefaults.InternalCompanyAccountDefaults', true);

        Contact contacto1 = new Contact(FirstName = 'Juan', LastName = 'Pérez', AccountId = acct.Id);
        contacto1 = (Contact)TestFactoryFramework.createSObject(contacto1, true);

        Contact contacto2 = new Contact(FirstName = 'Ana', LastName = 'Gómez', AccountId = acct.Id);
        contacto2 = (Contact)TestFactoryFramework.createSObject(contacto2, true);

        Campaign camp = new Campaign(Name = 'Campaña Prueba', IsActive = true);
        camp = (Campaign)TestFactoryFramework.createSObject(camp, true);

        List<CampaignMemberStatus> statuses = new List<CampaignMemberStatus>{
            new CampaignMemberStatus(CampaignId = camp.Id, Label = 'Vencido', HasResponded = false, IsDefault = false),
            new CampaignMemberStatus(CampaignId = camp.Id, Label = 'Pendiente', HasResponded = false, IsDefault = false)
        };
        for (CampaignMemberStatus status : statuses) {
            TestFactoryFramework.createSObject(status, true);
        }

        CampaignMember vencido = new CampaignMember(
            CampaignId = camp.Id,
            Status = 'Pendiente',
            DueDate__c = Date.today().addDays(-1),
            ContactId = contacto1.Id
        );

        CampaignMember vigente = new CampaignMember(
            CampaignId = camp.Id,
            Status = 'Sent',
            DueDate__c = Date.today().addDays(5),
            ContactId = contacto2.Id
        );

        TestFactoryFramework.createSObject(vencido, true);
        TestFactoryFramework.createSObject(vigente, true);
    }

    @isTest
    static void testBatchExecution() {
        Test.startTest();
        Database.executeBatch(new CloseExpiredCampaignMembersBatch(), 100);
        Test.stopTest();

        List<CampaignMember> updated = [SELECT Status, DueDate__c FROM CampaignMember];

        for (CampaignMember cm : updated) {
            if (cm.DueDate__c < Date.today()) {
                Assert.areEqual('Vencido', cm.Status, 'Debe estar marcado como Vencido');

            } else {
                Assert.areEqual('Sent', cm.Status, 'No debe cambiar el status');
            }
        }
    }

    @isTest
    static void testSchedulableExecution() {
        Test.startTest();
        String jobId = System.schedule(
            'Test Schedulable',
            '0 0 1 * * ?',
            new CloseExpiredCampaignMembersBatch()
        );
        Test.stopTest();

        Assert.areNotEqual(null, jobId, 'El Job ID no debe ser null');
    }

    @isTest
    static void testErrorLogging() {
        CampaignMember cm = [SELECT Id, Status FROM CampaignMember LIMIT 1];
        cm.CurrencyIsoCode = 'MXN'; // fuerza error si no es válido en tu org

        Database.SaveResult[] results = Database.update(new List<CampaignMember>{ cm }, false);

        Assert.isTrue(!results[0].isSuccess(), 'Se esperaba un fallo en el update');

        Database.Error err = results[0].getErrors()[0];

        Test.startTest();
        new CloseExpiredCampaignMembersBatch().handleError(new DmlException(err.getMessage()), cm.Id);
        Test.stopTest();
    }
}