/**
 * @name               : rotVideollamadaSolicitudControllerTest
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 10-03-2025
 * @modification date  : 10-03-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Clase test de rotVideollamadaSolicitudController
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   10-03-2025   Alvaro Gonzales Lapponi   Initial Version
**/
@isTest
public with sharing class rotVideollamadaSolicitudControllerTest {

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
        
        Id rtIdAccSucursal = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Internal_Company').getRecordTypeId();
        Account sucursalAregua = new Account(Name = 'AreguaTest', RecordTypeId = rtIdAccSucursal, Numero_Oficina__c = 320, ParentId = empresaUeno.Id);
        accList.add(sucursalAregua);
  
        insert accList;
        

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

        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        
        System.runAs(testUser) {
            List<Group> queues = new List<Group>();
            Group queueAregua = new Group(Name = 'AreguaTest', Type = 'Queue');
            queues.add(queueAregua);
            Group queueDefault = new Group(Name = 'Turnero Casos Cerrados', Type = 'Queue');
            queues.add(queueDefault);
            insert queues;
            
            List<QueuesObject> queueRelationshipList = new List<QueuesObject>();
            QueuesObject queueAreguaCaseRelationship = new QueueSObject(QueueID = queueAregua.id, SobjectType = 'Case');
            queueRelationshipList.add(queueAreguaCaseRelationship);
            QueuesObject queueDefaultCaseRelationship = new QueueSObject(QueueID = queueDefault.id, SobjectType = 'Case');
            queueRelationshipList.add(queueDefaultCaseRelationship);
            insert queueRelationshipList;
        }
        
    }
    
    @isTest
    public static void fetchClienteTestSiEsClienteOk() {
        User testUser = [Select Id, Name, Username FROM User WHERE ProfileId =: Label.ProfileSystemAdminId AND IsActive = true AND Office__c = '320' LIMIT 1];
        system.runAs(testUser){
            Test.startTest();
            rotVideollamadaSolicitudController.ResponseWrapperCliente response = rotVideollamadaSolicitudController.fetchCliente('1','12345678');
            system.debug(response.message);
            Test.stopTest();
            system.AssertEquals(STATUS_CODE_SUCCESS,response.statusCode,'Status code incorrecto');
        }
        
    }

    @isTest
    public static void fetchClienteTestNoEsClienteOk() {
        User testUser = [Select Id, Name, Username FROM User WHERE ProfileId =: Label.ProfileSystemAdminId AND IsActive = true AND Office__c = '320' LIMIT 1];
        system.runAs(testUser){
            String mock = '[{"firstName":"Pedro","lastName":"Perez","cedulaIdentidad":"","phone":"00000001"}]';
            Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok', mock));
            Test.startTest();
            rotVideollamadaSolicitudController.ResponseWrapperCliente response = rotVideollamadaSolicitudController.fetchCliente('1','00000001');
            system.debug(response.message);
            Test.stopTest();
            system.AssertEquals(STATUS_CODE_SUCCESS,response.statusCode,'Status code incorrecto');
        }
        
    }

    @isTest
    public static void fetchClienteTestNoEsClienteException() {
        String mock = '<xml>Error</xml>';
        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok', mock));
        Test.startTest();
        rotVideollamadaSolicitudController.ResponseWrapperCliente response = rotVideollamadaSolicitudController.fetchCliente('1','00000001');
        Test.stopTest();
        system.AssertEquals(STATUS_CODE_INTERNAL_ERROR,response.statusCode,'Status code incorrecto');
    }

    @isTest
    public static void fetchTurneroOpenCasesOk() {
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
            Test.startTest();
            rotVideollamadaSolicitudController.ResponseWrapperCasos response = rotVideollamadaSolicitudController.fetchTurneroOpenCases('1','12345678');
            Test.stopTest();
            system.AssertEquals(STATUS_CODE_SUCCESS,response.statusCode,'Status code incorrecto');
        }
    }
}