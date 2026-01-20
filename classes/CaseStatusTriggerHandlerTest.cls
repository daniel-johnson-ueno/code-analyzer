@isTest  
public class CaseStatusTriggerHandlerTest {

    @TestSetup
    private static void setup(){
        Ueno_Service_Domain__c testUrl= new Ueno_Service_Domain__c(ApiKey__c = '555-555-555',DomainName__c='https://kongcloud.ind-dev-sae1.ueno.com.py');
        insert  testUrl;

        Account testUenoGroupCompany = (Account)TestFactoryFramework.createSObject(new Account(), 'TestFactoryFrameworkDefaults.InternalCompanyAccountDefaults', false);
        testUenoGroupCompany.Name = 'Ueno Bank SA';
        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Vazquez_Group_Company');
        String recordTypeId = recordTypeInfo.getRecordTypeId();
        testUenoGroupCompany.RecordTypeId = recordTypeId;
        testUenoGroupCompany.GroupCompaniesUeno__c = 'UENO_BANK';
        insert testUenoGroupCompany;

        Account testTutiCompany = (Account)TestFactoryFramework.createSObject(new Account(), 'TestFactoryFrameworkDefaults.InternalCompanyAccountDefaults', false);
        testTutiCompany.Name = 'Tuti';
        testTutiCompany.RecordTypeId = recordTypeId;
        testTutiCompany.GroupCompaniesUeno__c = 'TUTI';
        insert testTutiCompany;

        Account testPersonAccount = (Account)TestFactoryFramework.createSObject(new Account(), 'TestFactoryFrameworkDefaults.PersonAccountDefaults', true);
        Case caseTestReclamo = (Case)TestFactoryFramework.createSObject(new Case(), 'TestFactoryFrameworkDefaults.ReclamoCaseDefaults', false);
        caseTestReclamo.AccountId = testPersonAccount.Id;
        caseTestReclamo.Description = 'Test Case Handler';
        caseTestReclamo.Subject = 'Test Case Handler';
        caseTestReclamo.Vazquez_Group_Company__c = testUenoGroupCompany.Id;
        insert caseTestReclamo;

        Case caseTestReclamoTuti = (Case)TestFactoryFramework.createSObject(new Case(), 'TestFactoryFrameworkDefaults.ReclamoCaseDefaults', false);
        caseTestReclamoTuti.AccountId = testPersonAccount.Id;
        caseTestReclamoTuti.Description = 'Test Case Handler Tuti';
        caseTestReclamoTuti.Subject = 'Test Case Handler Tuti';
        caseTestReclamoTuti.Vazquez_Group_Company__c = testTutiCompany.Id;
        insert caseTestReclamoTuti;

        Client_of_Company__c client = new Client_of_Company__c();
        client.Client__c = testPersonAccount.Id;
        client.Vazquez_Group_Company__c = testTutiCompany.Id;
        client.Email__c = 'test@test.com';
        client.Origin_of_Creation__c = 'SF - Buscador de clientes';
        insert client;
    }

  @isTest  
    public static void testHandleCaseStatus(){
       
        Group supportQueue = new Group(Name = 'Soporte_TI', Type = 'Queue');
        insert supportQueue;
        
        User testUser = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1 ];
        RecordType reclamo = [SELECT Id, DeveloperName, SObjectType FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Reclamo' LIMIT 1];




      Case oldCase = new Case(
            Status = 'Escalado',
            RecordTypeId =  reclamo.Id,
            Type = 'Casa de Bolsa',
            Reason = 'Venta procesada, dinero no acreditado',
            Origin = 'BOT',
            OwnerId = testUser.Id
        );
        insert oldCase;

        Case newCase = new Case(
            Id = oldCase.Id,
            Status = 'Derivado',
            RecordTypeId =  reclamo.Id,
            Type = 'Casa de Bolsa',
            Reason = 'Venta procesada, dinero no acreditado',
            Origin = 'BOT',
            OwnerId = testUser.Id
        );
        
        List<Case> newCases = new List<Case>{newCase};
        Map<Id, Case> oldCaseMap = new Map<Id, Case>{oldCase.Id => oldCase};

        Test.startTest();
        CaseStatusTriggerHandler.handleCaseStatus(newCases[0], oldCaseMap.get(newCases[0].Id));
        Test.stopTest();
    }  
    
