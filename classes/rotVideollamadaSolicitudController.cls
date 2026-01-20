/**
 * @name               : rotVideollamadaSolicitudController
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 10-03-2025
 * @modification date  : 10-03-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Clase controladora de lwc rotVideollamadaSolicitudDetail
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   10-03-2025   Alvaro Gonzales Lapponi   Initial Version
**/
public with sharing class rotVideollamadaSolicitudController {

    static final string STATUS_CODE_INTERNAL_ERROR          = '-2';
    static final string STATUS_CODE_SUCCESS                 = '0'; 
    
    static final String CASEORIGIN_TURNERO					= 'Turnero';
    static final Map<String,String> TIPODOCUMENTOFLOWMAP = new Map<String,String>{
        '1'=>'CEDULA DE IDENTIDAD PARAGUAYA',
        '2'=>'PASAPORTE',
        '6'=>'REGISTRO UNICO DEL CONTRIBUYENTE'
    };

    private static Account oficina;
    
    /**
    * @description Obtiene data de cliente
    * @author Alvaro Gonzales Lapponi | 10-03-2025
    * @param String tipoDocumento
    * @param String numeroDocumento
    * @return ResponseWrapperCliente 
    **/
    @AuraEnabled
    public static ResponseWrapperCliente fetchCliente(String tipoDocumento, String numeroDocumento){
        ResponseWrapperCliente response = new ResponseWrapperCliente();
        try{
            ClientIdentificationHelper.Response clientResponse = ClientIdentificationHelper.verifyAndRetrieveClient(tipoDocumento, numeroDocumento);
            response.cliente = clientResponse.cliente;
            response.nombreSucursal = getOffice().Name;
            response.statusCode = STATUS_CODE_SUCCESS;
        } catch(Exception e){
            response.message = e.getStackTraceString() + ' ' + e.getMessage();
            response.statusCode = STATUS_CODE_INTERNAL_ERROR;
        }
        return response;
    }
    
    /**
    * @description Obtiene casos abiertos provenientes de turnero, derivados a rot
    * @author Alvaro Gonzales Lapponi | 10-03-2025
    * @param String tipoDocumento
    * @param String numeroDocumento
    * @return ResponseWrapperCliente 
    **/
    @AuraEnabled(cacheable=true)
    public static ResponseWrapperCasos fetchTurneroOpenCases(String tipoDocumento, String numeroDocumento){
        ResponseWrapperCasos response = new ResponseWrapperCasos();
        try{
            Account office = getOffice();
            response.casos = new List<Caso>();
            List<Case> casos = [SELECT Id, CaseNumber, ClientProduct__c, ClientSubproduct__c
                                FROM Case
                                WHERE Origin =: CASEORIGIN_TURNERO AND Status = 'Nuevo' AND ROTDerivation__c = true
                                 AND DocumentType__c =: TIPODOCUMENTOFLOWMAP.get(tipoDocumento) AND DocumentNumber__c =: numeroDocumento
                                 AND CustomerServiceCenter__c =: office.Name AND CreatedDate = TODAY
                                WITH USER_MODE
                                ORDER BY CreatedDate DESC];
            for(Case c : casos){
                Caso caso = new Caso();
                caso.id = c.Id;
                caso.numeroCaso = c.CaseNumber;
                caso.detalle = String.isBlank(c.ClientSubproduct__c) ? c.ClientProduct__c : c.ClientProduct__c + ' / ' + c.ClientSubproduct__c;
                response.casos.add(caso);
            }
            response.statusCode = STATUS_CODE_SUCCESS;
        } catch(Exception e){
            response.message = e.getStackTraceString() + ' ' + e.getMessage();
            response.statusCode = STATUS_CODE_INTERNAL_ERROR;
        }
        return response;
    }

    private static Account getOffice(){
        if(oficina == null){
            Id userId = UserInfo.getUserId();
            User currentUser = [SELECT Office__c FROM User WHERE Id =: userId LIMIT 1];
            Decimal officeNumber = Decimal.valueOf(currentUser.Office__c);
            oficina = [
                SELECT Id, Name, ParentId, Parent.Name, Parent.GroupCompaniesUeno__c
                FROM Account
                WHERE Numero_Oficina__c =: officeNumber AND RecordType.DeveloperName = 'Internal_Company' AND Parent.GroupCompaniesUeno__c = 'UENO_BANK'
                LIMIT 1
            ];            
        }
        return oficina;
    }

    public virtual class ResponseWrapper{
        @AuraEnabled public String message;
        @AuraEnabled public String statusCode;
    }
    
    public class ResponseWrapperCliente extends ResponseWrapper{
        @AuraEnabled public ClientIdentificationHelper.Cliente cliente;
        @AuraEnabled public String nombreSucursal;
    }
    
    public class ResponseWrapperCasos extends ResponseWrapper{
        @AuraEnabled public List<Caso> casos;
    }
    
    public class Caso{
        @AuraEnabled public Id id;
        @AuraEnabled public String numeroCaso;
        @AuraEnabled public String detalle;
    }
}