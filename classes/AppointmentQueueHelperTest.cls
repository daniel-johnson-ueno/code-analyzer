/**
 * @name               : AppointmentQueueHelperTest
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 18-03-2025
 * @modification date  : 18-03-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Clase test de AppointmentQueueHelper
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   18-03-2025   Alvaro Gonzales Lapponi   Initial Version
**/
@isTest
private class AppointmentQueueHelperTest {
    
    /**
    * @description Método para insertar data de prueba
    * @author Alvaro Gonzales Lapponi | 18-03-2025 
    **/ 
    @testSetup
    static void setupTestData() {
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        
        List<Account> accList = new List<Account>();
        Id rtIdAccSucursal = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Internal_Company').getRecordTypeId();
        Account sucursalAregua = new Account(Name = 'Areguá', RecordTypeId = rtIdAccSucursal, Numero_Oficina__c = 320);       
        accList.add(sucursalAregua);
        Id rtIdAccPersonAccount = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account clientePersonaNatural = new Account(FirstName = 'Test FirstName', LastName = 'Test LastName', RecordTypeId = rtIdAccPersonAccount, DocumentNumber__c = '12345678', DocumentType__c = '1');
        accList.add(clientePersonaNatural);
        insert accList;
        
        // Crear caso de prueba
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
    * @description Método test para casuística de cita finalizada
    * @author Alvaro Gonzales Lapponi | 18-03-2025 
    **/ 
    @isTest
    static void testGetAppointmentWaitingInfo_FinalizedStatus() {
        Appointment__c testAppointment = [SELECT Id FROM Appointment__c WHERE Status__c = 'Finalizado' LIMIT 1];

        Test.startTest();
        AppointmentQueueHelper.WaitingInfoWrapper result = AppointmentQueueHelper.getAppointmentWaitingInfo(testAppointment.Id);
        Test.stopTest();

        System.assertEquals('Finalizado', result.status, 'La cita finalizada debería devolver su estado.');
    }

    /**
    * @description Método test para casuística sin Agentes disponibles
    * @author Alvaro Gonzales Lapponi | 18-03-2025 
    **/ 
    @isTest
    static void testGetAppointmentWaitingInfo_NoAgentsAvailable() {
        
        //Obtener cuentas (Sucursal Areguá y cliente)
        Account sucursal = [SELECT Id FROM Account WHERE Numero_Oficina__c = 320];
        Account cliente = [SELECT Id FROM Account WHERE DocumentNumber__c = '12345678'];
        
        //Obtener caso
        Case caso = [SELECT Id FROM Case LIMIT 1];
        
        // Agentes disponibles
        AppointmentQueueHelper.AVAILABLE_AGENTS_TEST = 0;
        // Insertar citas previas
        Appointment__c targetAppointment = new Appointment__c(
            AttentionType__c = 'Experiencia', Status__c = 'Llamada', Account__c = cliente.Id, Case__c = caso.Id,
            ExperienceCenter__c = sucursal.Id, RegistrationDateTime__c = System.now().addMinutes(-30)
        );
        insert targetAppointment;

        Test.startTest();
        AppointmentQueueHelper.WaitingInfoWrapper result = AppointmentQueueHelper.getAppointmentWaitingInfo(targetAppointment.Id);
        Test.stopTest();

        System.assertEquals(-1, result.numberOfPeopleBefore, 'Si no hay agentes, debería devolver -1.');
    }

    /**
    * @description Método test para casuística de citas previas y con Agentes Disponibles
    * @author Alvaro Gonzales Lapponi | 18-03-2025 
    **/ 
    @isTest
    static void testGetAppointmentWaitingInfo_WithAgentsAndPreviousAppointments() {
        
        //Obtener cuentas (Sucursal Areguá y cliente)
        Account sucursal = [SELECT Id FROM Account WHERE Numero_Oficina__c = 320];
        Account cliente = [SELECT Id FROM Account WHERE DocumentNumber__c = '12345678'];
        
        //Obtener caso
        Case caso = [SELECT Id FROM Case LIMIT 1];
        
        // Agentes disponibles
        AppointmentQueueHelper.AVAILABLE_AGENTS_TEST = 3;
        // Insertar citas previas
        Appointment__c targetAppointment = new Appointment__c(
            AttentionType__c = 'Experiencia', Status__c = 'Llamada', Account__c = cliente.Id, Case__c = caso.Id,
            ExperienceCenter__c = sucursal.Id, RegistrationDateTime__c = System.now().addMinutes(-30)
        );
        insert targetAppointment;

		system.debug('##### '+AppointmentQueueHelper.AVAILABLE_AGENTS_TEST);
        Test.startTest();
        AppointmentQueueHelper.WaitingInfoWrapper result = AppointmentQueueHelper.getAppointmentWaitingInfo(targetAppointment.Id);
        Test.stopTest();

        System.assert(result.numberOfPeopleBefore > 0, 'Debe haber al menos una persona antes en la cola.');
        System.assert(result.estimatedWaitingTime > 0, 'El tiempo estimado de espera debe ser mayor a 0.');
    }
}