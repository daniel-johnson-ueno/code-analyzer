/**
 * @name               : AppointmentQueueHelper
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 18-03-2025
 * @modification date  : 24-04-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Clase test de AppointmentQueueHelper
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   18-03-2025   Alvaro Gonzales Lapponi   Initial Version
 * 1.1   24-04-2025   Alvaro Gonzales Lapponi   Se cambió a 2 la cantidad de horas previas para realizar el cálculo de tiempo promedio
**/
public with sharing class AppointmentQueueHelper {
    
    static final Decimal UNIT_WAIT_TIME_DEFAULT = 10;
    static final Integer HOURS_BEFORE_FOR_CLOSE_APPOINTMENTS = 2;
    static final List<String> APPOINTMENT_STATUS_ENDED_LIST = new List<String>{'Finalizado','Cancelado','Abandonado'};
    @testVisible
    static Integer AVAILABLE_AGENTS_TEST   = 1;
    
    /**
    * @description 
    * @author Alvaro Gonzales Lapponi | 08-03-2025 
    * @param Id appointmentId
    * @return WaitingInfoWrapper
    **/ 
    public static WaitingInfoWrapper getAppointmentWaitingInfo(Id appointmentId) {
        WaitingInfoWrapper waitingInfo = new WaitingInfoWrapper();
        
        // Obtener la cita objetivo
        Appointment__c targetAppointment = getTargetAppointmentFromDB(appointmentId);
        if( APPOINTMENT_STATUS_ENDED_LIST.contains(targetAppointment.Status__c) ){
            waitingInfo.status = targetAppointment.Status__c;
            return waitingInfo;
        }
        if (targetAppointment == null) {
            return getDefaultResult(0, 'No Existe');
        }
        Integer numberOfAvailableAgents = getAvailableAgentsFromDB(targetAppointment);
        if (numberOfAvailableAgents == 0) {
            return getDefaultResult(-1, targetAppointment.Status__c);
        }
        waitingInfo.availableAdvisors = true;
        List<Appointment__c> previousAppointments = getPreviousAppointmentsFromDB(targetAppointment);
        Integer numberOfPeopleBefore = previousAppointments.size();
        Decimal unitWaitingTime = getUnitWaitingTime(targetAppointment);
        Decimal estimatedWaitingTime = calculateEstimatedWaitingTime(numberOfPeopleBefore, unitWaitingTime, numberOfAvailableAgents);

        // Retornar resultados
        waitingInfo.numberOfPeopleBefore = numberOfPeopleBefore;
        waitingInfo.estimatedWaitingTime = estimatedWaitingTime;
        waitingInfo.status = targetAppointment.Status__c;
        waitingInfo.advisorName = targetAppointment.Owner.Name;
        system.debug(waitingInfo);
        return waitingInfo;
    }
    
    /**
    * @description 
    * @author Alvaro Gonzales Lapponi | 08-03-2025 
    * @param Id appointmentId
    * @return Appointment__c
    **/ 
    private static Appointment__c getTargetAppointmentFromDB(Id appointmentId) {
        return [
            SELECT Id, AttentionType__c, Status__c, ExperienceCenter__c, Owner.Name, RegistrationDateTime__c,RequirePriorityAttention__c
            FROM Appointment__c
            WHERE Id = :appointmentId
            LIMIT 1
        ];
    }

    /**
    * @description 
    * @author Alvaro Gonzales Lapponi | 08-03-2025 
    * @param String skill
    * @return List<Contact>
    **/ 
    private static Integer getAvailableAgentsFromDB(Appointment__c targetAppointment) {
        Integer numberOfAvailableAgents = 0;
        Set<Id> servicePresenceIds = new Set<Id>();
        List<String> skills = targetAppointment.AttentionType__c.split(';');
        List<String> conditions = new List<String>();
        for (String s : skills) {
            conditions.add('\'' + s + '\'');
        }
        
        if(Test.isRunningTest()){
            numberOfAvailableAgents = AVAILABLE_AGENTS_TEST;
        } else{
            List<UserServicePresence> servicePresenceList = turneroTurnoConsultaActualizacionHelper.getTurneroAvailablePresenceUsers();
            for(UserServicePresence servicePresence : servicePresenceList){
                servicePresenceIds.add(servicePresence.UserId);
            }
            
            String query = 'SELECT Id, Skills__c FROM Contact WHERE AccountId = \'' + targetAppointment.ExperienceCenter__c  + '\' ' +
                			'AND Skills__c INCLUDES (' + String.join(conditions, ', ') + ') ' +
                			'AND UserId__c IN :servicePresenceIds';
            List<Contact> availableAgents = Database.query(query, AccessLevel.USER_MODE);
            numberOfAvailableAgents = availableAgents.size();
        }
        return numberOfAvailableAgents;
    }
    
    /**
    * @description 
    * @author Alvaro Gonzales Lapponi | 08-03-2025 
    * @param Appointment__c targetAppointment
    * @return List<Appointment__c>
    **/ 
    private static List<Appointment__c> getPreviousAppointmentsFromDB(Appointment__c targetAppointment) {
        List<String> skills = targetAppointment.AttentionType__c.split(';');
        List<String> conditions = new List<String>();
        for (String s : skills) {
            conditions.add('\'' + s + '\'');
        }
        String skillsCondition = String.join(conditions, ', ');
        String dateFormatted = targetAppointment.RegistrationDateTime__c.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        String waitingStatusString = '\'Ingreso\'';
        
        String baseConditions = 
            'Status__c IN (' + waitingStatusString + ') ' +
            'AND AttentionType__c INCLUDES (' + skillsCondition + ') ' +
            'AND ExperienceCenter__c = \'' + targetAppointment.ExperienceCenter__c + '\' ' +
            'AND RegistrationDateTime__c >= TODAY ';
        
        String query = '';
        
        if (targetAppointment.RequirePriorityAttention__c) {
            // Si tiene prioridad
            query = 'SELECT Id FROM Appointment__c WHERE ' + baseConditions +
                'AND RequirePriorityAttention__c = true ' +
                'AND RegistrationDateTime__c < ' + dateFormatted + ' ';
        } else {
            // Si NO tiene prioridad
            query = 'SELECT Id FROM Appointment__c WHERE ' + baseConditions +
                'AND ( ' +
                'RequirePriorityAttention__c = true OR ' +
                '(RequirePriorityAttention__c = false AND RegistrationDateTime__c < ' + dateFormatted + ') ' +
                ')';
        }
        
        query += ' ORDER BY RequirePriorityAttention__c DESC, RegistrationDateTime__c ASC';
        
        return (List<Appointment__c>) Database.query(query, AccessLevel.USER_MODE);
    }


    /**
    * @description 
    * @author Alvaro Gonzales Lapponi | 08-03-2025 
    * @param Appointment__c targetAppointment
    * @return Decimal
    **/ 
    private static Decimal getUnitWaitingTime(Appointment__c targetAppointment) {
        Decimal unitWaitingTime = UNIT_WAIT_TIME_DEFAULT;
        List<String> skills = targetAppointment.AttentionType__c.split(';');
        List<String> conditions = new List<String>();
        for (String s : skills) {
            conditions.add('\'' + s + '\'');
        }
        Decimal summarizedHoursDuration = 0;
        Datetime nHoursAgo = Datetime.now().addHours(-1 * HOURS_BEFORE_FOR_CLOSE_APPOINTMENTS);
        
        String query = 'SELECT Id, AttentionDurationInMinutes__c FROM Appointment__c ' +
                       'WHERE Status__c = \'Finalizado\' ' +
                    	 'AND AttentionType__c INCLUDES (' + String.join(conditions, ', ') + ') ' +
            			 'AND ExperienceCenter__c = \'' + targetAppointment.ExperienceCenter__c + '\' ' +
            			 'AND EndDateTime__c > ' + nHoursAgo.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') + ' ' +
             			 'AND AttentionDurationInMinutes__c != NULL';
        
        List<Appointment__c> finishedAppointments = Database.query(query, AccessLevel.USER_MODE);

        if(!finishedAppointments.isEmpty()){
            for (Appointment__c finished : finishedAppointments) {
                summarizedHoursDuration += finished.AttentionDurationInMinutes__c;
            }
            unitWaitingTime = summarizedHoursDuration / finishedAppointments.size();
        }
        

        return unitWaitingTime;
    }

    private static Decimal calculateEstimatedWaitingTime(Integer nPreviousAppointments, Decimal realDurations, Integer availableAgentsCount) {
        Decimal totalWaitingTime = realDurations * nPreviousAppointments;
        return availableAgentsCount > 0 ? (Decimal) totalWaitingTime / (Decimal) availableAgentsCount : 0;
    }
    
    private static Id getQueueIdByAccountName(String accountName) {
        return [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND DeveloperName =:accountName WITH USER_MODE LIMIT 1].Id;
    }

    private static WaitingInfoWrapper getDefaultResult(Integer defaultValue, String status) {
        WaitingInfoWrapper waitingInfo = new WaitingInfoWrapper();
        if(defaultValue == -1){
            waitingInfo.availableAdvisors = false;
        }
        waitingInfo.numberOfPeopleBefore = defaultValue;
        waitingInfo.estimatedWaitingTime = defaultValue;
        waitingInfo.status = status;
        system.debug(waitingInfo);
        return waitingInfo;
    }
    
    public class WaitingInfoWrapper{
        public Boolean availableAdvisors;
        public Integer numberOfPeopleBefore;
        public Decimal estimatedWaitingTime;
        public String status;
        public String advisorName;
    }
}