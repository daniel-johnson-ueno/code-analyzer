/**
 * @name               : procedureAssignmentUtilsTest
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 01-28-2025
 * @modification date  : 01-28-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Clase test de procedureAssignmentUtils
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   01-28-2025   Alvaro Gonzales Lapponi   Initial Version
**/
@isTest
public class procedureAssignmentUtilsTest {
    
    /**
    * @description Método test exitoso para obtener las condiciones de cita en horario diurno
    * @author Alvaro Gonzales Lapponi | 01-28-2025
    **/
    @isTest
    public static void getAppointmentConditionsDayTestOk(){
        procedureAssignmentUtils.AppointmentStructure structure = new procedureAssignmentUtils.AppointmentStructure();
        structure.isClient = true;
        structure.product = 'Cajas';
        structure.subproduct = 'Otras operaciones de caja';
        structure.representativeType = 'Persona';
        Test.startTest();
        procedureAssignmentUtils.Response response = procedureAssignmentUtils.getAppointmentConditions(structure);
        Test.stopTest();
        system.AssertEquals(true,response.existingRecord,'Sí debe existir un registro para la combinación ingresada');
    }
    
    /**
    * @description Método test exitoso para obtener las condiciones de cita en horario nocturno
    * @author Alvaro Gonzales Lapponi | 01-28-2025
    **/
    @isTest
    public static void getAppointmentConditionsNightTestOk(){
        procedureAssignmentUtils.AppointmentStructure structure = new procedureAssignmentUtils.AppointmentStructure();
        structure.isClient = true;
        structure.product = 'Cajas';
        structure.subproduct = 'Otras operaciones de caja';
        structure.representativeType = 'Persona';
        Test.startTest();
        procedureAssignmentUtils.Response response = procedureAssignmentUtils.getAppointmentConditions(structure);
        Test.stopTest();
        system.AssertEquals(true,response.existingRecord,'Sí debe existir un registro para la combinación ingresada');
    }
    
    /**
    * @description Método test exitoso para obtener Trámites
    * @author Alvaro Gonzales Lapponi | 01-28-2025
    **/
    @isTest
    public static void getTramitesTestOk(){
        Test.startTest();
        Map<String,List<String>> response = procedureAssignmentUtils.getTramites('Persona',true);
        Test.stopTest();
        system.AssertEquals(true, response.keySet().size()> 0, 'La respuesta debería tener al menos un elemento');
    }
    
}