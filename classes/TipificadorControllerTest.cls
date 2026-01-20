@isTest
public class TipificadorControllerTest {
    
    @testSetup
    public static void setup(){
        
       	Ueno_Service_Domain__c testUrl= new Ueno_Service_Domain__c(ApiKey__c = '555-555-555',DomainName__c='https://kongcloud.ind-dev-sae1.ueno.com.py');
       	insert testUrl;
        
        Account accountObject = (Account)TestFactoryFramework.createSObject(new Account(), 'TestFactoryFrameworkDefaults.PersonAccountDefaults', false);
        insert accountObject;
        
        Account testUenoAcc = (Account)TestFactoryFramework.createSObject(new Account(), 'TestFactoryFrameworkDefaults.InternalCompanyAccountDefaults', false);
        testUenoAcc.Name = 'Ueno Bank SA';
        testUenoAcc.GroupCompaniesUeno__c = 'Ueno Bank SA';
        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Vazquez_Group_Company');
        String recordTypeId = recordTypeInfo.getRecordTypeId();
        testUenoAcc.RecordTypeId = recordTypeId;
        insert testUenoAcc;

        Case caseTestReclamo = (Case)TestFactoryFramework.createSObject(new Case(), 'TestFactoryFrameworkDefaults.ReclamoCaseDefaults', false);
        caseTestReclamo.Reason = 'Bajé de nivel y no correspondía';
        caseTestReclamo.Type = 'Loyalty';
        caseTestReclamo.Status = 'Escalado';
        caseTestReclamo.Origin = 'Turnero';
        insert caseTestReclamo;

        Case caseTestSolicitud = (Case)TestFactoryFramework.createSObject(new Case(), 'TestFactoryFrameworkDefaults.SolicitudCaseDefaults', false);
        caseTestSolicitud.Reason = 'Apertura segunda caja de ahorro';
        caseTestSolicitud.Type = 'Caja de ahorro';
        caseTestSolicitud.Status = 'Escalado';
        caseTestSolicitud.Origin = 'BOT';
        insert caseTestSolicitud;
    }

    @isTest
    public static void testGetTipificadores(){
        Test.startTest();
        List<Case_Derivation_Rules__mdt> tip = TipificadorController.getTipificadores('UENO_BANK');
        Test.stopTest();
		Assert.areEqual(true, !tip.isEmpty(), 'Debe obtener registros de metadata');
    }
    
    @isTest
    public static void testGetTipificadoresCompanies(){
        Test.startTest();
        List<Account> tip = TipificadorController.getCompanies();
        Test.stopTest();
		Assert.areEqual(true, !tip.isEmpty(), 'Debe obtener registros de cuenta');
    }

    @isTest
    public static void testGetTipificadoresByType(){
        Test.startTest();
        List<Case_Derivation_Rules__mdt> tip = TipificadorController.getTipificadoresByType('Loyalty');
        Test.stopTest();
        Assert.areEqual(true, !tip.isEmpty(), 'Debe obtener registros de metadata');
    }

    @isTest
    public static void testGetRequiredFields(){
        Test.startTest();
        List<Case_Derivation_Rules__mdt> requiredFields = TipificadorController.getRequiredFields('Turnero','Caja de ahorro','Apertura segunda caja de ahorro|Solicitud');
        Test.stopTest();
        Assert.areEqual(true, !requiredFields.isEmpty(), 'Debe obtener registros de metadata');
    }
    @isTest
    public static void testGetRequiredFieldsDigital(){
        Test.startTest();
        List<Case_Derivation_Rules__mdt> requiredFields = TipificadorController.getRequiredFields('BOT','Caja de ahorro','Apertura segunda caja de ahorro|Solicitud');
        Test.stopTest();
        Assert.areEqual(true, !requiredFields.isEmpty(), 'Debe obtener registros de metadata');
    }
    
    @isTest
    public static void testGetRequiredFieldsSolicitud(){
        Test.startTest();
        List<Case_Derivation_Rules__mdt> requiredFields = TipificadorController.getRequiredFields('BOT','Tarjetas procesamiento','Levantamiento de parámetros compras web|Solicitud');
        Test.stopTest();
        Assert.areEqual(true, !requiredFields.isEmpty(), 'Debe obtener registros de metadata');
    }
    
    @isTest
    public static void testGetRequiredFieldsPresencial(){
        Test.startTest();
        List<Case_Derivation_Rules__mdt> requiredFields = TipificadorController.getRequiredFields('ROT','Caja de ahorro','Apertura segunda caja de ahorro|Solicitud');
        Test.stopTest();
        Assert.areEqual(true, !requiredFields.isEmpty(), 'Debe obtener registros de metadata');
    }
    

    @isTest
    public static void testUpdateCaseRequiredFieldsDT(){
        Id caseId = [SELECT Id FROM Case WHERE Origin = 'Turnero' LIMIT 1].Id;
        Map<String,String> fieldValues = new Map<String,String>{
            'DateTime__c' => '2024-12-01'
        };
        Test.startTest();
        TipificadorController.updateCaseRequiredFields(caseId,fieldValues,'Bajé de nivel y no correspondía|Reclamo','Loyalty', 'UENO_BANK', 'subject','description');
        Test.stopTest(); 
        List<Case> cases = [SELECT Id, Type FROM Case WHERE Id = :caseId];
        Assert.areEqual('Loyalty', cases[0].Type, 'No se actualizo el caso correctamente');
    }
    
