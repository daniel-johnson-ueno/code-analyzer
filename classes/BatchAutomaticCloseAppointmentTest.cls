/**
 * @name               : BatchAutomaticCloseAppointmentTest
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 26-05-2025
 * @modification date  : 27-05-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Clase test de BatchAutomaticCloseAppointment
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   26-05-2025   Alvaro Gonzales Lapponi   Initial Version
**/
@isTest
public with sharing class BatchAutomaticCloseAppointmentTest {
    
    /**
    * @description Método de carga de data dummy
    * @author Alvaro Gonzales Lapponi | 27-05-2025 
    **/
    @testSetup
    static void setupTestData() {
        User testUser = [SELECT Id, Name FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        
        system.runAs(testUser){
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
                ExperienceCenter__c = sucursalAregua.Id, OwnerId = testUser.Id, RegistrationDateTime__c = System.now().addDays(-1)
            );
            appointments.add(testOpenAppointment);
            insert appointments;
        }
    }

    /**
    * @description Método test para invocar a batch sin errores
    * @author Alvaro Gonzales Lapponi | 27-05-2025 
    **/
    @isTest
    static void closeAppointmentsWithoutErrorsTest() {
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        system.runAs(testUser){
            Test.startTest();
            BatchAutomaticCloseAppointment closeAppointmentsClass = new BatchAutomaticCloseAppointment();
            Database.executeBatch(closeAppointmentsClass, 10);
            Test.stopTest();
            Boolean updatedRecords = confirmUpdatedRecords();
            system.AssertEquals(true, updatedRecords, 'Registros debieron actualizarse correctamente');
        }
    }

    /**
    * @description Método test para invocar a batch con usuario sin permisos suficientes
    * @author Alvaro Gonzales Lapponi | 27-05-2025 
    **/
    @isTest
    static void closeAppointmentsWithErrorsTest() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Cajeros' LIMIT 1];
        // Crear usuario sin permisos
        User standardUser = new User(
            Alias = 'stduser',
            Email = 'standarduserturnero@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Lima',
            UserName = 'standarduserturnero' + DateTime.now().getTime() + '@test.com',
            Office__c = '320'
        );
        insert standardUser;
        system.debug('post inserts');
        
        system.runAs(standardUser){
            Test.startTest();
            BatchAutomaticCloseAppointment closeAppointmentsClass = new BatchAutomaticCloseAppointment();
            Database.executeBatch(closeAppointmentsClass, 10);
            Test.stopTest();
            Boolean updatedRecords = confirmUpdatedRecords();
            system.AssertEquals(false, updatedRecords, 'Registros NO debieron actualizarse correctamente');
        }
    }

    /**
    * @description Método test para ejecutar la clase batch sin parámetros
    * @author Alvaro Gonzales Lapponi | 27-05-2025 
    **/
    @isTest
    static void testExecuteMethod() {
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        system.runAs(testUser){
            Test.startTest();
            new BatchAutomaticCloseAppointment().execute(null);
            Test.stopTest();
            Boolean updatedRecords = confirmUpdatedRecords();
            system.AssertEquals(true, updatedRecords, 'Registros debieron actualizarse correctamente');
        }
    }
    
    /**
    * @description Método auxiliar para confirmar que los registros fueron actualizados
    * @author Alvaro Gonzales Lapponi | 27-05-2025 
    * @return Boolean 
    **/
    private static Boolean confirmUpdatedRecords(){
        List<Appointment__c> appointments = [SELECT Id, Status__c, Case__c, Case__r.Status FROM Appointment__c WHERE RegistrationDateTime__c = YESTERDAY ];
        for(Appointment__c app : appointments){
            system.debug(app);
            system.debug(app.Case__r.Status);
            if( !(app.Status__c == 'Cancelado' && app.Case__r.Status == Label.CaseStatus_Close) ){
                return false;
            }
        }
        return true;
    }
}