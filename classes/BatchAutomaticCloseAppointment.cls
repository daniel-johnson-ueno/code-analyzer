/**
 * @name               : BatchAutomaticCloseAppointment
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 12-05-2025
 * @modification date  : 27-05-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Batch para cerrar las citas no gestionadas y sus casos
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   23-05-2025   Alvaro Gonzales Lapponi   Initial Version
**/
global with sharing class BatchAutomaticCloseAppointment implements Database.Batchable<SObject>, Schedulable {

    private static final String CLASS_NAME = 'BatchAutomaticCloseAppointment';
    private static final Integer RECORDS_PER_BATCH = 100;

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Status__c, Case__c, Case__r.Status ' +
                       'FROM Appointment__c ' +
                       'WHERE Status__c = \'Ingreso\' ' +
                       'AND RegistrationDateTime__c = YESTERDAY ' +
                       'AND Case__c != null';
        return Database.getQueryLocator(query);
    }

    /**
    * @description Método que se ejecuta con los registros obtenidos
    * @author Alvaro Gonzales Lapponi | 26-05-2025 
    * @param Database.BatchableContext bc 
    * @param List<Appointment__c> appointments 
    **/
    global void execute(Database.BatchableContext bc, List<Appointment__c> appointments) {
        try {
            List<Case> casesToUpdate = new List<Case>();
            List<Appointment__c> appointmentsToUpdate = new List<Appointment__c>();

            setDataToUpdate(appointments, casesToUpdate, appointmentsToUpdate);

            List<String> failedCaseIdsBatch = processUpdatesErrors(casesToUpdate, 'execute (Casos)');
            List<String> failedAppointmentIdsBatch = processUpdatesErrors(appointmentsToUpdate, 'execute (Citas)');

            logDMLErrors(failedCaseIdsBatch, 'casos', 'execute (Casos)');
            logDMLErrors(failedAppointmentIdsBatch, 'citas', 'execute (Citas)');

        } catch (Exception e) {
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), CLASS_NAME, 'execute');
        }
    }

    /**
    * @description Setea los registros de cita y caso por actualizar
    * @author Alvaro Gonzales Lapponi | 26-05-2025 
    * @param List<Appointment__c> appointments 
    * @param List<Case> casesToUpdate 
    * @param List<Appointment__c> appointmentsToUpdate 
    **/
    private void setDataToUpdate(List<Appointment__c> appointments, List<Case> casesToUpdate, List<Appointment__c> appointmentsToUpdate) {
        for (Appointment__c app : appointments) {
            if (app.Case__r != null && app.Case__r.Status == 'Nuevo') {
                app.Status__c = 'Cancelado';
                app.EndDateTime__c = System.now();

                Case c = new Case(
                    Id = app.Case__c,
                    Status = Label.CaseStatus_Close,
                    Type = 'Atencion digital',
                    Reason = 'No requiere gestion',
                    Subject = 'Cierre automático',
                    Description = 'Caso cerrado automáticamente desde Batch',
                    RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Consulta').getRecordTypeId(),
                    OwnerId = System.Label.qeTurneroClosedCase
                );

                appointmentsToUpdate.add(app);
                casesToUpdate.add(c);
            }
        }
    }

    /**
    * @description Guarda en una lista los errores del DML
    * @author Alvaro Gonzales Lapponi | 26-05-2025 
    * @param List<SObject> registros 
    * @param String contexto 
    * @return List<String> 
    **/
    private List<String> processUpdatesErrors(List<SObject> registros, String contexto) {
        List<String> errores = new List<String>();

        if (registros.isEmpty()) return errores;

        List<Database.SaveResult> results = Database.update(registros, false);

        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                Database.Error[] errs = results[i].getErrors();
                String mensaje = (errs.size() > 0) ? errs[0].getMessage() : 'Error desconocido';
                errores.add(registros[i].Id + ': ' + mensaje);
            }
        }
        return errores;
    }

    /**
    * @description Guarda logs de errores si los hubiera
    * @author Alvaro Gonzales Lapponi | 26-05-2025 
    * @param List<String> errores 
    * @param String entidad 
    * @param String contexto 
    **/
    private void logDMLErrors(List<String> errores, String entidad, String contexto) {
        if (!errores.isEmpty()) {
            generateErrorLogEventFromText(
                'Fallaron ' + errores.size() + ' ' + entidad + '. ' + String.join(errores, ', '),
                UserInfo.getUserId(),
                CLASS_NAME,
                contexto
            );
        }
    }


    global void finish(Database.BatchableContext bc) {
        system.debug('Proceso de cierre de citas sin gestionar finalizado');
    }

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchAutomaticCloseAppointment(), RECORDS_PER_BATCH);
    }

    private void generateErrorLogEventFromText(String errorMessage, String userId, String className, String methodName) {
        Generate_Error_Log__e newErrorLogEvent = new Generate_Error_Log__e();
        newErrorLogEvent.Running_User__c = userId;
        newErrorLogEvent.Class_Name__c = className;
        newErrorLogEvent.Method_Name__c = methodName;
        newErrorLogEvent.Error_Message__c = errorMessage;
        newErrorLogEvent.Line_Number__c = 'N/A';
        newErrorLogEvent.Execution_Date__c = Datetime.now();
        EventBus.publish(newErrorLogEvent);
    }
}