public class SendCaseNotificationServiceQueueable implements Queueable, Database.AllowsCallouts {
    private Map<String, Case> caseByCaseId;
    private List<Case> newCases;
    private Map<Id, Case> oldCases;
    private static final String STATUS_ASSIGNED = 'Asignado';
    
    public SendCaseNotificationServiceQueueable(List<Case> newCases, Map<String, Case> caseByCaseId, Map<Id, Case> oldCases){
        this.caseByCaseId = caseByCaseId;
        this.newCases = newCases;
        this.oldCases = oldCases;

    }
    
    public void execute(QueueableContext context) {

        List<RecordType> recordTypeIds = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Case' AND DeveloperName IN ('Solicitud','Reclamo')];

        for (Case newCase : newCases) {
            Case oldCase;
            if(oldCases != null && oldCases.size() > 0){
                oldCase = oldCases.containsKey(newCase.Id) ? oldCases.get(newCase.Id): null;
            }

            if(caseByCaseId.containsKey(newCase.Id)){

                String personCode = String.valueOf(caseByCaseId.get(newCase.Id).Account.PersonCode__c);
                String recordTypeName = caseByCaseId.get(newCase.Id).RecordType.Name;
                if (shouldSendNotification(newCase, oldCase, recordTypeIds, personCode)) {
                    Boolean isNew = ((oldCase != null && newCase.RecordTypeId != oldCase.RecordTypeId && newCase.Status == STATUS_ASSIGNED) || newCase.Status == 'Nuevo');
                    String milestoneStatus = newCase.MilestoneStatus;

                    String brazeEvent = null;

                    if (milestoneStatus != null && milestoneStatus.equals('Open Violation')) {
                        System.debug('Se envia la notificacion de SLA vencido');
                        brazeEvent = 'SF_CASE_EVENT_SLA_EXPIRED';
                    } else {
                        if (isNew) {
                            System.debug('Se envia la notificacion de nuevo caso abierto');
                            brazeEvent = 'SF_CASE_EVENT_NEW';
                        } else if (newCase.Status.equals('Cerrado')) {
                            System.debug('Se envia la notificacion de caso cerrado');
                            brazeEvent = 'SF_CASE_EVENT_CASE_CLOSED';
                        } else {
                            System.debug('No se debe enviar notificacion para este status: ' + newCase.Status);
                            return;
                        }
                    }

                    SendCaseNotification(personCode, newCase.Origin, newCase.CaseNumber, recordTypeName, newCase.Braze_Description__c, brazeEvent);
                }
            }

        }
    }

    public static void SendCaseNotification(String personCode, String origin, String caseNumber, String typologyType, String typologyReason, String brazeEvent){
        Web_Service_Endpoint__mdt wsEndpSetting = Web_Service_Endpoint__mdt.getInstance('caseNotification');
        Ueno_Service_Domain__c domain = Ueno_Service_Domain__c.getOrgDefaults();
        String endpoint = domain.DomainName__c + wsEndpSetting.path__c;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('apikey', domain.ApiKey__c);
        req.setMethod('POST');

        String requestBody = '{' +
                '"personCode": "' + personCode + '", ' +
                '"origin": "' + origin + '", ' +
                '"event": "' + brazeEvent + '", ' +
                '"caseId": "' + caseNumber + '", ' +
                '"typology": {' +
                    '"type": "' + typologyType.toLowerCase() +
                    '", "reason": "' + typologyReason?.unescapeJava() +
                '"}' +
        '}';

        req.setBody(requestBody);
        req.setTimeout(60000);

        HttpHelper.HttpClientWithRetry httpClient = new HttpHelper.HttpClientWithRetry();

        if (req != null) {
            HttpResponse tResponse = httpClient.doCallout(req);
            System.debug('Respuesta: ' + tResponse.getStatusCode());
            System.debug('Message: ' + tResponse.getBody());
        }
    }

    private static Boolean shouldSendNotification(Case newCase, Case oldCase, List<RecordType> recordTypeIds, String personCode) {
        System.debug('shouldSendNotification');
        if(newCase.AccountId != null){
            if (personCode == null) {
                System.debug('El cliente no tiene person code. No se envia ninguna notificacion!');
                return false;
            }
            for (RecordType recordTypeId : recordTypeIds) {
                if (newCase.RecordTypeId == recordTypeId.Id && newCase.AutomaticClosure__c == false) {
                    return true;
                }
            }
            System.debug('Por el record type no se debe enviar notificacion.');
            return false;
        }
        System.debug('El caso no tiene cuenta asociada. No se envia ninguna notificacion!');
        return false;
    }
    
}