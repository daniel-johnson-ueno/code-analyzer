/**
 * @name               : turneroTurnoConsultaActualizacionHelper
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 21-03-2025
 * @modification date  : 21-03-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Clase helper without sharing que permite actualizar registros para Guest Users
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   21-03-2025   Alvaro Gonzales Lapponi   Initial Version
**/
public without sharing class turneroTurnoConsultaActualizacionHelper {
    
    /**
    * @description Método que permite actualizar registros de cita en modo without sharing
    * @author Alvaro Gonzales Lapponi | 21-03-2025
    * @param Appointment__c appointment
    **/
    public static void updateAppointment(Appointment__c appointment){
        database.update(appointment, AccessLevel.SYSTEM_MODE);
    }
    
    /**
    * @description Método obtiene asesores en estado de presencia Disponible_Turnero en modo without sharing
    * @author Alvaro Gonzales Lapponi | 21-03-2025
    * @return List<UserServicePresence>
    **/
    public static List<UserServicePresence> getTurneroAvailablePresenceUsers(){
        return [SELECT Id, UserId FROM UserServicePresence WHERE IsCurrentState = true AND ServicePresenceStatus.DeveloperName = 'Disponible_Turnero' WITH SYSTEM_MODE];
    }

    public static void updateCase(Case cas) {
        database.update(cas, AccessLevel.SYSTEM_MODE);
    }

}