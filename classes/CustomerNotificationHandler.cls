public with sharing class CustomerNotificationHandler {
    
    public static HttpRequest buildCaseNotificationRequest() {
        Web_Service_Endpoint__mdt ws = Web_Service_Endpoint__mdt.getInstance('caseNotification');
        Ueno_Service_Domain__c domain = Ueno_Service_Domain__c.getOrgDefaults();
    
        HttpRequest req = new HttpRequest();
        req.setEndpoint(domain.DomainName__c + ws.path__c);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('apikey', domain.ApiKey__c);
        req.setMethod('POST');
        req.setTimeout(60000);
        
        return req;
    }

    public static HttpRequest createNotificationRequest(Case caseObject, Account accountObject, Boolean isNew) {
        HttpRequest req;
        String milestoneStatus = caseObject.MilestoneStatus;
        
        if (milestoneStatus != null && milestoneStatus.equals('Open Violation')) {
            System.debug('Se envia la notificacion de SLA vencido');
            req = sendNotificationEvent(caseObject,  String.valueOf(accountObject.PersonCode__c), 'SF_CASE_EVENT_SLA_EXPIRED');
        } else {
            String caseStatus = caseObject.Status;

            if (isNew) {
                System.debug('Se envia la notificacion de nuevo caso abierto');
                req = sendNotificationEvent(caseObject, String.valueOf(accountObject.PersonCode__c), 'SF_CASE_EVENT_NEW');
            } else if (caseStatus.equals('Cerrado')) {
                System.debug('Se envia la notificacion de caso cerrado');
                req = sendNotificationEvent(caseObject, String.valueOf(accountObject.PersonCode__c), 'SF_CASE_EVENT_CASE_CLOSED');
            } else {
                System.debug('No se debe enviar notificacion para este status: ' + caseStatus);
            }
        }
        System.debug('Notification request:' + req);
        return req;        
    }

    private static HttpRequest sendNotificationEvent(Case caseObject, String personCode, String event){

        HttpRequest req = CustomerNotificationHandler.buildCaseNotificationRequest();
        System.debug('CustomerNotificationHandler: ' + req);
        System.debug('Case object: ' + caseObject);
        System.debug('Person code: ' + personCode);
        System.debug('Event: ' + event);
        
        CaseNotificationRequestDto request = new CaseNotificationRequestDto();
        request.personCode = personCode;
        request.caseId = caseObject.Id;
        request.origin = caseObject.Origin;
        request.event = event;
        request.caseNumber = caseObject.CaseNumber;

        CaseNotificationRequestDto.Typology typo = new CaseNotificationRequestDto.Typology();
        typo.type = caseObject.RecordType.Name;
        typo.reason = caseObject.Braze_Description__c;
        request.typology = typo;

        String requestBody = JSON.serialize(request);

        req.setBody(requestBody);
        req.setTimeout(60000);

        return req;
    }
    public static HttpRequest createNotificationRequest(CaseNotificationRequestDto caseNotificationDto) {
        HttpRequest req = CustomerNotificationHandler.buildCaseNotificationRequest();
        String requestBody = JSON.serialize(caseNotificationDto);
        req.setBody(requestBody);
        req.setTimeout(60000);
       return req;
    }
    
}