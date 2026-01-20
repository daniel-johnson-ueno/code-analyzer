/**
 * @name               : procedureAssignmentUtils
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 01-28-2025
 * @modification date  : 26-02-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Clase utilitaria para metadata procedureAssignment__mdt
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   01-28-2025   Alvaro Gonzales Lapponi   Initial Version
**/
public with sharing class procedureAssignmentUtils {
    
    /**
    * @description Se obtienen las caraceterísticas de la cita
    * @author Alvaro Gonzales Lapponi | 24-01-2025
    * @param AppointmentStructure structure
    * @return Response
    **/
    @AuraEnabled(cacheable=false)
    public static Response getAppointmentConditions(AppointmentStructure structure){
        Response response = new Response();
        List<procedureAssignment__mdt> mdtList = [SELECT DayTimeQueueable__c, NightTimeQueueable__c, DayTimeProfile__c, NightTimeProfile__c, DayTimeClosedCase__c, NightTimeClosedCase__c, Company__c
                                                  FROM procedureAssignment__mdt
                                                  WHERE Product__c =: structure.product AND Subproduct__c =: structure.subproduct
                                                  AND RepresentativeType__c =: structure.representativeType AND isClient__c =: structure.isClient LIMIT 1];
             
        if(!mdtList.isEmpty()){
            response.existingRecord = true;
            procedureAssignment__mdt mdt = mdtList[0];
            response.appointmentConditions = new AppointmentConditions();
            response.appointmentConditions.company = mdt.Company__c;
            Boolean dayTime = isDayTime();
            if(dayTime){
                response.appointmentConditions.queueable = mdt.DayTimeQueueable__c;
                response.appointmentConditions.queue = mdt.DayTimeProfile__c;
                response.appointmentConditions.closedCase = mdt.DayTimeClosedCase__c;
            } else{
                response.appointmentConditions.queueable = mdt.NightTimeQueueable__c;
                response.appointmentConditions.queue = mdt.NightTimeProfile__c;
                response.appointmentConditions.closedCase = mdt.NightTimeClosedCase__c;
            }
        } else{
            response.existingRecord = false;
        }
        return response;   
    }
    
    /**
    * @description Se identifica si se está en horario regular o complementario
    * @author Alvaro Gonzales Lapponi | 24-01-2025
    * @return Boolean
    **/
    private static Boolean isDayTime(){
        Id businessHoursId = [SELECT Id FROM BusinessHours WHERE Name = 'Turnero' LIMIT 1].Id;
        Datetime now = System.now();
        return BusinessHours.isWithin(businessHoursId, now);
    }
    
    /**
    * @description 
    * @author Alvaro Gonzales Lapponi | 24-01-2025
    * @param String representativeType 
    * @param Boolean isClient 
    * @return 
    **/
    @AuraEnabled(cacheable=true)
    public static Map<String,List<String>> getTramites(String representativeType, Boolean isClient){
        List<procedureAssignment__mdt> procedureAssignments = [SELECT Product__c, Subproduct__c
                                                               FROM procedureAssignment__mdt
                                                               WHERE RepresentativeType__c =: representativeType AND isClient__c =: isClient];
        
        Map<String,List<String>> productSubproductMap = new Map<String,List<String>>();
        
        for(procedureAssignment__mdt mdt : procedureAssignments){
            if(productSubproductMap.containsKey(mdt.Product__c)){
                productSubproductMap.get(mdt.Product__c).add(mdt.Subproduct__c);
            } else{
                productSubproductMap.put(mdt.Product__c, new List<String>{mdt.Subproduct__c});
            }
        }        
        
        return productSubproductMap;
    }
    
    public class AppointmentStructure {
        @AuraEnabled public String representativeType { get; set; }
        @AuraEnabled public Boolean isClient { get; set; }
        @AuraEnabled public String product { get; set; }
        @AuraEnabled public String subproduct { get; set; }
    }
    
    public class Response{
        @AuraEnabled public Boolean existingRecord;
        @AuraEnabled public AppointmentConditions appointmentConditions;
    }
    
    public class AppointmentConditions{
        @AuraEnabled public Boolean queueable { get; set; }
        @AuraEnabled public String queue { get; set; }
        @AuraEnabled public Boolean closedCase { get; set; }
        @AuraEnabled public String company { get; set; }
    }
}