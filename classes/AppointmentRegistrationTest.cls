@isTest
private class AppointmentRegistrationTest {
    
    @testSetup
    static void setupTestData() {
        
        List<Account> accEmpresaList = new List<Account>();
        Id rtIdGrupoVasquez = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Vazquez_Group_Company').getRecordTypeId();
        Account empresaUeno = new Account(Name = 'Ueno Bank SA', GroupCompaniesUeno__c = 'UENO_BANK', RecordTypeId = rtIdGrupoVasquez);
        Account empresaUpay = new Account(Name = 'Upay SA', GroupCompaniesUeno__c = 'UPAY', RecordTypeId = rtIdGrupoVasquez);
        accEmpresaList.add(empresaUeno);
        accEmpresaList.add(empresaUpay);
        
        insert accEmpresaList;
        
        List<Account> accList = new List<Account>();
        Id rtIdAccPersonAccount = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account clientePersonaNatural = new Account(FirstName = 'Test FirstName', LastName = 'Test LastName', RecordTypeId = rtIdAccPersonAccount, DocumentNumber__c = '12345678', DocumentType__c = '1');
        accList.add(clientePersonaNatural);
        
        Account accNoCliente = new Account(Name = 'No Cliente');
        accList.add(accNoCliente);
        Id rtIdAccSucursal = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Internal_Company').getRecordTypeId();
        Account sucursalAregua = new Account(Name = 'AreguaTest', RecordTypeId = rtIdAccSucursal, Numero_Oficina__c = 320, ParentId = empresaUeno.Id);
        accList.add(sucursalAregua);
  
        insert accList;
        
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(testUser) {
            List<Group> queues = new List<Group>();
            Group queueAregua = new Group(Name = 'AreguaTest', DeveloperName = 'AreguaTest',  Type = 'Queue');
            queues.add(queueAregua);
            //Cola de casos cerrados (TurneroClosedCases) no se inserta pues ya existe con el mismo DeveloperName
            insert queues;
            
            List<QueuesObject> queueRelationshipList = new List<QueuesObject>();
            QueuesObject queueAreguaCaseRelationship = new QueueSObject(QueueID = queueAregua.id, SobjectType = 'Case');
            queueRelationshipList.add(queueAreguaCaseRelationship);
            QueuesObject queueAreguaAppointmentRelationship = new QueueSObject(QueueID = queueAregua.id, SobjectType = 'Appointment__c');
            queueRelationshipList.add(queueAreguaAppointmentRelationship);
            insert queueRelationshipList;
        }
    }
    
    /**
    * @description Prueba la creación de un caso con estado 'Nuevo'
    */
    @isTest
    static void testQueueAppointmentOpenCase() {
        User testUser = [Select Id, Name, Username FROM User WHERE ProfileId =: Label.ProfileSystemAdminId AND IsActive = true AND Office__c = '320' LIMIT 1];
        Account sucursalAregua = [SELECT Id FROM Account WHERE Numero_Oficina__c = 320];
        system.runAs(testUser){
            Contact userContact = new Contact(
                FirstName = 'Nombre Test',
                LastName = 'Apellido Test',
                UserId__c = testUser.Id,
                AccountId = sucursalAregua.Id
            );
            insert userContact;
            AppointmentRegistration.Request req = new AppointmentRegistration.Request();
            req.accountId = [SELECT Id FROM Account LIMIT 1].Id;
            req.origin = 'Email';
            req.description = 'Test case';
            req.phoneNumber = '999999999';
            req.requirePriority = false;
            req.procedure = 'Tarjetas';
            req.subprocedure = 'Aumento de limite de crédito';
            req.queueable = true;
            req.closedCase = false;
            req.personType = 'Persona';
            req.attentionProfile = 'Experiencia';
            req.company = 'UENO_BANK';
            Test.startTest();
            Map<String,Id> idsMap = AppointmentRegistration.queueAppointment(req);
            Test.stopTest();
            Case insertedCase = [SELECT Status FROM Case WHERE Id = :idsMap.get('case')];
            System.assertEquals('Nuevo', insertedCase.Status, 'El estado del caso no es el esperado');
        }
        
        
    }
    
    /**
    * @description Prueba la creación de un caso con estado 'Cerrado'
    */
    @isTest
    static void testQueueAppointmentClosedCase() {
        User testUser = [Select Id, Name, Username FROM User WHERE ProfileId =: Label.ProfileSystemAdminId AND IsActive = true AND Office__c = '320' LIMIT 1];
        Account sucursalAregua = [SELECT Id FROM Account WHERE Numero_Oficina__c = 320];
        system.runAs(testUser){
            Contact userContact = new Contact(
                FirstName = 'Nombre Test',
                LastName = 'Apellido Test',
                UserId__c = testUser.Id,
                AccountId = sucursalAregua.Id
            );
            insert userContact;
            AppointmentRegistration.Request req = new AppointmentRegistration.Request();
            req.accountId = [SELECT Id FROM Account LIMIT 1].Id;
            req.origin = 'Email';
            req.description = 'Test case';
            req.phoneNumber = '999999999';
            req.requirePriority = false;
            req.procedure = 'Caja';
            req.subprocedure = 'Depósito o extracción menor a 300 billetes';
            req.queueable = false;
            req.closedCase = true;
            req.personType = 'Persona';
            req.attentionProfile = 'TED';
            req.company = 'UENO_BANK';
            Test.startTest();
            Map<String,Id> idsMap = AppointmentRegistration.queueAppointment(req);
            Test.stopTest();
            Case insertedCase = [SELECT Status FROM Case WHERE Id = :idsMap.get('case')];
            System.assertEquals('Cerrado', insertedCase.Status, 'El estado del caso no es el esperado');
        }
    }
    
    
    /**
    * @description Prueba la creación de cita para No Cliente
    */
    @isTest
    static void testQueueAppointmentWithoutAccountId() {
        User testUser = [Select Id, Name, Username FROM User WHERE ProfileId =: Label.ProfileSystemAdminId AND IsActive = true AND Office__c = '320' LIMIT 1];
        Account sucursalAregua = [SELECT Id FROM Account WHERE Numero_Oficina__c = 320];
        Account cuentaNoCliente = [SELECT Id FROM Account WHERE Name = 'No Cliente'];
        system.runAs(testUser){
            Contact userContact = new Contact(
                FirstName = 'Nombre Test',
                LastName = 'Apellido Test',
                UserId__c = testUser.Id,
                AccountId = sucursalAregua.Id
            );
            insert userContact;
            AppointmentRegistration.Request req = new AppointmentRegistration.Request();
            req.accountId = cuentaNoCliente.Id;
            req.origin = 'Email';
            req.description = 'Test case';
            req.phoneNumber = '999999999';
            req.requirePriority = false;
            req.procedure = 'Apertura de cuenta';
            req.subprocedure = 'Problemas con mi registro';
            req.queueable = true;
            req.closedCase = false;
            req.personType = 'Empresa';
            req.attentionProfile = 'Comercial';
            req.company = 'UENO_BANK';
            Test.startTest();
            Map<String,Id> idsMap = AppointmentRegistration.queueAppointment(req);
            Test.stopTest();
            Case insertedCase = [SELECT Status FROM Case WHERE Id = :idsMap.get('case')];
            System.assertEquals('Nuevo', insertedCase.Status, 'El estado del caso no es el esperado');
        }
    }
    

}