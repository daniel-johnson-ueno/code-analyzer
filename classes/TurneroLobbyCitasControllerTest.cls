@isTest
private class TurneroLobbyCitasControllerTest {
    
    // Helper method to create test data
    private static void createTestData() {
        
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        
        List<Account> accList = new List<Account>();
        
        Id rtIdAccSucursal = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Internal_Company').getRecordTypeId();
        Account sucursalAregua = new Account(Name = 'Areguá', RecordTypeId = rtIdAccSucursal, Numero_Oficina__c = 320);
        accList.add(sucursalAregua);
        
        insert accList;
        
        Case caseTest = (Case)TestFactoryFramework.createSObject(new Case(), 'TestFactoryFrameworkDefaults.ConsultaCaseDefaults', false);
        caseTest.Origin = 'Web';
        caseTest.Type = 'Reclamo';
        caseTest.Status = 'Nuevo';
        caseTest.AccountId = sucursalAregua.id;
        caseTest.OwnerId = testUser.Id;
        insert caseTest;
        
        
        
        System.runAs(testUser) {
            Id rtContactId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Internal_Contact').getRecordTypeId();
            Contact agent = new Contact(LastName = 'Agente', ExecutiveStatus__c = 'Activo', Skills__c = 'Experiencia', UserId__c = testUser.Id, RecordTypeId = rtContactId, AccountId = sucursalAregua.Id );
            insert agent;

            
            
            List<Group> queues = new List<Group>();
            Group queueAregua = new Group(Name = 'Areguá', Type = 'Queue');
            queues.add(queueAregua);
            insert queues;
            
            List<QueuesObject> queueRelationshipList = new List<QueuesObject>();
            QueuesObject queueAreguaCaseRelationship = new QueueSObject(QueueID = queueAregua.id, SobjectType = 'Case');
            queueRelationshipList.add(queueAreguaCaseRelationship);
            QueuesObject queueAreguaAppointmentRelationship = new QueueSObject(QueueID = queueAregua.id, SobjectType = 'Appointment__c');
            queueRelationshipList.add(queueAreguaAppointmentRelationship);
            insert queueRelationshipList;
            
            Appointment__c testOpenAppointment1 = new Appointment__c(
                AttentionType__c = 'Experiencia', Status__c = 'Ingreso',
            ExperienceCenter__c = sucursalAregua.Id, OwnerId = queueAregua.Id, RegistrationDateTime__c = System.now().addHours(-1), Case__c = caseTest.Id
                );
            
            insert testOpenAppointment1;
            
            PermissionSet per = [ SELECT Id  FROM PermissionSet where name = 'TurneroSupervisor'];
            PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = per.Id, AssigneeId = testUser.id);
            insert psa;
            
            
        }
    }
    
    @isTest
    static void testValidateAssignAppointment() {
        Test.startTest();
        
        createTestData();
        
        
        // Call method directly
        String validationMessage = TurneroLobbyCitasController.validateAsignAppointment();
        
        // Assertions
        System.assertEquals(null, validationMessage, 'Validation should return a message when conditions are not met');
        
        Test.stopTest();
    }
    
    @isTest
    static void getAllbranchesForNotSupervisors() {
        Test.startTest();
        
        createTestData();
        
        // Call method directly
        TurneroLobbyCitasController.LobbyDataWrapper data = TurneroLobbyCitasController.getAllbranchesForSupervisorAndRefreshTime();
        system.debug(data);
        // Assertions
        System.assertNotEquals(null, data, 'return list of branches for the user and the refresh date');
        
        Test.stopTest();
    }
    
    @isTest
    static void assignAppointmentFlow() {
        Test.startTest();
        
        createTestData();
        List<TurneroLobbyCitasController.Requests> idfirstElement = new List<TurneroLobbyCitasController.Requests>();
        TurneroLobbyCitasController.Requests rs = new TurneroLobbyCitasController.Requests();
        Appointment__c targetAppointment = [SELECT Id, OwnerId, Case__c  FROM Appointment__c where Case__c <> null LIMIT 1];
        Case appointmentCase = [SELECT Id, OwnerId, Status FROM Case WHERE Id =: targetAppointment.Case__c WITH USER_MODE LIMIT 1];
        appointmentCase.OwnerId = targetAppointment.ownerId;
        update appointmentCase;

        rs.AppointmentId =targetAppointment.ID;
        idfirstElement.add(rs);
        // Call method directly
        List<TurneroLobbyCitasController.Results> data = TurneroLobbyCitasController.assignAppointmentFlow(idfirstElement);
        system.debug(data);
        // Assertions
        System.assertNotEquals(null, data, 'return list of branches for the user and the refresh date');
        
        Test.stopTest();
    }
    
    @isTest
    static void createDataTableColumns() {
        Test.startTest();
        
        createTestData();
        List<Turnero__mdt> meta = new List<Turnero__mdt>();
        Turnero__mdt md = new Turnero__mdt();
        md.Label = 'Label';
        md.FieldType__c = 'FIELDS';
        md.Field__c = 'Field__c';
        meta.add(md);
        // Call method directly
        String data = TurneroLobbyCitasController.createDataTableColumns(meta);
        system.debug(data);
        // Assertions
        System.assertNotEquals(null, data, 'return list of branches for the user and the refresh date');
        
        Test.stopTest();
    }
    
    
    @isTest
    static void getAppointmentByQueueIdAndSkill() {
        Test.startTest();
        
        createTestData();
        List<Turnero__mdt> meta = new List<Turnero__mdt>();
        Turnero__mdt md = new Turnero__mdt();
        md.Label = 'Label';
        md.FieldType__c = 'FIELDS';
        md.Field__c = 'RegistrationDateTime__c';
        md.FieldOrder__c = 1;
        meta.add(md);
        List<Group> idq = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name = 'Areguá' WITH USER_MODE LIMIT 1];
        String skill = 'Experiencia';
        // Call method directly
        List<Appointment__c> data = TurneroLobbyCitasController.getAppointmentByQueueIdAndSkill(idQ[0].Id,skill,meta);
        system.debug(data);
        // Assertions
        System.assertNotEquals(null, data, 'return list of branches for the user and the refresh date');
        
        Test.stopTest();
    }
    @isTest
    static void appointmentAssignationProcess() {
        Test.startTest();
        
        createTestData();
      
        Appointment__c targetAppointment = [SELECT Id, OwnerId, Case__c  FROM Appointment__c where Case__c <> null LIMIT 1];
        Case appointmentCase = [SELECT Id, OwnerId, Status FROM Case WHERE Id =: targetAppointment.Case__c WITH USER_MODE LIMIT 1];
        appointmentCase.OwnerId = targetAppointment.ownerId;
        update appointmentCase;

        // Call method directly
        Boolean data = TurneroLobbyCitasController.appointmentAssignationProcess(targetAppointment.ownerId,targetAppointment);
        
        // Assertions
        System.assertNotEquals(null, data, 'return list of branches for the user and the refresh date');
        
        Test.stopTest();
    }
    
    @isTest
    static void assignAppointment() {
        Test.startTest();
        
        createTestData();
      
        Appointment__c targetAppointment = [SELECT Id, OwnerId, Case__c  FROM Appointment__c where Case__c <> null LIMIT 1];
        Case appointmentCase = [SELECT Id, OwnerId, Status FROM Case WHERE Id =: targetAppointment.Case__c WITH USER_MODE LIMIT 1];
        appointmentCase.OwnerId = targetAppointment.ownerId;
        update appointmentCase;

        // Call method directly
        TurneroLobbyCitasController.LobbyDataWrapper data = TurneroLobbyCitasController.assignAppointment(targetAppointment.Id);
        
        // Assertions
        System.assertNotEquals(null, data, 'return list of branches for the user and the refresh date');
        
        Test.stopTest();
    }

    @isTest
    static void getLobbyCitasData() {
        Test.startTest();
        
        createTestData();
      
        Appointment__c targetAppointment = [SELECT Id, OwnerId, Case__c  FROM Appointment__c where Case__c <> null LIMIT 1];
        Case appointmentCase = [SELECT Id, OwnerId, Status FROM Case WHERE Id =: targetAppointment.Case__c WITH USER_MODE LIMIT 1];
        appointmentCase.OwnerId = targetAppointment.ownerId;
        update appointmentCase;

        // Call method directly
        TurneroLobbyCitasController.LobbyDataWrapper data = TurneroLobbyCitasController.getLobbyCitasData('Areguá');
        
        // Assertions
        System.assertNotEquals(null, data, 'return list of branches for the user and the refresh date');
        
        Test.stopTest();
    }


    
}