/**
 * @name               : turneroTurnoSolicitudController
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 26-11-2024
 * @modification date  : 10-03-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Clase controladora de lwc turneroTurnoSolicitudDetail
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   20-11-2024   Alvaro Gonzales Lapponi   Initial Version
**/
public with sharing class turneroTurnoSolicitudController {

    static final String CLASS_NAME							= 'turneroTurnoSolicitudController';
    static final String METHOD_FETCHCLIENTE					= 'fetchCliente';
    static final String METHOD_CHECKIN						= 'checkIn';
    static final String METHOD_SENDSMS						= 'sendSMS';
    
    static final String CASEORIGIN_TURNERO					= 'Turnero';
    
    static final string STATUS_CODE_INTERNAL_ERROR          = '-2';
    static final String STATUS_CODE_EXTERNAL_ERROR          = '-1';
    static final string STATUS_CODE_SUCCESS                 = '0'; 
    static final String EXCEPTION_MESSAGE = 'Generar Excepción desde turneroTurnoSolicitudController';
    @testVisible
    static Boolean SHOULD_THROW_EXCEPTION   = false; //NOPMD

    /**
    * @description 
    * @author Alvaro Gonzales Lapponi | 25-11-2024 
    * @param String tipoDocumento 
    * @param String numeroDocumento 
    * @return ResponseWrapperCliente 
    **/
    @AuraEnabled
    public static ResponseWrapperCliente fetchCliente(String tipoDocumento, String numeroDocumento){
        ResponseWrapperCliente response = new ResponseWrapperCliente();
        try{
            
            if( SHOULD_THROW_EXCEPTION && Test.isRunningTest() ){
                throw new AuraHandledException( EXCEPTION_MESSAGE );
            }
            ClientIdentificationHelper.Response clientResponse = ClientIdentificationHelper.verifyAndRetrieveClient(tipoDocumento, numeroDocumento);
            response.cliente = clientResponse.cliente;
            response.statusCode = STATUS_CODE_SUCCESS;
        } catch(Exception e){
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), CLASS_NAME, METHOD_FETCHCLIENTE);
            response.message = e.getStackTraceString() + ' ' + e.getMessage();
            response.statusCode = STATUS_CODE_INTERNAL_ERROR;
        }
        return response;
    }
    
    /**
    * @description 
    * @author Alvaro Gonzales Lapponi | 26-11-2024 
    * @param AppointmentData data
    * @param procedureAssignmentUtils.AppointmentConditions conditions
    * @return ResponseWrapperAppointment 
    **/
    @AuraEnabled(cacheable=false)
    public static ResponseWrapperAppointment checkIn(AppointmentData data, procedureAssignmentUtils.AppointmentConditions conditions) {
        ResponseWrapperAppointment response = new ResponseWrapperAppointment();
        try{
            
            if( SHOULD_THROW_EXCEPTION && Test.isRunningTest() ){
                throw new AuraHandledException( EXCEPTION_MESSAGE );
            }
            AppointmentRegistration.Request registrationData = setRegistrationData(data, conditions);
            Map<String,Id> registrationIds = AppointmentRegistration.queueAppointment(registrationData);
            response.caseId = registrationIds.get('case');
            response.appointmentId = registrationIds.keyset().contains('appointment') ? registrationIds.get('appointment') : null;
            response.statusCode = STATUS_CODE_SUCCESS;
        } catch(Exception e){
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), CLASS_NAME, METHOD_CHECKIN);
            response.statusCode = STATUS_CODE_INTERNAL_ERROR;
            response.message = e.getMessage() + ' ' + e.getStackTraceString();
        }
        return response;
    }
    
    /**
    * @description 
    * @author Alvaro Gonzales Lapponi | 10-03-2025 
    * @param AppointmentData data 
    * @param procedureAssignmentUtils.AppointmentConditions conditions 
    * @return AppointmentRegistration.Request 
    **/
    private static AppointmentRegistration.Request setRegistrationData(AppointmentData data, procedureAssignmentUtils.AppointmentConditions conditions){
        AppointmentRegistration.Request request = new AppointmentRegistration.Request();
        request.origin = CASEORIGIN_TURNERO;
        request.accountId = data.accountId;
        request.queueable = conditions.queueable;
        request.closedCase = conditions.closedCase;
        request.attentionProfile = conditions.queue;
        request.company = conditions.company;
        request.personType = data.tipoRepresentante;
        request.documentType = String.isNotBlank(data.tipoDocumento) ? data.tipoDocumento : null;
        request.documentNumber = String.isNotBlank(data.numeroDocumento) ? data.numeroDocumento : null;
        request.firstName = String.isNotBlank(data.nombreCliente) ? data.nombreCliente : null;
        request.lastName = String.isNotBlank(data.apellidoCliente) ? data.apellidoCliente : null;
        request.procedure = data.tramite;
        request.subprocedure = data.subtramite;
        request.requirePriority = data.requierePrioridad;
        request.phoneNumber = data.telefono;
        request.picture = data.foto;
        request.description = '';
        return request;
    }

    /**
    * @description Envío de SMS
    * @author Alvaro Gonzales Lapponi | 12-12-2024 
    * @param String phone 
    * @param String message 
    * @return ResponseWrapper 
    **/
    @AuraEnabled(cacheable=false)
    public static ResponseWrapper sendSMS(String phone, String message){
        ResponseWrapper response = new ResponseWrapper();
        try{
            
            if( SHOULD_THROW_EXCEPTION && Test.isRunningTest() ){
                throw new AuraHandledException( EXCEPTION_MESSAGE );
            }
            shortMessageService.Response smsResponse = shortMessageService.sendSMS(phone, message);
            if(!smsResponse.hasException){
                if(smsResponse.serviceResponse.code == 400){
                    response.statusCode = STATUS_CODE_EXTERNAL_ERROR;
                    response.message = smsResponse.serviceResponse.message;
                } else{
                    response.statusCode = STATUS_CODE_SUCCESS;
                }
                
            } else{
                response.statusCode = STATUS_CODE_EXTERNAL_ERROR;
                response.message = smsResponse.exceptionInfo.getMessage();
            }
        } catch(Exception e){
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), CLASS_NAME, METHOD_SENDSMS);
            response.statusCode = STATUS_CODE_INTERNAL_ERROR;
            response.message = e.getMessage();
        }
        return response;
    }

    public class AppointmentData{
        @AuraEnabled public String tipoRepresentante { get; set; }
        @AuraEnabled public String tipoDocumento { get; set; }
        @AuraEnabled public String numeroDocumento { get; set; }
        @AuraEnabled public String nombreCliente { get; set; }
        @AuraEnabled public String apellidoCliente { get; set; }
        @AuraEnabled public Id accountId { get; set; }
        @AuraEnabled public String telefono { get; set; }
        @AuraEnabled public String tramite { get; set; }
        @AuraEnabled public String subtramite { get; set; }
        @AuraEnabled public Boolean requierePrioridad { get; set; }
        @AuraEnabled public String foto { get; set; }
    }

    public class ResponseWrapperAppointment extends ResponseWrapper{
        @AuraEnabled public Id appointmentId;
        @AuraEnabled public Id caseId;
    }

    public class ResponseWrapperCliente extends ResponseWrapper{
        @AuraEnabled public ClientIdentificationHelper.Cliente cliente;
    }
    
    public class ResponseWrapperWorkTypes extends ResponseWrapper{
        @AuraEnabled public List<TipoWorkGroup> workTypeGroups;
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

    public class TipoWorkGroup{
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public Boolean prioritary;
        @AuraEnabled public String icon;
        @AuraEnabled public List<String> detalles;
    }

    public virtual class ResponseWrapper{
        @AuraEnabled public String message;
        @AuraEnabled public String statusCode;
    }
}