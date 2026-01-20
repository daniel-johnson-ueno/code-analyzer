/**
 * @name               : ClientIdentificationHelperTest
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 10-03-2025
 * @modification date  : 12-03-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Clase test de ClientIdentificationHelper
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   10-03-2025   Alvaro Gonzales Lapponi   Initial Version
**/
@isTest
public with sharing class ClientIdentificationHelperTest {
    static final String ASSERT_MESSAGE                      = 'Atributo de cliente incorrecto';
    static final String CLIENT_ESTADO_EXISTE_EN_SALESFORCE  = 'Existente en Salesforce';
    static final String CLIENT_ESTADO_NUEVO_EN_SALESFORCE   = 'Nuevo en Salesforce';
    static final String CLIENT_ESTADO_NO_CLIENTE            = 'No Cliente';
    /**
    * @description Inserción de data dummy
    * @author Alvaro Gonzales Lapponi | 10-03-2025 
    **/
    @testSetup
    public static void dataSetup(){
        List<Account> accList = new List<Account>();
        Id rtIdAccPersonAccount = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account clientePersonaNatural = new Account(FirstName = 'Test FirstName', LastName = 'Test LastName', RecordTypeId = rtIdAccPersonAccount, DocumentNumber__c = '12345678', DocumentType__c = '1');
        accList.add(clientePersonaNatural);
        Account accNoCliente = new Account(Name = 'No Cliente');
        accList.add(accNoCliente);
        insert accList;
    }

    /**
    * @description Casuística: Cliente sí existe en Salesforce
    * @author Alvaro Gonzales Lapponi | 10-03-2025 
    **/
    @isTest
    public static void verifyAndRetrieveClientIsClientSalesforceOk() {
        Test.startTest();
        ClientIdentificationHelper.Response retrievedClient = ClientIdentificationHelper.verifyAndRetrieveClient('1', '12345678');
        Test.stopTest();
        Account acc = [SELECT Id FROM Account WHERE FirstName = 'Test FirstName' LIMIT 1];
        system.AssertEquals(CLIENT_ESTADO_EXISTE_EN_SALESFORCE, retrievedClient.estado, ASSERT_MESSAGE);
        system.AssertEquals(true, retrievedClient.cliente.esCliente, ASSERT_MESSAGE);
        system.AssertEquals(acc.iD, retrievedClient.cliente.accountId, ASSERT_MESSAGE);
        
    }

    /**
    * @description Casuística: Cliente Persona no existe en Salesforce pero sí en Bankiti
    * @author Alvaro Gonzales Lapponi | 10-03-2025 
    **/
    @isTest
    public static void verifyAndRetrieveClientPersonIsClientBankitiOk() {
        String mock = '[{"firstName":"Nombre Test", "lastName":"Apellido Test", "cedulaIdentidad":"00000001","phone":"987654321"}]';
        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok', mock));
        Test.startTest();
        ClientIdentificationHelper.Response retrievedClient = ClientIdentificationHelper.verifyAndRetrieveClient('1', '00000001');
        Test.stopTest();
        Account acc = [SELECT Id FROM Account WHERE DocumentType__c = '1' AND DocumentNumber__c = '00000001' LIMIT 1];
        system.AssertEquals(CLIENT_ESTADO_NUEVO_EN_SALESFORCE, retrievedClient.estado, ASSERT_MESSAGE);
        system.AssertEquals(true, retrievedClient.cliente.esCliente, ASSERT_MESSAGE);
        system.AssertEquals(acc.iD, retrievedClient.cliente.accountId, ASSERT_MESSAGE);
    }

    /**
    * @description Casuística: Cliente Empresa no existe en Salesforce pero sí en Bankiti
    * @author Alvaro Gonzales Lapponi | 10-03-2025 
    **/
    @isTest
    public static void verifyAndRetrieveClientCompanyIsClientBankitiOk() {
        String mock = '[{"firstName":"Nombre Test", "cuil":"10000001","phone":"987654321"}]';
        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok', mock));
        Test.startTest();
        ClientIdentificationHelper.Response retrievedClient = ClientIdentificationHelper.verifyAndRetrieveClient('6', '10000001');
        Test.stopTest();
        Account acc = [SELECT Id FROM Account WHERE DocumentType__c = '6' AND DocumentNumber__c = '10000001' LIMIT 1];
        system.AssertEquals(CLIENT_ESTADO_NUEVO_EN_SALESFORCE, retrievedClient.estado, ASSERT_MESSAGE);
        system.AssertEquals(true, retrievedClient.cliente.esCliente, ASSERT_MESSAGE);
        system.AssertEquals(acc.iD, retrievedClient.cliente.accountId, ASSERT_MESSAGE);
    }

    /**
    * @description Casuística: Cliente no existe en Salesforce ni en Bankiti pero sí en IDL
    * @author Alvaro Gonzales Lapponi | 10-03-2025 
    **/
    @isTest
    public static void verifyAndRetrieveClientIsNotClientButFoundOk() {
        String mock = '[{"firstName":"Nombre Test","cedulaIdentidad":"00000001"}]';
        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok', mock));
        Test.startTest();
        ClientIdentificationHelper.Response retrievedClient = ClientIdentificationHelper.verifyAndRetrieveClient('1', '00000001');
        Test.stopTest();
        Account acc = [SELECT Id FROM Account WHERE Name = 'No Cliente' LIMIT 1];
        system.AssertEquals(CLIENT_ESTADO_NO_CLIENTE, retrievedClient.estado, ASSERT_MESSAGE);
        system.AssertEquals('Nombre Test', retrievedClient.cliente.fullName, ASSERT_MESSAGE);
        system.AssertEquals('1', retrievedClient.cliente.tipoDocumento, ASSERT_MESSAGE);
        system.AssertEquals('00000001', retrievedClient.cliente.numeroDocumento, ASSERT_MESSAGE);
        system.AssertEquals(false, retrievedClient.cliente.esCliente, ASSERT_MESSAGE);
        system.AssertEquals(acc.iD, retrievedClient.cliente.accountId, ASSERT_MESSAGE);
    }

    /**
    * @description Casuística: Cliente no existe en Salesforce,Bankiti ni IDL
    * @author Alvaro Gonzales Lapponi | 10-03-2025 
    **/
    @isTest
    public static void verifyAndRetrieveClientIsNotClientNotFoundOk() {
        String mock = '[{"cedulaIdentidad":"00000001"}]';
        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok', mock));
        Test.startTest();
        ClientIdentificationHelper.Response retrievedClient = ClientIdentificationHelper.verifyAndRetrieveClient('1', '00000001');
        Test.stopTest();
        Account acc = [SELECT Id FROM Account WHERE Name = 'No Cliente' LIMIT 1];
        system.AssertEquals(CLIENT_ESTADO_NO_CLIENTE, retrievedClient.estado, ASSERT_MESSAGE);
        system.AssertEquals(true, String.isBlank(retrievedClient.cliente.fullName), ASSERT_MESSAGE);
        system.AssertEquals('1', retrievedClient.cliente.tipoDocumento, ASSERT_MESSAGE);
        system.AssertEquals('00000001', retrievedClient.cliente.numeroDocumento, ASSERT_MESSAGE);
        system.AssertEquals(false, retrievedClient.cliente.esCliente, ASSERT_MESSAGE);
        system.AssertEquals(acc.iD, retrievedClient.cliente.accountId, ASSERT_MESSAGE);
    }

}