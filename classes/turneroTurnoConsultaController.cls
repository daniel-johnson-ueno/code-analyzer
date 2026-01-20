/**
 * @name               : turneroTurnoConsultaController
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 10-12-2024
 * @modification date  : 22-05-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Clase controladora de lwc turneroTurnoConsultaDetail
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   18-03-2024   Alvaro Gonzales Lapponi   Initial Version
**/
public with sharing class turneroTurnoConsultaController {

    static final string STATUS_CODE_SUCCESS                 = '0'; 
    static final string STATUS_CODE_INTERNAL_ERROR          = '-2';
    static final String EXCEPTION_MESSAGE = 'Generar Excepción desde turneroTurnoConsultaController';
    @testVisible
    static Boolean SHOULD_THROW_EXCEPTION   = false; //NOPMD
    
    /**
    * @description Método que obtiene la información del tiempo de espera y personas delante
    * @author Alvaro Gonzales Lapponi | 25-11-2024 
    * @param Id appointmentId
    * @return ResponsePositionWrapper 
    **/
    @AuraEnabled(cacheable=false)
    public static ResponsePositionWrapper getPosition(Id appointmentId) {
        ResponsePositionWrapper response = new ResponsePositionWrapper();
        try{
            
            if( SHOULD_THROW_EXCEPTION && Test.isRunningTest() ){
                throw new AuraHandledException( EXCEPTION_MESSAGE );
            }
            
            response.positionData = new PositionData();
            AppointmentQueueHelper.WaitingInfoWrapper positionInfo = AppointmentQueueHelper.getAppointmentWaitingInfo(appointmentId);
            response.positionData.asesoresDisponibles = positionInfo.availableAdvisors;
            response.positionData.personasAntes = positionInfo.numberOfPeopleBefore;
            response.positionData.tiempoRestanteMinutos = positionInfo.estimatedWaitingTime;
            response.positionData.nombreAsesor = positionInfo.advisorName;
            response.positionData.estado = positionInfo.status;
            response.statusCode = STATUS_CODE_SUCCESS;
        } catch(Exception e){
            response.statusCode = STATUS_CODE_INTERNAL_ERROR;
            response.message = e.getStackTraceString() + ' ' + e.getMessage();
        }
        return response;
    }
    
    /**
    * @description Método que cancela la cita a solicitud del cliente
    * @author Alvaro Gonzales Lapponi | 25-11-2024 
    * @param Id appointmentId
    * @return ResponseWrapper 
    **/
    @AuraEnabled(cacheable=false)
    public static ResponseWrapper cancelAppointment(Id appointmentId) {
        ResponseWrapper response = new ResponseWrapper();
        try{
            
            if( SHOULD_THROW_EXCEPTION && Test.isRunningTest() ){
                throw new AuraHandledException( EXCEPTION_MESSAGE );
            }
            
            Appointment__c appointment = [SELECT Id, Status__c ,Case__c FROM Appointment__c WHERE Id =: appointmentId];
            Case cas = [SELECT Id  FROM Case WHERE Id =: appointment.Case__c];
            cas.Client_left__c = true;
            cas.AutomaticClosure__c = true;
            cas.OwnerId = System.Label.qeTurneroClosedCase;

            appointment.Status__c = 'Abandonado';
            turneroTurnoConsultaActualizacionHelper.updateAppointment(appointment);
            turneroTurnoConsultaActualizacionHelper.updateCase(cas);

            response.statusCode = STATUS_CODE_SUCCESS;
        } catch(Exception e){
            response.statusCode = STATUS_CODE_INTERNAL_ERROR;
            response.message = e.getStackTraceString() + ' ' + e.getMessage();
        }
        return response;
    }
    
    /**
    * @description Método que obtiene el tiempo configurado de refresco de consulta
    * @author Alvaro Gonzales Lapponi | 25-11-2024 
    * @return Integer - Tiempo de refresco 
    **/
    @AuraEnabled(cacheable=true)
    public static Integer getRefreshPeriod() {
        Turnero__mdt mdtRecord = Turnero__mdt.getInstance('AutoUpdateAppointmentTracking');
        return Integer.valueOf(mdtRecord.Field__c);
    }
    
    public class ResponsePositionWrapper extends ResponseWrapper{
        @AuraEnabled public PositionData positionData;
    }
    
    public class PositionData{
        @AuraEnabled public Boolean asesoresDisponibles;
        @AuraEnabled public Integer personasAntes;
        @AuraEnabled public Decimal tiempoRestanteMinutos;
        @AuraEnabled public String nombreAsesor;
        @AuraEnabled public Boolean finalizado;
        @AuraEnabled public String estado;
    }
    
    public virtual class ResponseWrapper{
        @AuraEnabled public String message;
        @AuraEnabled public String statusCode;
    }

}