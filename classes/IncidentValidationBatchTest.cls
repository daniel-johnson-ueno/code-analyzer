@isTest
public class IncidentValidationBatchTest {

    @TestSetup static void setup() {

        Account testPersonAccount = (Account)TestFactoryFramework.createSObject(new Account(), 'TestFactoryFrameworkDefaults.InternalCompanyAccountDefaults', false);
        String accountNameIM = System.label.accountNameIM;
        testPersonAccount.Name = accountNameIM;
        insert testPersonAccount;
        Incident inc = new Incident();
        inc.Tipo__c = 'Ahorro programado';
        inc.Motivo__c = 'Creación';
        inc.Origen__c = 'Casos';
        inc.Priority = 'Baja';
        inc.Status = 'Nuevo';
        inc.Subject = 'Test test';
        inc.Description = 'Test';
        inc.Vazquez_Group_Company__c = 'UENO_BANK';
        inc.Date_Status_In_Validation__c = Datetime.now();
        insert inc;        
    }

    @isTest
    public static void testIncidentValidationBatch() {
        Incident inc = [SELECT Id, status, Date_Status_In_Validation__c FROM Incident WHERE Subject = 'Test test' LIMIT 1];
        inc.Date_Status_In_Validation__c = Datetime.now().addHours(-50);
        update inc;
        Test.startTest();
            IncidentValidationBatch b = new IncidentValidationBatch();
            Database.executeBatch(b);
        Test.stopTest();
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob LIMIT 1];
        Assert.areEqual ('Completed',  a.Status, 'Job completed with no errors');
        Incident incident = [SELECT Id, status, Date_Status_In_Validation__c FROM Incident WHERE Subject = 'Test test' LIMIT 1];
        Assert.areEqual ('Cerrado',  incident.Status, 'Status should be Cerrado');
    }

    @isTest
    public static void testScheduleableBatch() {
        IncidentValidationBatch schedulable = new IncidentValidationBatch();
        Test.startTest();        
            schedulable.execute(null);
        Test.stopTest();
        System.assertNotEquals(null, schedulable, 'Schedulable is not null');
    }

}