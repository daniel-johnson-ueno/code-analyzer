public with sharing class CaseNotificationController {

    public class TestCase { 
        @InvocableVariable(required=true) public Case caseObject;
        @InvocableVariable(required=true) public Boolean isNew;
    } 

    @InvocableMethod(label='List cases' description='List cases')
    public static void sendCaseNotification(List<TestCase> cases){
        Id caseId = cases.get(0).caseObject.Id;
        Boolean isNew = cases.get(0).isNew;
        sendFutureCaseNotification(caseId, isNew);
    }

    @future(callout=true)
    public static void sendFutureCaseNotification(Id caseId, Boolean isNew) {
        if (!Schema.sObjectType.Case.fields.CaseNumber.isAccessible()) {
            System.debug('Error: El usuario no tiene permisos para leer el objeto Case.');
            return;
        }
		Account accountObject;
        Case caseObject = [SELECT Id, AccountId , Origin, CaseNumber, Type, Reason, Braze_Description__c, MilestoneStatus, Status, RecordType.Name FROM Case WHERE Id =: caseId];
        System.debug(caseObject);
        if(caseObject.AccountId != null){
            accountObject = [SELECT PersonCode__c FROM Account WHERE Id =: caseObject.AccountId ];
        	System.debug(accountObject);
        	if (accountObject.PersonCode__c == null) {
            	System.debug('El cliente no tiene person code. No se envia ninguna notificacion!');
            	return;
        	}

        }else{
            System.debug('El caso no tiene cuenta asociada. No se envia ninguna notificacion!');
            	return;
        }

        HttpHelper.HttpClientWithRetry httpClient = new HttpHelper.HttpClientWithRetry();
        
         HttpRequest req = CustomerNotificationHandler.createNotificationRequest(caseObject, accountObject, isNew);

        if (req != null) {
            HttpResponse tResponse = httpClient.doCallout(req);
            System.debug('Respuesta: ' + tResponse.getStatusCode());
            System.debug('Message: ' + tResponse.getBody());
        }
    }

   /* private static HttpRequest createNotificationRequest(Case caseObject, Account accountObject, Boolean isNew) {
        HttpRequest req;
        String milestoneStatus = caseObject.MilestoneStatus;
        
        if (milestoneStatus != null && milestoneStatus.equals('Open Violation')) {
            System.debug('Se envia la notificacion de SLA vencido');
            req = sendNotificationEvent(caseObject, accountObject, 'SF_CASE_EVENT_SLA_EXPIRED');
        } else {
            String caseStatus = caseObject.Status;

            if (isNew) {
                System.debug('Se envia la notificacion de nuevo caso abierto');
                req = sendNotificationEvent(caseObject, accountObject, 'SF_CASE_EVENT_NEW');
            } else if (caseStatus.equals('Cerrado')) {
                System.debug('Se envia la notificacion de caso cerrado');
                req = sendNotificationEvent(caseObject, accountObject, 'SF_CASE_EVENT_CASE_CLOSED');
            } else {
                System.debug('No se debe enviar notificacion para este status: ' + caseStatus);
            }
        }
        return req;        
    }

    private static HttpRequest sendNotificationEvent(Case caseObject, Account accountObject, String event){
        String personCode = String.valueOf(accountObject.PersonCode__c);
        String origin = caseObject.Origin;
        String caseNumber = caseObject.CaseNumber;
        String typologyType = caseObject.RecordType.Name;
        String typologyReason = caseObject.Braze_Description__c;

        Web_Service_Endpoint__mdt wsEndpSetting = Web_Service_Endpoint__mdt.getInstance('caseNotification');
        Ueno_Service_Domain__c domain = Ueno_Service_Domain__c.getOrgDefaults();

        String endpoint = domain.DomainName__c + wsEndpSetting.path__c;        

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('apikey', domain.ApiKey__c);
        req.setMethod('POST');
        System.debug('CaseNotificationController: ' + req);
        String requestBody = '{"personCode": "' + personCode + '", ' +
        '"origin": "' + origin + '", ' +
        '"event": "' + event + '", ' +
        '"caseId": "' + caseNumber + '", ' +
        '"typology": {"type": "' + typologyType.toLowerCase() + '", "reason": "' + typologyReason.unescapeJava() + '"}}';

        req.setBody(requestBody);
        req.setTimeout(60000);

        return req;
    }*/
}