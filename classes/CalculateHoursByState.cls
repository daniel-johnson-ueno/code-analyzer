/*
@author Veronica Zarza
@date 22/10/2024
@description Clase invocable para el calculo de horas por estado a partir de BusinessHours
*/

public with sharing class CalculateHoursByState{
    
    @AuraEnabled(cacheable=true)
	public static Double calculateSecondsDifferenceInStage(String caseDateTimeLastStatusChange) {
        Double result;
        try{
            result = calculateSecondsDifferenceInStage(caseDateTimeLastStatusChange, Datetime.now());
        }
        catch(Exception e){
            System.debug(e.getMessage());
            return 0;
        }
		return result;
    }

    public static Double calculateSecondsDifferenceInStage(String caseDateTimeLastStatusChange, Datetime now) {
        Double result;
        try{
            if(caseDateTimeLastStatusChange==null){
                return 0;
            }
            DateTime caseDateTimeLastStatusChangeDateTime = Datetime.valueOfGmt(caseDateTimeLastStatusChange.replace('T', ' ').replace('Z', ''));
            DateTime currentDateTime = now;
            BusinessHours bussinesHour = [SELECT Id FROM BusinessHours WHERE Name = 'Horario Ueno' LIMIT 1];
            result = (Double)BusinessHours.diff(bussinesHour.Id,caseDateTimeLastStatusChangeDateTime,currentDateTime)/1000;
        }
        catch(Exception e){
            System.debug(e.getMessage());
            return 0;
        }
		return result;
    }

    @AuraEnabled(cacheable=true)
    public static Boolean itIsWorkingHours(){
        Boolean result;
        try{
            result = checkItIsWorkingHours(Datetime.now());
        }
        catch(Exception e){
            System.debug(e.getMessage());
            return false;
        }
		return result;
    }

    public static Boolean checkItIsWorkingHours(Datetime currentTime){
        BusinessHours bussinesHour = [SELECT Id FROM BusinessHours WHERE Name = 'Horario Ueno' LIMIT 1];
        Datetime now = currentTime;
        return BusinessHours.isWithin(bussinesHour.Id, now);
    }

    @InvocableMethod(label='Calcular horas habiles' description='Calculo de horas habiles por estado a partir de BH')
    public static List<Double> calculateHoursInSecondsByState(List<FlowInputs> inputs){
     List<Double> results = new List<Double>();
     Set<Id> businessHoursIds = new Set<Id>();
    
    for(FlowInputs inp :inputs){
        businessHoursIds.add(inp.businessHoursId);
    }
    
    Map<Id, BusinessHours> businessHoursMap = new Map<Id, BusinessHours>(
    [SELECT Id FROM BusinessHours WHERE Id IN :businessHoursIds]
    );
    Double seconds;
    for(FlowInputs inp :inputs){
        BusinessHours bh = businessHoursMap.get(inp.businessHoursId);
        if(bh != null && inp.startDate != null && inp.endDate != null){
            Long result = BusinessHours.diff(bh.Id,inp.startDate,inp.endDate);
            seconds = (Double)(result / 1000);
        }
    	results.add(seconds);
    }
    return results;
    }
    
     public class FlowInputs{
     @InvocableVariable(required=true label='Business Hours Id' description='Id de BH')
     public Id businessHoursId;
    
     @InvocableVariable(required=true label='Fecha de inicio' description='Fecha inicial para el calculo de SLA')
     public Datetime startDate;
    
     @InvocableVariable(required=true label='Fecha de finalizacion' description='Fecha final para el calculo de SLA')
     public Datetime endDate;
     }
}