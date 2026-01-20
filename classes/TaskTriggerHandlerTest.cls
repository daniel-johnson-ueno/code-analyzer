@isTest
public class TaskTriggerHandlerTest {
    @testSetup
    static void setupTestData() {
        
        Contact con = new Contact(
            FirstName = 'FirstNameTest',
            LastName = 'LastNameTest',
            Skills__c = 'Producto'
        );
        insert con;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Asignación',
            CloseDate = Date.today(),
            RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Onboarding' LIMIT 1].Id,
            CompanyType__c = 'EAS'
        );
        insert opp;
    }

    @isTest
    static void testHandleAfterUpdate(){
        RecordType rtTraining = [SELECT Id FROM RecordType WHERE DeveloperName = :Label.NameRecordTypeTaskTraining];

        Contact con = new Contact(
            FirstName = 'FirstNameTest',
            LastName = 'LastNameTest',
            Skills__c = 'Producto'
        );
        insert con;

        Task task = new Task(
            RecordTypeId = rtTraining.Id,
            WhoId =  con.Id,
            Skills__c = 'Soft skills'
        );
        insert task;

        Test.startTest();
        Task taskToUpdate = [SELECT Id, Status, PercentResults__c FROM Task LIMIT 1];
        taskToUpdate.Status =  'Completed';
        taskToUpdate.PercentResults__c =  90;
        update taskToUpdate;
        Test.stopTest();

        Contact updatedTContact = [SELECT Id, Skills__c FROM Contact LIMIT 1];

        Assert.areEqual('Producto', updatedTContact.Skills__c, 'No se actualiza correctamente el contacto.');

    }
     @isTest
    static void testSetStartDate() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Task task = new Task(
            WhatId = opp.Id,
            Status = 'Devuelto'
        );
        insert task;
        
        Test.startTest();
        TaskTriggerHandler handler = new TaskTriggerHandler();
        handler.setStartDate([SELECT Id, WhatId, Status FROM Task]);
        Test.stopTest();
        
        Task updatedTask = [SELECT StartDateTime__c FROM Task WHERE Id = :task.Id];
        System.assertNotEquals(null, updatedTask.StartDateTime__c, 'StartDateTime__c no fue actualizado correctamente.');
    }
    
    @isTest
    static void testCalculateTaskTime() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Task task = new Task(
            WhatId = opp.Id,
            Status = 'Open',
            StartDateTime__c = Datetime.now().addHours(-5) 
        );
        insert task;
        
        Test.startTest();
        TaskTriggerHandler handler = new TaskTriggerHandler();
        handler.calculateTaskTime([SELECT Id, WhatId, Status, StartDateTime__c FROM Task]);
        Test.stopTest();
        
        Task updatedTask = [SELECT Time_in_Hours__c, Time_in_Days__c FROM Task WHERE Id = :task.Id];
        System.assert(updatedTask.Time_in_Hours__c > 0, 'No se calculó correctamente el tiempo en horas.');
        System.assert(updatedTask.Time_in_Days__c > 0, 'No se calculó correctamente el tiempo en días.');
    }
}