    @isTest
    public static void testUpdateCaseRequiredFields(){
        Id caseId = [SELECT Id FROM Case WHERE Origin = 'Turnero' LIMIT 1].Id;
        Map<String,String> fieldValues = new Map<String,String>{
            'AccountType__c' => 'Cuenta Corriente',
            'CurrencyIsoCode ' => 'PYG', 
            'OperationNumber__c' => '111111',
            'Payment_method__c' => 'TD'
        };
        Test.startTest();
        TipificadorController.updateCaseRequiredFields(caseId,fieldValues,'Apertura segunda caja de ahorro|Solicitud','Caja de ahorro', 'UENO_BANK','subject','description');
        Test.stopTest(); 
        List<Case> cases = [SELECT Id, Type FROM Case WHERE Id = :caseId];
        Assert.areEqual('Caja de ahorro', cases[0].Type, 'No se actualizo el caso correctamente');
    }
    
    @isTest
    public static void testUpdateCaseRequiredFieldsdDig(){
        Id caseId = [SELECT Id FROM Case WHERE Origin = 'BOT' LIMIT 1].Id;
        Map<String,String> fieldValues = new Map<String,String>{
            'AccountType__c' => 'Cuenta Corriente',
            'CurrencyIsoCode ' => 'PYG', 
            'OperationNumber__c' => '111111',
            'Payment_method__c' => 'TD'
        };
        Test.startTest();
        TipificadorController.updateCaseRequiredFields(caseId,fieldValues,'Apertura segunda caja de ahorro|Solicitud','Caja de ahorro', 'UENO_BANK','subject','description');
        Test.stopTest(); 
        List<Case> cases = [SELECT Id, Type FROM Case WHERE Id = :caseId];
        Assert.areEqual('Caja de ahorro', cases[0].Type, 'No se actualizo el caso correctamente');
    }
    
    @isTest
    public static void testCreateCase(){
        Id caseId = [SELECT Id FROM Case WHERE Origin = 'Turnero' LIMIT 1].Id;
        Map<String,String> fieldValues = new Map<String,String>{
            'Origin' => 'Turnero',
            'Subject ' => 'test subject',
            'Description ' => 'test description'   
        };
        Test.startTest();
        TipificadorController.createCase(null,fieldValues,'Apertura segunda caja de ahorro|Solicitud','Caja de ahorro', null, null);
        Test.stopTest(); 
        List<Case> cases = [SELECT Id, Type FROM Case WHERE Type = 'Caja de ahorro'];
        Assert.areEqual(true, !cases.isEmpty(), 'No se creo el caso correctamente');
    }
    
    @isTest
    public static void testCreateCaseDig(){
        Id caseId = [SELECT Id FROM Case WHERE Origin = 'Turnero' LIMIT 1].Id;
        Map<String,String> fieldValues = new Map<String,String>{
            'Origin' => 'BOT',
            'Subject ' => 'test subject',
            'Description ' => 'test description'   
        };
        Test.startTest();
        TipificadorController.createCase(null,fieldValues,'Apertura segunda caja de ahorro|Solicitud','Caja de ahorro', null, null);
        Test.stopTest(); 
        List<Case> cases = [SELECT Id, Type FROM Case WHERE Type = 'Caja de ahorro'];
        Assert.areEqual(true, !cases.isEmpty(), 'No se creo el caso correctamente');
    }
    
    @isTest
    public static void testCreateCaseConsulta(){
        Id caseId = [SELECT Id FROM Case WHERE Origin = 'Turnero' LIMIT 1].Id;
        Map<String,String> fieldValues = new Map<String,String>{
            'Origin' => 'Turnero',
            'Subject ' => 'test subject',
            'Description ' => 'test description',  
            'Datetime__c ' => '20-03-2025,00:00:00Z'
        };
        Test.startTest();
        TipificadorController.createCase(null,fieldValues,'Re contacto|Consulta','Atencion Telefonica', null, 'Ueno Bank SA');
        Test.stopTest(); 
        List<Case> cases = [SELECT Id, Type FROM Case WHERE Type = 'Caja de ahorro'];
        Assert.areEqual(true, !cases.isEmpty(), 'No se creo el caso correctamente');
    }
    
    @isTest
    public static void testCheckIfIsFirstAssign(){
        Case c = [SELECT Id, Status FROM Case WHERE RecordType.Name = 'Reclamo' LIMIT 1];
        Test.startTest();
        c.Subject = 'subj';
        c.Description = 'desc';
        c.Status = 'Asignado';
        update c;
        Boolean isSecondAAssignment = TipificadorController.checkIfIsFirstAssign(c.Id);
        Test.stopTest();
        Assert.areEqual(true, !isSecondAAssignment, 'No verifica correctamente el historico de estados.');
    }
   
    @isTest
    public static void testGetObjectType(){
        Case c = [SELECT Id, RecordTypeId FROM Case WHERE Origin = 'Turnero' LIMIT 1];
        Test.startTest();
        String rtName = TipificadorController.getObjectType(c.Id);
        Test.stopTest();
        Assert.areEqual(rtName, 'Case', 'No se obtiene correctamente el tipo de objeto.');
    }
    
    @isTest
    public static void testGetPersonAccountContact(){
        Account acc = [SELECT Id  FROM Account WHERE Name != 'Ueno Bank SA' LIMIT 1];
        Test.startTest();
        Contact con = TipificadorController.getPersonAccountContact(acc.Id);
        Test.stopTest();
        Assert.areNotEqual(con,null,'No se obtiene correctamente el contacto relacionado.');
    }
    
   	@isTest
    public static void testGetAccountCompanyKey(){
        Account acc = [SELECT Id FROM Account WHERE Name = 'Ueno Bank SA' LIMIT 1];
        Test.startTest();
        String accUenoName = TipificadorController.getAccountCompanyKey(acc.Id);
        Test.stopTest();
        Assert.areEqual(accUenoName,'Ueno Bank SA', 'No se obtiene correctamente la cuenta empresa.') ;
    }
}