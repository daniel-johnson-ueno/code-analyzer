public with sharing class ExecutiveAssistanceController {

    @AuraEnabled
    public static List<ExecutiveAssistanceService.ExecutiveAssistanceWrapper> executiveAssistanceList(Date selectedDate) {

        List<ExecutiveAssistanceService.ExecutiveAssistanceWrapper> executiveAssistanceDataResponse =  ExecutiveAssistanceService.getExecutiveAssistanceResponse(selectedDate);

        return executiveAssistanceDataResponse;
    }

}