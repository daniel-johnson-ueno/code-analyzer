/**
 * @name               : turneroTurnoSolicitudControllerTest
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 10-11-2025
 * @modification date  : 10-03-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Clase test de turneroTurnoSolicitudController
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   10-03-2025   Alvaro Gonzales Lapponi   Initial Version
**/
@isTest
public class turneroTurnoSolicitudControllerTest {
    
    static final String APPOINTMENTCATEGORY_TURNERO1_NAME   = 'Cita Turnero';
    static final String WAIITLIST_TURNERO_NAME              = 'Lista Espera Areguá';

    static final string STATUS_CODE_INTERNAL_ERROR          = '-2';
    static final String STATUS_CODE_EXTERNAL_ERROR          = '-1';
    static final string STATUS_CODE_SUCCESS                 = '0'; 
    
    @testSetup
    public static void dataSetup(){
        
        
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
            Group queueAregua = new Group(Name = 'AreguaTest', DeveloperName = 'AreguaTest', Type = 'Queue');
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
    
    @isTest
    public static void fetchClienteTestEsClienteOk(){        
        String mock = '[{"firstName":"Pedro","lastName":"Perez","cedulaIdentidad":"","phone":"091234567"}]';
        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok', mock));
        Test.startTest();
        turneroTurnoSolicitudController.ResponseWrapperCliente response = turneroTurnoSolicitudController.fetchCliente('1','12345678');
        Test.stopTest();
        system.AssertEquals(STATUS_CODE_SUCCESS,response.statusCode,'Status code incorrecto');
    }
    
    @isTest
    public static void fetchClienteTestNoEsClientePersonaOk(){
        String mock = '[{"firstName":"Pedro","lastName":"Perez","cedulaIdentidad":"","phone":"091234567"}]';
        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok', mock));
        Test.startTest();
        turneroTurnoSolicitudController.ResponseWrapperCliente response = turneroTurnoSolicitudController.fetchCliente('1','0000ABCD');
        Test.stopTest();
        system.AssertEquals(STATUS_CODE_SUCCESS,response.statusCode,'Status code incorrecto');
    }
    
    @isTest
    public static void fetchClienteTestNoEsClienteEmpresaOk(){
        String mock = '[{"firstName":"Empresa Test","ruc":"102030","phone":"091234567"}]';
        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok', mock));
        Test.startTest();
        turneroTurnoSolicitudController.ResponseWrapperCliente response = turneroTurnoSolicitudController.fetchCliente('6','102030');
        Test.stopTest();
        system.AssertEquals(STATUS_CODE_SUCCESS,response.statusCode,'Status code incorrecto');
    }
    
    @isTest
    public static void fetchClienteTestException(){
        turneroTurnoSolicitudController.SHOULD_THROW_EXCEPTION = true;
        Test.startTest();
        turneroTurnoSolicitudController.ResponseWrapperCliente response = turneroTurnoSolicitudController.fetchCliente('1','0000ABCD');
        Test.stopTest();
        system.AssertEquals(STATUS_CODE_INTERNAL_ERROR,response.statusCode,'Status code incorrecto');
    }
    
    @isTest
    public static void checkInTestOpenCaseOk(){
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
            
            turneroTurnoSolicitudController.AppointmentData data = new turneroTurnoSolicitudController.AppointmentData();
            procedureAssignmentUtils.AppointmentConditions conditions = new procedureAssignmentUtils.AppointmentConditions();
            data.accountId = [SELECT Id FROM Account LIMIT 1].Id;
            data.foto = '';
            data.tramite = 'Tarjetas';
            data.subtramite = 'Solicitud de tarjeta';
            data.requierePrioridad = false;
            conditions.closedCase = false;
            conditions.queueable = true;
            conditions.queue = 'Experiencia';
            conditions.company = 'UENO_BANK';
            
            Test.startTest();
            turneroTurnoSolicitudController.ResponseWrapperAppointment response = turneroTurnoSolicitudController.checkIn(data, conditions);
            Test.stopTest();
            system.AssertEquals(STATUS_CODE_SUCCESS,response.statusCode,'Status code incorrecto');
        }

    }
    
    @isTest
    public static void checkInTestClosedCaseOk(){
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
            turneroTurnoSolicitudController.AppointmentData data = new turneroTurnoSolicitudController.AppointmentData();
            procedureAssignmentUtils.AppointmentConditions conditions = new procedureAssignmentUtils.AppointmentConditions();
            data.accountId = [SELECT Id FROM Account LIMIT 1].Id;
            data.foto = '';
            data.tipoRepresentante = 'Persona';
            data.tramite = 'Tarjetas';
            data.subtramite = 'Solicitud de tarjeta';
            data.requierePrioridad = false;
            conditions.closedCase = true;
            conditions.queueable = true;
            conditions.queue = 'Experiencia';
            conditions.company = 'UENO_BANK';
            
            Test.startTest();
            turneroTurnoSolicitudController.ResponseWrapperAppointment response = turneroTurnoSolicitudController.checkIn(data, conditions);
            Test.stopTest();
            system.AssertEquals(STATUS_CODE_SUCCESS,response.statusCode,'Status code incorrecto');
        }

    }
    
    
    @isTest
    public static void checkInTestException(){
        User testUser = [Select Id, Name, Username FROM User WHERE ProfileId =: Label.ProfileSystemAdminId AND IsActive = true AND Office__c = '320' LIMIT 1];
        Account sucursalAregua = [SELECT Id FROM Account WHERE Numero_Oficina__c = 320];
        system.runAs(testUser){
            turneroTurnoSolicitudController.SHOULD_THROW_EXCEPTION = true;
            turneroTurnoSolicitudController.AppointmentData data = new turneroTurnoSolicitudController.AppointmentData();
            procedureAssignmentUtils.AppointmentConditions conditions = new procedureAssignmentUtils.AppointmentConditions();
            Test.startTest();
            turneroTurnoSolicitudController.ResponseWrapperAppointment response = turneroTurnoSolicitudController.checkIn(data, conditions);
            Test.stopTest();
            system.AssertEquals(STATUS_CODE_INTERNAL_ERROR,response.statusCode,'Status code incorrecto');
        }

    }
    
    
    @isTest
    public static void sendSMSTestOk(){
        String mock = '{"status": "[TWILLIO] Message sent to +59500000000"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok', mock));
        Test.startTest();
        turneroTurnoSolicitudController.ResponseWrapper response = turneroTurnoSolicitudController.sendSMS('+59500000000','SMS testing message');
        Test.stopTest();
        system.AssertEquals(STATUS_CODE_SUCCESS,response.statusCode,'Status code incorrecto');
    }
    
    @isTest
    public static void sendSMSTestExceptionExternal(){
        String mock = 'invalid';
        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok', mock));
        Test.startTest();
        turneroTurnoSolicitudController.ResponseWrapper response = turneroTurnoSolicitudController.sendSMS('+59500000000','SMS testing message');
        Test.stopTest();
        system.AssertEquals(STATUS_CODE_EXTERNAL_ERROR,response.statusCode,'Status code incorrecto');
    }
    
    @isTest
    public static void sendSMSTestExceptionInternal(){
        String mock = 'invalid';
        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok', mock));
        turneroTurnoSolicitudController.SHOULD_THROW_EXCEPTION = true;
        Test.startTest();
        turneroTurnoSolicitudController.ResponseWrapper response = turneroTurnoSolicitudController.sendSMS('+59500000000','SMS testing message');
        Test.stopTest();
        system.AssertEquals(STATUS_CODE_INTERNAL_ERROR,response.statusCode,'Status code incorrecto');
    }


}