   @isTest  
    public static void testHandleCaseStatus2(){
        
        RecordType reclamo = [SELECT Id, DeveloperName,SObjectType FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Reclamo' LIMIT 1];
        
     
        Group supportQueue = new Group(Name = 'Soporte_TI', Type = 'Queue');
        insert supportQueue;


        //Account person = TestFactory.createPersonAccount();
        
        Case oldCase = new Case(
            //AccountId = person.Id,
            Status = 'Escalado',
            RecordTypeId =  reclamo.Id,
            Type = 'Casa de Bolsa',
            Reason = 'Venta procesada, dinero no acreditado',
            Origin = 'BOT'
        );
        insert oldCase;

        Case newCase = new Case(
            //AccountId = person.Id,
            Id = oldCase.Id,
            Status = 'Derivado',
            RecordTypeId =  reclamo.Id,
            Type = 'Casa de Bolsa',
            Reason = 'Venta procesada, dinero no acreditado',
            Origin = 'BOT'
        );
        
        List<Case> newCases = new List<Case>{newCase};
        Map<Id, Case> oldCaseMap = new Map<Id, Case>{oldCase.Id => oldCase};

        Test.startTest();
        CaseStatusTriggerHandler.handleCaseStatus(newCases[0], oldCaseMap.get(newCases[0].Id));
        Test.stopTest();
    }  
    
     @isTest  
    	public static void testHandleCaseStatus3(){
        
        RecordType reclamo = [SELECT Id, DeveloperName,SObjectType FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Reclamo' LIMIT 1];
        
     
        Group supportQueue = new Group(Name = 'Soporte_TI', Type = 'Queue');
        insert supportQueue;


        //Account person = TestFactory.createPersonAccount();
        
        Case oldCase = new Case(
            //AccountId = person.Id,
            Status = 'Derivado',
            RecordTypeId =  reclamo.Id,
            Type = 'Transferencias',
            Reason = 'No puedo hacer transferencia',
            Origin = 'BOT'
        );
        insert oldCase;

        Case newCase = new Case(
            //AccountId = person.Id,
            Id = oldCase.Id,
            Status = 'Cerrado',
            RecordTypeId =  reclamo.Id,
            Type = 'Tarjetas procesamiento',
            Reason = 'No puedo hacer transferencia',
            Origin = 'BOT'
        );
        
        List<Case> newCases = new List<Case>{newCase};
        Map<Id, Case> oldCaseMap = new Map<Id, Case>{oldCase.Id => oldCase};

        Test.startTest();
        CaseStatusTriggerHandler.handleCaseStatus(newCases[0], oldCaseMap.get(newCases[0].Id));
        Test.stopTest();
    }
    
   @isTest  
    	public static void testHandleCaseStatus4(){
        
        RecordType reclamo = [SELECT Id, DeveloperName,SObjectType FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Reclamo' LIMIT 1];
        
     
        Group supportQueue = new Group(Name = 'Gestion_Operativa', Type = 'Queue');
        insert supportQueue;


        //Account person = TestFactory.createPersonAccount();
        
        Case oldCase = new Case(
            //AccountId = person.Id,
            Status = 'Asignado',
            RecordTypeId =  reclamo.Id,
            Type = 'Tarjetas procesamiento',
            Reason = 'Dinero no dispensado ATM externo',
            Origin = 'BOT'
        );
        insert oldCase;

        Case newCase = new Case(
            //AccountId = person.Id,
            Id = oldCase.Id,
            Status = 'Escalado',
            RecordTypeId =  reclamo.Id,
            Type = 'Tarjetas procesamiento',
            Reason = 'Dinero no dispensado ATM externo',
            Origin = 'BOT'
        );
        
        List<Case> newCases = new List<Case>{newCase};
        Map<Id, Case> oldCaseMap = new Map<Id, Case>{oldCase.Id => oldCase};

        Test.startTest();
        CaseStatusTriggerHandler.handleCaseStatus(newCases[0], oldCaseMap.get(newCases[0].Id));
        Test.stopTest();
    }
    
    @isTest  
    	public static void testHandleCaseStatus5(){
        
        RecordType solicitud  = [SELECT Id, DeveloperName,SObjectType FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Solicitud' LIMIT 1];
        
     
        Group supportQueue = new Group(Name = 'Gestion_Operativa', Type = 'Queue');
        insert supportQueue;


        //Account person = TestFactory.createPersonAccount();
        
        Case oldCase = new Case(
           // AccountId = person.Id,
            Status = 'Asignado',
            RecordTypeId =  solicitud.Id,
            Type = 'Onboarding',
            Reason = 'Eliminacion de Onboarding',
            Origin = 'Turnero'
        );
        insert oldCase;

        Case newCase = new Case(
            //AccountId = person.Id,
            Id = oldCase.Id,
            Status = 'Escalado',
            RecordTypeId =  solicitud.Id,
            Type = 'Onboarding',
            Reason = 'Eliminacion de Onboarding',
            Origin = 'Turnero',
            CancellationReason__c = 'Cliente incorrecto'
        );
        
        List<Case> newCases = new List<Case>{newCase};
        Map<Id, Case> oldCaseMap = new Map<Id, Case>{oldCase.Id => oldCase};

        Test.startTest();
        CaseStatusTriggerHandler.handleCaseStatus(newCases[0], oldCaseMap.get(newCases[0].Id));
        Test.stopTest();
    }
    
    @isTest  
    	public static void testHandleCaseStatus6(){
        
        RecordType solicitud  = [SELECT Id, DeveloperName,SObjectType FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Solicitud' LIMIT 1];
        
     
        Group supportQueue = new Group(Name = 'Gestion_Operativa', Type = 'Queue');
        insert supportQueue;


        //Account person = TestFactory.createPersonAccount();
        
        Case oldCase = new Case(
            //AccountId = person.Id,
            Status = 'Derivado',
            RecordTypeId =  solicitud.Id,
            Type = 'Onboarding',
            Reason = 'Eliminacion de Onboarding',
            Origin = 'Turnero'
        );
        insert oldCase;

        Case newCase = new Case(
            //AccountId = person.Id,
            Id = oldCase.Id,
            Status = 'En Validación',
            RecordTypeId =  solicitud.Id,
            Type = 'Onboarding',
            Reason = 'Eliminacion de Onboarding',
            Origin = 'Turnero',
            CancellationReason__c = 'Cliente incorrecto'
        );
        
        List<Case> newCases = new List<Case>{newCase};
        Map<Id, Case> oldCaseMap = new Map<Id, Case>{oldCase.Id => oldCase};

        Test.startTest();
        CaseStatusTriggerHandler.handleCaseStatus(newCases[0], oldCaseMap.get(newCases[0].Id));
        Test.stopTest();
    }

    @isTest  
    	public static void testNoExistStatus(){
        
        RecordType solicitud  = [SELECT Id, DeveloperName,SObjectType FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Solicitud' LIMIT 1];
        
     
        Group supportQueue = new Group(Name = 'Gestion_Operativa', Type = 'Queue');
        insert supportQueue;


        //Account person = TestFactory.createPersonAccount();
        
        Case oldCase = new Case(
            //AccountId = person.Id,
            Status = 'Escalado',
            RecordTypeId =  solicitud.Id,
            Type = 'Casa de Bolsa',
            Reason = 'Venta de CDA',
            Origin = 'Turnero'
        );
        insert oldCase;

        Case newCase = new Case(
            //AccountId = person.Id,
            Id = oldCase.Id,
            Status = 'Derivado',
            RecordTypeId =  solicitud.Id,
            Type = 'Casa de Bolsa',
            Reason = 'Venta de CDA',
            Origin = 'Turnero'
        );
        
        List<Case> newCases = new List<Case>{newCase};
        Map<Id, Case> oldCaseMap = new Map<Id, Case>{oldCase.Id => oldCase};

        Test.startTest();
        CaseStatusTriggerHandler.handleCaseStatus(newCases[0], oldCaseMap.get(newCases[0].Id));
        Test.stopTest();
    }

    @isTest  
    	public static void testIrrelevantStatusChange(){
        
        RecordType solicitud  = [SELECT Id, DeveloperName,SObjectType FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Solicitud' LIMIT 1];
        
     
        Group supportQueue = new Group(Name = 'Gestion_Operativa', Type = 'Queue');
        insert supportQueue;


        //Account person = TestFactory.createPersonAccount();
        
        Case oldCase = new Case(
            //AccountId = person.Id,
            Status = 'Nuevo',
            RecordTypeId =  solicitud.Id,
            Type = 'Onboarding',
            Reason = 'Eliminacion de Onboarding',
            Origin = 'Turnero'
        );
        insert oldCase;

        Case newCase = new Case(
            //AccountId = person.Id,
            Id = oldCase.Id,
            Status = 'Asignado',
            RecordTypeId =  solicitud.Id,
            Type = 'Onboarding',
            Reason = 'Eliminacion de Onboarding',
            Origin = 'Turnero',
            CancellationReason__c = 'Cliente incorrecto'
        );
        
        List<Case> newCases = new List<Case>{newCase};
        Map<Id, Case> oldCaseMap = new Map<Id, Case>{oldCase.Id => oldCase};

        Test.startTest();
        CaseStatusTriggerHandler.handleCaseStatus(newCases[0], oldCaseMap.get(newCases[0].Id));
        Test.stopTest();
    }
    
    @isTest  
    	public static void testDerivationROT(){
        
        RecordType solicitud  = [SELECT Id, DeveloperName,SObjectType FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Solicitud' LIMIT 1];
        
        //Account person = TestFactory.createPersonAccount();
        
        Case oldCase = new Case(
           // AccountId = person.Id,
            Status = 'Asignado',
            RecordTypeId =  solicitud.Id,
            Type = 'Onboarding',
            Reason = 'Eliminacion de Onboarding',
            Origin = 'Turnero', 
            ROTDerivation__c = true
        );
        insert oldCase;

        Case newCase = new Case(
            //AccountId = person.Id,
            Id = oldCase.Id,
            Status = 'Escalado',
            RecordTypeId =  solicitud.Id,
            Type = 'Onboarding',
            Reason = 'Eliminacion de Onboarding',
            Origin = 'Turnero',
            CancellationReason__c = 'Cliente incorrecto', 
            ROTDerivation__c = true
        );
        
        List<Case> newCases = new List<Case>{newCase};
        Map<Id, Case> oldCaseMap = new Map<Id, Case>{oldCase.Id => oldCase};

        Test.startTest();
        CaseStatusTriggerHandler.handleCaseStatus(newCases[0], oldCaseMap.get(newCases[0].Id));
        Test.stopTest();
    }

    @isTest  
    	public static void testNotDerivationROT(){
        
        RecordType solicitud  = [SELECT Id, DeveloperName,SObjectType FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Solicitud' LIMIT 1];
        
        //Account person = TestFactory.createPersonAccount();
        
        Case oldCase = new Case(
           // AccountId = person.Id,
            Status = 'Asignado',
            RecordTypeId =  solicitud.Id,
            Type = 'Onboarding',
            Reason = 'Eliminacion de Onboarding',
            SendToROT__c = true, 
            ROTDerivation__c = true
        );
        insert oldCase;

        Case newCase = new Case(
            //AccountId = person.Id,
            Id = oldCase.Id,
            Status = 'Escalado',
            RecordTypeId =  solicitud.Id,
            Type = 'Onboarding',
            Reason = 'Eliminacion de Onboarding',
            SendToROT__c = true,
            CancellationReason__c = 'Cliente incorrecto', 
            ROTDerivation__c = true
        );
        
        List<Case> newCases = new List<Case>{newCase};
        Map<Id, Case> oldCaseMap = new Map<Id, Case>{oldCase.Id => oldCase};

        Test.startTest();
        CaseStatusTriggerHandler.handleCaseStatus(newCases[0], oldCaseMap.get(newCases[0].Id));
        Test.stopTest();
    }
    
    @isTest  
    	public static void testNewStatusEnValidacionROT(){
        
        RecordType solicitud  = [SELECT Id, DeveloperName,SObjectType FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Solicitud' LIMIT 1];
        
        //Account person = TestFactory.createPersonAccount();
        
        Case oldCase = new Case(
           // AccountId = person.Id,
            Status = 'Asignado',
            RecordTypeId =  solicitud.Id,
            Type = 'Onboarding',
            Reason = 'Eliminacion de Onboarding',
            Origin = 'Turnero', 
            ROTDerivation__c = true
        );
        insert oldCase;

        Case newCase = new Case(
          //  AccountId = person.Id,
            Id = oldCase.Id,
            Status = 'En Validación',
            RecordTypeId =  solicitud.Id,
            Type = 'Onboarding',
            Reason = 'Eliminacion de Onboarding',
            Origin = 'Turnero',
            CancellationReason__c = 'Cliente incorrecto'
        );
        
        List<Case> newCases = new List<Case>{newCase};
        Map<Id, Case> oldCaseMap = new Map<Id, Case>{oldCase.Id => oldCase};

        Test.startTest();
        CaseStatusTriggerHandler.handleCaseStatus(newCases[0], oldCaseMap.get(newCases[0].Id));
        Test.stopTest();
    }
    
    @isTest  
    	public static void testNewStatusEnValidacion(){
        
        RecordType solicitud  = [SELECT Id, DeveloperName,SObjectType FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Solicitud' LIMIT 1];
        
        //Account person = TestFactory.createPersonAccount();
        
        Case oldCase = new Case(
           // AccountId = person.Id,
            Status = 'Asignado',
            RecordTypeId =  solicitud.Id,
            Type = 'Onboarding',
            Reason = 'Eliminacion de Onboarding',
            Origin = 'BOT'
        );
        insert oldCase;

        Case newCase = new Case(
            //AccountId = person.Id,
            Id = oldCase.Id,
            Status = 'En Validación',
            RecordTypeId =  solicitud.Id,
            Type = 'Onboarding',
            Reason = 'Eliminacion de Onboarding',
            Origin = 'BOT',
            CancellationReason__c = 'Cliente incorrecto'
        );
        
        List<Case> newCases = new List<Case>{newCase};
        Map<Id, Case> oldCaseMap = new Map<Id, Case>{oldCase.Id => oldCase};

        Test.startTest();
        CaseStatusTriggerHandler.handleCaseStatus(newCases[0], oldCaseMap.get(newCases[0].Id));
        Test.stopTest();
    }
    
    @isTest  
    	public static void testOldStatusIsClosed(){
        
        RecordType solicitud  = [SELECT Id, DeveloperName,SObjectType FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Solicitud' LIMIT 1];

        User userTest = [SELECT Id FROM User WHERE ProfileId != :Label.ProfileSystemAdminId AND IsActive = true LIMIT 1];
        
        //Account person = TestFactory.createPersonAccount();
        
        Case oldCase = new Case(
          //  AccountId = person.Id,
            Status = 'Cerrado',
            RecordTypeId =  solicitud.Id,
            Type = 'Onboarding',
            Reason = 'Eliminacion de Onboarding',
            Origin = 'BOT',
            Resolution__c = 'Resolución a favor'
        );
        insert oldCase;

        Case newCase = new Case(
           // AccountId = person.Id,
            Id = oldCase.Id,
            Status = 'En Validación',
            RecordTypeId =  solicitud.Id,
            Type = 'Onboarding',
            Reason = 'Eliminacion de Onboarding',
            Origin = 'BOT',
            CancellationReason__c = 'Cliente incorrecto'
        );
        
        List<Case> newCases = new List<Case>{newCase};
        Map<Id, Case> oldCaseMap = new Map<Id, Case>{oldCase.Id => oldCase};

        Test.startTest();
        System.runAs(userTest){
            CaseStatusTriggerHandler.handleCaseStatus(newCases[0], oldCaseMap.get(newCases[0].Id));
        }
        Test.stopTest();
    }
    
    @isTest  
    	public static void testNewStatDerivadoError(){
        
        RecordType solicitud  = [SELECT Id, DeveloperName,SObjectType FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Solicitud' LIMIT 1];
        
        //Account person = TestFactory.createPersonAccount();
        
        Case oldCase = new Case(
          //  AccountId = person.Id,
            Status = 'Asignado',
            RecordTypeId =  solicitud.Id,
            Type = 'Onboarding',
            Reason = 'Eliminacion de Onboarding',
            Origin = 'BOT'
        );
        insert oldCase;

        Case newCase = new Case(
          //  AccountId = person.Id,
            Id = oldCase.Id,
            Status = 'Derivado',
            RecordTypeId =  solicitud.Id,
            Type = 'Onboarding',
            Reason = 'Eliminacion de Onboarding',
            Origin = 'BOT',
            CancellationReason__c = 'Cliente incorrecto'
        );
        
        List<Case> newCases = new List<Case>{newCase};
        Map<Id, Case> oldCaseMap = new Map<Id, Case>{oldCase.Id => oldCase};

        Test.startTest();
        CaseStatusTriggerHandler.handleCaseStatus(newCases[0], oldCaseMap.get(newCases[0].Id));
        Test.stopTest();
    }
    
    @isTest  
    public static void testNewStatCerradoError(){
        
        RecordType solicitud  = [SELECT Id, DeveloperName,SObjectType FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Solicitud' LIMIT 1];
        
      //  Account person = TestFactory.createPersonAccount();
        
        Case oldCase = new Case(
            //AccountId = person.Id,
            Status = 'Asignado',
            RecordTypeId =  solicitud.Id,
            Type = 'Onboarding',
            Reason = 'Eliminacion de Onboarding',
            Origin = 'BOT'
        );
        insert oldCase;

        Case newCase = new Case(
         //   AccountId = person.Id,
            Id = oldCase.Id,
            Status = 'Cerrado',
            RecordTypeId =  solicitud.Id,
            Type = 'Onboarding',
            Reason = 'Eliminacion de Onboarding',
            Origin = 'BOT',
            CancellationReason__c = 'Cliente incorrecto'
        );
        
        List<Case> newCases = new List<Case>{newCase};
        Map<Id, Case> oldCaseMap = new Map<Id, Case>{oldCase.Id => oldCase};

        Test.startTest();
        CaseStatusTriggerHandler.handleCaseStatus(newCases[0], oldCaseMap.get(newCases[0].Id));
        Test.stopTest();
    }
    
    @isTest  
    	public static void testNewStatCerradoOwner(){
        
        RecordType solicitud  = [SELECT Id, DeveloperName,SObjectType FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Solicitud' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
       // Account person = TestFactory.createPersonAccount();
        
        Case oldCase = new Case(
           // AccountId = person.Id,
            Status = 'Asignado',
            RecordTypeId =  solicitud.Id,
            Type = 'Onboarding',
            Reason = 'Eliminacion de Onboarding',
            Origin = 'BOT',
            OwnerId = testUser.Id,
            Description = 'Test description',
            Subject = 'Test subject'
        );
        insert oldCase;

        Case newCase = new Case(
          //  AccountId = person.Id,
            Id = oldCase.Id,
            Status = 'Cerrado',
            RecordTypeId =  solicitud.Id,
            Type = 'Onboarding',
            Reason = 'Eliminacion de Onboarding',
            Origin = 'BOT',
            CancellationReason__c = 'Cliente incorrecto',
            OwnerId = testUser.Id,
            Description = 'Test description',
            Subject = 'Test subject'
        );
        
        List<Case> newCases = new List<Case>{newCase};
        Map<Id, Case> oldCaseMap = new Map<Id, Case>{oldCase.Id => oldCase};

        Test.startTest();
        CaseStatusTriggerHandler.handleCaseStatus(newCases[0], oldCaseMap.get(newCases[0].Id));
        Test.stopTest();
    }
    
    @isTest  
    	public static void testNewStatCerradoOwner2(){
        
        RecordType solicitud  = [SELECT Id, DeveloperName,SObjectType FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Solicitud' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
       // Account person = TestFactory.createPersonAccount();
        
        Case oldCase = new Case(
          //  AccountId = person.Id,
            Status = 'Escalado',
            RecordTypeId =  solicitud.Id,
            Type = '',
            Reason = 'Eliminacion de Onboarding',
            Origin = 'BOT',
            OwnerId = testUser.Id,
            Description = 'Test description',
            Subject = 'Test subject'
        );
        insert oldCase;

        Case newCase = new Case(
           // AccountId = person.Id,
            Id = oldCase.Id,
            Status = 'Escalado',
            RecordTypeId =  solicitud.Id,
            Type = 'Onboarding',
            Reason = 'Eliminacion de Onboarding',
            Origin = 'BOT',
            OwnerId = testUser.Id,
            Description = 'Test description',
            Subject = 'Test subject'
        );
        
        List<Case> newCases = new List<Case>{newCase};
        Map<Id, Case> oldCaseMap = new Map<Id, Case>{oldCase.Id => oldCase};

        Test.startTest();
        CaseStatusTriggerHandler.handleCaseTipificacion(newCases[0], oldCaseMap.get(newCases[0].Id));
        Test.stopTest();
    }

    @isTest  
    	public static void testNewStatCerradoError2(){
        
        RecordType consulta  = [SELECT Id, DeveloperName,SObjectType FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Consulta' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
       // Account person = TestFactory.createPersonAccount();
        
        Case oldCase = new Case(
          //  AccountId = person.Id,
            Status = 'Asignado',
            RecordTypeId =  consulta.Id,
            Type = '',
            Reason = '',
            Origin = 'Turnero',
            OwnerId = testUser.Id
        );
        insert oldCase;

        Case newCase = new Case(
           // AccountId = person.Id,
            Id = oldCase.Id,
            RecordTypeId =  consulta.Id,
            Type = 'Alias',
            Reason = 'Qué es el alias',
            Origin = 'Turnero',
            OwnerId = testUser.Id
            
        );
        
        List<Case> newCases = new List<Case>{newCase};
        Map<Id, Case> oldCaseMap = new Map<Id, Case>{oldCase.Id => oldCase};

        Test.startTest();
        CaseStatusTriggerHandler.handleCaseTipificacion(newCases[0], oldCaseMap.get(newCases[0].Id));
        Test.stopTest();
    }
    
     @isTest  
    	public static void testNewStatCerrado2(){
        
        RecordType consulta  = [SELECT Id, DeveloperName,SObjectType FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Consulta' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
       // Account person = TestFactory.createPersonAccount();
        
        Case oldCase = new Case(
          //  AccountId = person.Id,
            Status = 'Asignado',
            RecordTypeId =  consulta.Id,
            Type = '',
            Reason = '',
            Origin = 'Turnero',
            OwnerId = testUser.Id,
            Subject = 'SubjectTest',
            Description = 'DescriptionTest'
        );
        insert oldCase;

        Case newCase = new Case(
           // AccountId = person.Id,
            Id = oldCase.Id,
            RecordTypeId =  consulta.Id,
            Type = 'Alias',
            Reason = 'Qué es el alias',
            Origin = 'Turnero',
            OwnerId = testUser.Id,
            Subject = 'SubjectTest',
            Description = 'DescriptionTest'
        );
        
        List<Case> newCases = new List<Case>{newCase};
        Map<Id, Case> oldCaseMap = new Map<Id, Case>{oldCase.Id => oldCase};

        Test.startTest();
        CaseStatusTriggerHandler.handleCaseTipificacion(newCases[0], oldCaseMap.get(newCases[0].Id));
        Test.stopTest();
    }
    
    @isTest  
    	public static void testTelefonoEnValidacion(){
        
        RecordType solicitud  = [SELECT Id, DeveloperName,SObjectType FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Solicitud' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
       // Account person = TestFactory.createPersonAccount();
        
        Case oldCase = new Case(
          //  AccountId = person.Id,
            Status = 'Derivado',
            RecordTypeId =  solicitud.Id,
            Type = 'Onboarding',
            Reason = 'Eliminacion de Onboarding',
            Origin = 'Teléfono',
            OwnerId = testUser.Id,
            Description = 'Test description',
            Subject = 'Test subject'
        );
        insert oldCase;

        Case newCase = new Case(
           // AccountId = person.Id,
            Id = oldCase.Id,
            Status = 'En Validación',
            RecordTypeId =  solicitud.Id,
            Type = 'Onboarding',
            Reason = 'Eliminacion de Onboarding',
            Origin = 'Teléfono',
            OwnerId = testUser.Id,
            Description = 'Test description',
            Subject = 'Test subject'
        );
        
        List<Case> newCases = new List<Case>{newCase};
        Map<Id, Case> oldCaseMap = new Map<Id, Case>{oldCase.Id => oldCase};

        Test.startTest();
        CaseStatusTriggerHandler.handleCaseStatus(newCases[0], oldCaseMap.get(newCases[0].Id));
        Test.stopTest();
    }
    
    @isTest  
    	public static void testRRSSEnValidacion(){
        
        RecordType solicitud  = [SELECT Id, DeveloperName,SObjectType FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Solicitud' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
       // Account person = TestFactory.createPersonAccount();
        
        Case oldCase = new Case(
          //  AccountId = person.Id,
            Status = 'Derivado',
            RecordTypeId =  solicitud.Id,
            Type = 'Onboarding',
            Reason = 'Eliminacion de Onboarding',
            Origin = 'Twitter',
            OwnerId = testUser.Id,
            Description = 'Test description',
            Subject = 'Test subject'
        );
        insert oldCase;

        Case newCase = new Case(
           // AccountId = person.Id,
            Id = oldCase.Id,
            Status = 'En Validación',
            RecordTypeId =  solicitud.Id,
            Type = 'Onboarding',
            Reason = 'Eliminacion de Onboarding',
            Origin = 'Twitter',
            OwnerId = testUser.Id,
            Description = 'Test description',
            Subject = 'Test subject'
        );
        
        List<Case> newCases = new List<Case>{newCase};
        Map<Id, Case> oldCaseMap = new Map<Id, Case>{oldCase.Id => oldCase};

        Test.startTest();
        CaseStatusTriggerHandler.handleCaseStatus(newCases[0], oldCaseMap.get(newCases[0].Id));
        Test.stopTest();
    }
    
    @isTest  
    	public static void testReclamoFraude(){
        
        RecordType reclamoFraude  = [SELECT Id, DeveloperName,SObjectType FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Reclamo_Fraude' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
       // Account person = TestFactory.createPersonAccount();
        
        Case oldCase = new Case(
          //  AccountId = person.Id,
            Status = 'Derivado',
            RecordTypeId =  reclamoFraude.Id,
            Type = 'Transferencias',
            Reason = 'Cliente ueno estafado por cliente ueno',
            Origin = 'Turnero',
            OwnerId = testUser.Id,
            Description = 'Test description',
            Subject = 'Test subject'
        );
        insert oldCase;

        Case newCase = new Case(
           // AccountId = person.Id,
            Id = oldCase.Id,
            Status = 'En Validación',
            RecordTypeId =  reclamoFraude.Id,
            Type = 'Transferencias',
            Reason = 'Cliente ueno estafado por cliente ueno',
            Origin = 'Turnero',
            OwnerId = testUser.Id,
            Description = 'Test description',
            Subject = 'Test subject'
        );
        
        List<Case> newCases = new List<Case>{newCase};
        Map<Id, Case> oldCaseMap = new Map<Id, Case>{oldCase.Id => oldCase};

        Test.startTest();
        CaseStatusTriggerHandler.handleCaseStatus(newCases[0], oldCaseMap.get(newCases[0].Id));
        Test.stopTest();
    }
    @isTest  
    public static void testhandleKonnectInsightsCases(){
      	RecordType solicitud  = [SELECT Id, DeveloperName,SObjectType FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Solicitud' LIMIT 1];
     	User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

    	Case oldCase = new Case(
   		OwnerId = testUser.Id,
		RecordTypeId =  solicitud.Id,
    	Status = 'Derivado',
    	Origin = 'Konnect Insights - Facebook',
    	Description = 'Test description',
    	Subject = 'Test subject'
    	);
   		insert oldCase;
   		Case newCase = new Case(
    	Id = oldCase.Id,
    	OwnerId = testUser.Id,
        Origin = 'Konnect Insights - Facebook',    
   		RecordTypeId =  solicitud.Id,
    	Status = 'En Validación'
    	);
    	List<Case> newCases = new List<Case>{newCase};
        Map<Id, Case> oldCaseMap = new Map<Id, Case>{oldCase.Id => oldCase};
   		Test.startTest();
    	CaseStatusTriggerHandler.handleCaseStatus(newCases[0], oldCaseMap.get(newCases[0].Id));
    	Test.stopTest();
    }
    
    @isTest  
    public static void testClientLeft(){
      	RecordType solicitud  = [SELECT Id, DeveloperName,SObjectType FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Solicitud' LIMIT 1];
     	User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

    	Case oldCase = new Case(
   		OwnerId = testUser.Id,
		RecordTypeId =  solicitud.Id,
    	Status = 'Derivado',
    	Origin = 'Konnect Insights - Facebook',
    	Description = 'Test description',
    	Subject = 'Test subject',
        Client_left__c = false
    	);
   		insert oldCase;
   		Case newCase = new Case(
    	Id = oldCase.Id,
    	OwnerId = testUser.Id,
        Origin = 'Konnect Insights - Facebook',    
   		RecordTypeId =  solicitud.Id,
    	Status = 'En Validación',
        Client_left__c = true
    	);
    	List<Case> newCases = new List<Case>{newCase};
        Map<Id, Case> oldCaseMap = new Map<Id, Case>{oldCase.Id => oldCase};
   		Test.startTest();
    	CaseStatusTriggerHandler.handleCaseTipificacion(newCases[0], oldCaseMap.get(newCases[0].Id));
    	Test.stopTest();
        }

        @isTest  
    	public static void testClosureIsNotAllowed(){
        
        RecordType solicitud  = [SELECT Id, DeveloperName,SObjectType FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Solicitud' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
       // Account person = TestFactory.createPersonAccount();
        
        Case oldCase = new Case(
           // AccountId = person.Id,
            Status = 'Escalado',
            RecordTypeId =  solicitud.Id,
            Type = 'CDA',
            Reason = 'Vender CDA en casa de bolsa',
            SendToROT__c = true,
            OwnerId = testUser.Id,
            Description = 'Test description',
            Subject = 'Test subject'
        );
        insert oldCase;

        Case newCase = new Case(
          //  AccountId = person.Id,
            Id = oldCase.Id,
            Status = 'Cerrado',
            RecordTypeId =  solicitud.Id,
            Type = 'CDA',
            Reason = 'Vender CDA en casa de bolsa',
            SendToROT__c = true,
            OwnerId = testUser.Id,
            Description = 'Test description',
            Subject = 'Test subject'
        );
        
        List<Case> newCases = new List<Case>{newCase};
        Map<Id, Case> oldCaseMap = new Map<Id, Case>{oldCase.Id => oldCase};

        Test.startTest();
        CaseStatusTriggerHandler.handleCaseStatus(newCases[0], oldCaseMap.get(newCases[0].Id));
        Test.stopTest();
    }

    @isTest  
    public static void testhandleEmailOrigin(){
      	RecordType solicitud  = [SELECT Id, DeveloperName,SObjectType FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Solicitud' LIMIT 1];
     	User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

    	Case oldCase = new Case(
   		OwnerId = testUser.Id,
		RecordTypeId =  solicitud.Id,
    	Status = 'Derivado',
    	Origin = 'Email',
    	Description = 'Test description',
    	Subject = 'Test subject'
    	);
   		insert oldCase;
   		Case newCase = new Case(
    	Id = oldCase.Id,
    	OwnerId = testUser.Id,
        Origin = 'Email',    
   		RecordTypeId =  solicitud.Id,
    	Status = 'En Validación'
    	);
    	List<Case> newCases = new List<Case>{newCase};
        Map<Id, Case> oldCaseMap = new Map<Id, Case>{oldCase.Id => oldCase};
   		Test.startTest();
    	CaseStatusTriggerHandler.handleCaseStatus(newCases[0], oldCaseMap.get(newCases[0].Id));
    	Test.stopTest();
    }

    @isTest  
    public static void testHandleCommercialCase(){
      	RecordType solicitud  = [SELECT Id, DeveloperName,SObjectType FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Solicitud' LIMIT 1];
     	User testUser = [SELECT Id FROM User WHERE IsActive = TRUE AND Email = 'cristian.moreno@itti.digital' LIMIT 1];

        Account acc = new Account(
        	Name = 'Test acc',
         	PersonCode__c = 123456,
    		AccountExecutiveEmail__c = 'cristian.moreno@itti.digital'
        );

        insert acc;

    	Case oldCase = new Case(
   		OwnerId = testUser.Id,
        AccountId = acc.Id,
		RecordTypeId =  solicitud.Id,
    	Status = 'Asignado',
    	Origin = 'Email',
    	Description = 'Test description',
    	Subject = 'Test subject',
        Type = 'Caja de Ahorro y Cuenta corriente',
        Reason = 'Aumento de limite LOA'
    	);
   		insert oldCase;
   		Case newCase = new Case(
    	Id = oldCase.Id,
    	OwnerId = testUser.Id,
        AccountId = acc.Id,
        Origin = 'Email',    
   		RecordTypeId =  solicitud.Id,
    	Status = 'Escalado',
        Type = 'Caja de Ahorro y Cuenta corriente',
        Reason = 'Aumento de limite LOA',
        Description = 'Test description',
    	Subject = 'Test subject'    
    	);
    	List<Case> newCases = new List<Case>{newCase};
        Map<Id, Case> oldCaseMap = new Map<Id, Case>{oldCase.Id => oldCase};
   		Test.startTest();
    	CaseStatusTriggerHandler.handleCaseStatus(newCases[0], oldCaseMap.get(newCases[0].Id));
    	Test.stopTest();
    }
    
    @isTest  
    public static void testHandleCommercialCase2(){
      	RecordType solicitud  = [SELECT Id, DeveloperName,SObjectType FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Solicitud' LIMIT 1];
     	User testUser = [SELECT Id FROM User WHERE IsActive = TRUE AND Email = 'cristian.moreno@itti.digital' LIMIT 1];
        
        Account acc = new Account(
        	Name = 'Test acc',
         	PersonCode__c = 123456,
    		AccountExecutiveEmail__c = 'cristian.moreno@itti.digital'
        );
        insert acc;

    	Case oldCase = new Case(
   		OwnerId = testUser.Id,
        AccountId = acc.Id,
		RecordTypeId =  solicitud.Id,
    	Status = 'Asignado',
    	Origin = 'Email',
    	Description = 'Test description',
    	Subject = 'Test subject',
        Type = 'Caja de Ahorro y Cuenta corriente',
        Reason = 'Aumento de limite LOA',
        CustomerServiceCenter__c = 'Palma'
    	);
   		insert oldCase;
   		Case newCase = new Case(
    	Id = oldCase.Id,
    	OwnerId = testUser.Id,
        AccountId = acc.Id,
        Origin = 'Email',    
   		RecordTypeId =  solicitud.Id,
    	Status = 'Escalado',
        Type = 'Caja de Ahorro y Cuenta corriente',
        Reason = 'Aumento de limite LOA',
        Description = 'Test description',
    	Subject = 'Test subject',
        CustomerServiceCenter__c = 'Palma'    
    	);
    	List<Case> newCases = new List<Case>{newCase};
        Map<Id, Case> oldCaseMap = new Map<Id, Case>{oldCase.Id => oldCase};
   		Test.startTest();
        CaseStatusTriggerHandler.handleCaseStatus(newCases[0], oldCaseMap.get(newCases[0].Id));
    	Test.stopTest();
    }

    @IsTest
    public static void testHandleCaseClienteDeEmpresa(){
        Case c = [SELECT Id, Type, AccountId, Vazquez_Group_Company__c FROM Case WHERE Subject = 'Test Case Handler' LIMIT 1];
        c.type = 'Cuenta corriente';
        update c;
        Test.startTest();
            CaseStatusTriggerHandler.handleCaseClienteDeEmpresa(c, null);
        Test.stopTest();
        List<Client_of_Company__c> clients = [SELECT Id FROM Client_of_Company__c WHERE Client__c = :c.AccountId];
        Assert.areNotEqual(null, clients);
    }

    @IsTest
    public static void testHandleCaseClienteDeEmpresaEmail(){
        Case c = [SELECT Id, Type, AccountId, Vazquez_Group_Company__c FROM Case WHERE Subject = 'Test Case Handler Tuti' LIMIT 1];
        Test.startTest();
            CaseStatusTriggerHandler.handleCaseClienteDeEmpresa(c, null);
        Test.stopTest();
        Case cUpdated = [SELECT Id, Email__c FROM Case WHERE Subject = 'Test Case Handler Tuti' LIMIT 1];
        Assert.areNotEqual('test@test.com', cUpdated.Email__c);
    }
        
}