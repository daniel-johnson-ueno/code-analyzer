/**
 * @name               : ClientIdentificationHelper
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 10-02-2025
 * @modification date  : 12-03-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Busca clientes en SF, Bankitti e IDL. Si es necesario hace inserts en Salesforce
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   10-02-2025   Alvaro Gonzales Lapponi   Initial Version
 * 1.0   28-03-2025   Alvaro Gonzales Lapponi   Setea el campo Type_and_Document_Number__c
**/
public with sharing class ClientIdentificationHelper {

    static final String CLIENT_ESTADO_EXISTE_EN_SALESFORCE  = 'Existente en Salesforce';
    static final String CLIENT_ESTADO_NUEVO_EN_SALESFORCE   = 'Nuevo en Salesforce';
    static final String CLIENT_ESTADO_NO_CLIENTE            = 'No Cliente';

    static final Map<String,String> TIPODOCUMENTOBFFMAP = new Map<String,String>{
        '1'=>'cedulaIdentidad',
        '2'=>'pasaporte',
        '6'=>'cuil'
    };
                
    static final Map<String,String> ACCOUNT_RECORDTYPE = new Map<String,String>{
        'Persona' => 'PersonAccount',
        'Empresa' => 'IndustriesBusiness'
    };
       
    /**
    * @description Proceso de obtención de cliente que orquesta entre Salesforce, Bankiti, IDL
    * @author Alvaro Gonzales Lapponi | 30-01-2025 
    * @param String tipoDocumento
    * @param String numeroDocumento
    * @return Cliente
    **/ 
    public static Response verifyAndRetrieveClient(String tipoDocumento, String numeroDocumento){
        Response response = new Response();
        Response.cliente = new Cliente();
        response.cliente.tipoDocumento = tipoDocumento;
        response.cliente.numeroDocumento = numeroDocumento;
        response.cliente.esCliente = false;
        response.cliente.noReconocido = false;
        
        List<Account> accList = [SELECT Id, Name, Phone, isPersonAccount
                                 FROM Account WHERE DocumentNumber__c =: numeroDocumento AND DocumentType__c =: tipoDocumento
                                 WITH USER_MODE LIMIT 1];
        if(!accList.isEmpty()){
            Account acc = accList[0];
            response.cliente.esCliente = true;
            response.cliente.accountId = acc.Id;
            response.cliente.esPersona = acc.isPersonAccount;
            response.cliente.fullName = acc.Name;
            response.cliente.telefono = acc.Phone != '0' ? acc.Phone : null;
            response.estado = CLIENT_ESTADO_EXISTE_EN_SALESFORCE;
        } else{
            personSearchIDL.Response responseIDL = personSearchIDL.searchIsCustomer(TIPODOCUMENTOBFFMAP.get(tipoDocumento), numeroDocumento);
            response.cliente.esPersona = processTipoRepresentante(tipoDocumento);
            if(!responseIDL.hasException && String.isNotBlank(responseIDL.serviceResponse.firstName)){
                response.cliente.esCliente = processEsCliente(responseIDL.serviceResponse);
                response.cliente.fullName = processFullName(responseIDL.serviceResponse);
                response.cliente.nombre =  responseIDL.serviceResponse.firstName;
                response.cliente.apellido =  responseIDL.serviceResponse.lastName;
                response.cliente.telefono =  responseIDL.serviceResponse.phone != '0' ? responseIDL.serviceResponse.phone : null;
                
                Account acc = new Account();
                if(response.cliente.esCliente){
                    acc = createPendingAccount(response.cliente);
                    response.cliente.accountId = acc.Id;
                    response.estado = CLIENT_ESTADO_NUEVO_EN_SALESFORCE;
                } 
            } else{
                response.estado = CLIENT_ESTADO_NO_CLIENTE;
                
            } 
        }
        
        if (!response.cliente.esCliente && response.cliente.accountId == null) {
            
            String orgId15 = UserInfo.getOrganizationId().substring(0, 15);
            General_Setting__mdt generalSettings = [SELECT No_Cliente_Id__c FROM General_Setting__mdt WHERE Id__c =: orgId15 LIMIT 1];
            Account acc = new Account();
            if(Test.isRunningTest()){
                acc = [SELECT Id
                       FROM Account WHERE Name = 'No Cliente'
                       WITH USER_MODE LIMIT 1];
            }else{
                acc = [SELECT Id
                       FROM Account WHERE Id =: generalSettings.No_Cliente_Id__c
                       WITH USER_MODE LIMIT 1];
            }
            response.cliente.noReconocido = String.isBlank(response.cliente.fullName);
            response.cliente.accountId = acc.Id;
            response.estado = CLIENT_ESTADO_NO_CLIENTE;
        }
        return response;
    }
    
    /**
    * @description Si retorna true es persona, si retorna false es empresa
    * @author Alvaro Gonzales Lapponi | 30-01-2025 
    * @param String tipoDocumento 
    * @return Boolean 
    **/
    private static Boolean processTipoRepresentante(String tipoDocumento){
        if(tipoDocumento=='1' || tipoDocumento=='2'){
            return true;
        } else{
            return false;
        }
    }
    
    /**
    * @description Procesa la respuesta de la API para verificar si es cliente en Bankiti o no
    * @author Alvaro Gonzales Lapponi | 30-01-2025 
    * @param personSearchIDL.ServiceResponse serviceResponse 
    * @return Boolean 
    **/
    private static Boolean processEsCliente(personSearchIDL.ServiceResponse serviceResponse){
        return (String.isNotBlank(serviceResponse.email) || String.isNotBlank(serviceResponse.customerNumber) || String.isNotBlank(serviceResponse.phone));
    }
    
    /**
    * @description Obtiene el nombre completo de un cliente
    * @author Alvaro Gonzales Lapponi | 30-01-2025 
    * @param personSearchIDL.ServiceResponse serviceResponse 
    * @return String 
    **/
    private static String processFullName(personSearchIDL.ServiceResponse serviceResponse){
        List<String> nameParts = new List<String>();
        
        if (String.isNotBlank(serviceResponse.firstName)) {
            nameParts.add(serviceResponse.firstName);
        }
        if (String.isNotBlank(serviceResponse.lastName)) {
            nameParts.add(serviceResponse.lastName);
        }
        
        return String.join(nameParts, ' ');
    }
    
    /**
    * @description Crea Cuenta cuando esta existía en Bankiti pero no en Salesforce
    * @author Alvaro Gonzales Lapponi | 12-03-2025 
    * @param Cliente cliente 
    * @return Account 
    **/
    private static Account createPendingAccount(Cliente cliente){
        String rtDeveloperName;
        Account acc = new Account();
        acc.DocumentType__c = cliente.tipoDocumento;
        acc.DocumentNumber__c = cliente.numeroDocumento;
        acc.Type_and_Document_Number__c = cliente.tipoDocumento + '_' + cliente.numeroDocumento;
        if(cliente.esPersona){
            rtDeveloperName = ACCOUNT_RECORDTYPE.get('Persona');
            acc.FirstName = cliente.nombre;
            acc.LastName = cliente.apellido;
        } else{
            rtDeveloperName = ACCOUNT_RECORDTYPE.get('Empresa');
            acc.Name = cliente.fullName;
        }
        acc.RecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get(rtDeveloperName).getRecordTypeId();
        database.insert(acc,AccessLevel.USER_MODE);
        return acc;
    }
    
    public class Response{
        public String estado;
        public Cliente cliente;
    }
    
    public class Cliente{
        @AuraEnabled public Boolean esCliente;
        @AuraEnabled public Id accountId;
        @AuraEnabled public String nombre;
        @AuraEnabled public String apellido;
        @AuraEnabled public String fullName;
        @AuraEnabled public String telefono;
        @AuraEnabled public String tipoDocumento;
        @AuraEnabled public String numeroDocumento;
        @AuraEnabled public Boolean esPersona;
        @AuraEnabled public Boolean noReconocido;
    }
}