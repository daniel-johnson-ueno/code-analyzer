/**
 * @name               : turneroTurnoConsultaControllerTest
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 18-03-2025
 * @modification date  : 18-03-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Clase test de turneroTurnoConsultaController
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   18-03-2025   Alvaro Gonzales Lapponi   Initial Version
**/
@isTest
public with sharing class turneroTurnoConsultaControllerTest {
    
    static final string STATUS_CODE_SUCCESS                 = '0'; 
    static final string STATUS_CODE_INTERNAL_ERROR          = '-2';
    
    /**
    * @description Método para insertar data de prueba
    * @author Alvaro Gonzales Lapponi | 18-03-2025 
    **/ 
    @testSetup
    static void setupTestData() {
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        
        // Crear cuentas de prueba
        List<Account> accEmpresaList = new List<Account>();
        Id rtIdGrupoVasquez = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Vazquez_Group_Company').getRecordTypeId();
        Account empresaUeno = new Account(Name = 'Ueno Bank SA', GroupCompaniesUeno__c = 'UENO_BANK', RecordTypeId = rtIdGrupoVasquez);
        accEmpresaList.add(empresaUeno);
        
        insert accEmpresaList;
        
        List<Account> accList = new List<Account>();
        Id rtIdAccPersonAccount = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account clientePersonaNatural = new Account(FirstName = 'Test FirstName', LastName = 'Test LastName', RecordTypeId = rtIdAccPersonAccount, DocumentNumber__c = '12345678', DocumentType__c = '1');
        accList.add(clientePersonaNatural);
        
        Id rtIdAccSucursal = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Internal_Company').getRecordTypeId();
        Account sucursalAregua = new Account(Name = 'AreguaTest', RecordTypeId = rtIdAccSucursal, Numero_Oficina__c = 320, ParentId = empresaUeno.Id);
        accList.add(sucursalAregua);
  
        insert accList;
        
        // Crear un caso de prueba
        Case caso = new Case();
        caso.AccountId = clientePersonaNatural.Id;
        caso.Status = 'Nuevo';
        caso.Origin = 'Turnero';
        caso.DocumentType__c = 'CEDULA DE IDENTIDAD PARAGUAYA';
        caso.DocumentNumber__c = '12345678';
        caso.CustomerServiceCenter__c = sucursalAregua.Name;
        caso.ClientProduct__c = 'Tarjetas';
        caso.ClientSubproduct__c = 'Solicitud de tarjeta';
        caso.ROTDerivation__c = true;
		caso.RecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Consulta').getRecordTypeId();
        insert caso;
        
        // Crear una cita de prueba
        List<Appointment__c> appointments = new List<Appointment__c>();
        Appointment__c testOpenAppointment = new Appointment__c(
            AttentionType__c = 'Experiencia', Status__c = 'Ingreso', Case__c = caso.Id,
            ExperienceCenter__c = sucursalAregua.Id, OwnerId = testUser.Id, RegistrationDateTime__c = System.now().addHours(-1)
        );
        Appointment__c testClosedAppointment = new Appointment__c(
            AttentionType__c = 'Experiencia', Status__c = 'Finalizado', Case__c = caso.Id,
            StarDateTime__c = System.now().addHours(-2), EndDateTime__c = System.now().addHours(-1),
            ExperienceCenter__c = sucursalAregua.Id, OwnerId = UserInfo.getUserId(), RegistrationDateTime__c = System.now().addHours(-3)
        );
        appointments.add(testOpenAppointment);
        appointments.add(testClosedAppointment);
        insert appointments;
    }
    
    /**
    * @description Método test exitoso para obtener datos de espera - casuística de citas previas y con Agentes Disponibles
    * @author Alvaro Gonzales Lapponi | 18-03-2025 
    **/ 
    @isTest
    static void testGetPositionOk() {
        // Insertar agentes disponibles
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        Case caso = [SELECT Id FROM Case LIMIT 1];
        Account sucursal = [SELECT Id FROM Account WHERE Numero_Oficina__c = 320];
        Id rtContactId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Internal_Contact').getRecordTypeId();
        Contact agent = new Contact(LastName = 'Agente', ExecutiveStatus__c = 'Activo', Skills__c = 'Experiencia', UserId__c = testUser.Id, RecordTypeId = rtContactId, AccountId = sucursal.Id );
        insert agent;
        
        Appointment__c targetAppointment = new Appointment__c(
            AttentionType__c = 'Experiencia', Status__c = 'Llamada', Case__c = caso.Id,
            ExperienceCenter__c = sucursal.Id, RegistrationDateTime__c = System.now().addMinutes(-30)
        );
        insert targetAppointment;

        Test.startTest();
        turneroTurnoConsultaController.ResponsePositionWrapper response = turneroTurnoConsultaController.getPosition(targetAppointment.Id);
        Test.stopTest();

        System.assertEquals(STATUS_CODE_SUCCESS, response.statusCode, 'Status Code incorrecto');
        System.assert(response.positionData.personasAntes > 0, 'Debe haber al menos una persona antes en la cola.');
        System.assert(response.positionData.tiempoRestanteMinutos > 0, 'El tiempo estimado de espera debe ser mayor a 0.');
    }
    
    /**
    * @description Método test para obtener datos de espera - Exception
    * @author Alvaro Gonzales Lapponi | 18-03-2025 
    **/ 
    @isTest
    static void testGetPositionException() {
        turneroTurnoConsultaController.SHOULD_THROW_EXCEPTION = true;
        // Insertar agentes disponibles
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        Case caso = [SELECT Id FROM Case LIMIT 1];
        Account sucursal = [SELECT Id FROM Account WHERE Numero_Oficina__c = 320];
        Id rtContactId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Internal_Contact').getRecordTypeId();
        Contact agent = new Contact(LastName = 'Agente', ExecutiveStatus__c = 'Activo', Skills__c = 'Experiencia', UserId__c = testUser.Id, RecordTypeId = rtContactId, AccountId = sucursal.Id );
        insert agent;
        
        Appointment__c targetAppointment = new Appointment__c(
            AttentionType__c = 'Experiencia', Status__c = 'Llamada', Case__c = caso.Id,
            ExperienceCenter__c = sucursal.Id, RegistrationDateTime__c = System.now().addMinutes(-30)
        );
        insert targetAppointment;

        Test.startTest();
        turneroTurnoConsultaController.ResponsePositionWrapper response = turneroTurnoConsultaController.getPosition(targetAppointment.Id);
        Test.stopTest();

        System.assertEquals(STATUS_CODE_INTERNAL_ERROR, response.statusCode, 'Status Code incorrecto');
    }
    
    /**
    * @description Método test exitoso para cancelar cita
    * @author Alvaro Gonzales Lapponi | 18-03-2025 
    **/ 
    @isTest
    static void testCancelAppointmentOk() {
        
        Appointment__c testAppointment = [SELECT Id FROM Appointment__c WHERE Status__c = 'Ingreso' LIMIT 1];

        Test.startTest();
        turneroTurnoConsultaController.ResponseWrapper response = turneroTurnoConsultaController.cancelAppointment(testAppointment.Id);
        Test.stopTest();

        System.assertEquals(STATUS_CODE_SUCCESS, response.statusCode, 'Status Code incorrecto');
    }
    
    /**
    * @description Método test para cancelar cita - Exception
    * @author Alvaro Gonzales Lapponi | 18-03-2025 
    **/ 
    @isTest
    static void testCancelAppointmentException() {
        
        turneroTurnoConsultaController.SHOULD_THROW_EXCEPTION = true;
        Appointment__c testAppointment = [SELECT Id FROM Appointment__c WHERE Status__c = 'Ingreso' LIMIT 1];

        Test.startTest();
        turneroTurnoConsultaController.ResponseWrapper response = turneroTurnoConsultaController.cancelAppointment(testAppointment.Id);
        turneroTurnoConsultaActualizacionHelper.getTurneroAvailablePresenceUsers();
        Test.stopTest();

        System.assertEquals(STATUS_CODE_INTERNAL_ERROR, response.statusCode, 'Status Code incorrecto');
    }
    
    /**
    * @description Método test para obtener tiempo de refresco
    * @author Alvaro Gonzales Lapponi | 18-03-2025 
    **/ 
    @isTest
    static void testGetRefreshPeriod() {
        
        Appointment__c testAppointment = [SELECT Id FROM Appointment__c WHERE Status__c = 'Ingreso' LIMIT 1];

        Test.startTest();
        Integer refreshPeriod = turneroTurnoConsultaController.getRefreshPeriod();
        Test.stopTest();

        System.assertEquals(true, refreshPeriod > 0 , 'El tiempo de refresco debe ser mayor a cero');
    }


}