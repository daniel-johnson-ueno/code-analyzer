public with sharing class GenerateLogEvent {

    public static void generateErrorLogEvent(Exception exceptionLog, String userId, String className, String methodName){

        Generate_Error_Log__e newErrorLogEvent = new Generate_Error_Log__e();
        newErrorLogEvent.Running_User__c = userId;
        newErrorLogEvent.Class_Name__c = className;
        newErrorLogEvent.Method_Name__c = methodName;
        newErrorLogEvent.Error_Message__c = exceptionLog.getMessage();
        newErrorLogEvent.Line_Number__c = String.valueOf(exceptionLog.getLineNumber());
        newErrorLogEvent.Execution_Date__c = Datetime.now();

        System.debug(newErrorLogEvent);
        EventBus.publish(newErrorLogEvent);

    }

    public static void generateIntegrationLogEvent(HttpRequest request, HttpResponse response){

        Map<String, Object> parsedBody;
        if(response.getStatusCode() != 200){
            parsedBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        }

        Generate_Integration_Log__e newIntegrationLog = new Generate_Integration_Log__e();
        newIntegrationLog.Endpoint__c = request.getEndpoint();
        newIntegrationLog.Request_Method__c = request.getMethod().toUpperCase();
        newIntegrationLog.Response__c = response.getBody().length() > 131072 ? response.getBody().substring(0,131072) : response.getBody();
        newIntegrationLog.Response_Status_Code__c = response.getStatusCode();
        newIntegrationLog.Trace_Id__c = parsedBody != null && parsedBody.containsKey('traceId') ? String.valueOf(parsedBody.get('traceId')) : null;

        EventBus.publish(newIntegrationLog);

    }

}