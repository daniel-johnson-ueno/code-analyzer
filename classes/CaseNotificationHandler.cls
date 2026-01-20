/**
 * Created by alexis on 21/02/2025.
 */

 public with sharing class CaseNotificationHandler {
    private static final String BY_PASS_FLOW = 'ByPass_Flow';
    private static final String STATUS_ASSIGNED = 'Asignado';
    public static Boolean isFirstTime = true;

    // Devuelve si debe ejecutar el handler
    private static Boolean shouldRunHandle() {
        List<PermissionSetAssignment> psaList = [
                SELECT Id
                FROM PermissionSetAssignment
                WHERE AssigneeId = :UserInfo.getUserId()
                AND PermissionSet.Name = :BY_PASS_FLOW
        ];

        return psaList.isEmpty();
    }

    // Devuelve si debe enviar notificación
    private static Boolean shouldSendNotification(Case newCase, Case oldCase, List<RecordType> recordTypeIds, String personCode) {

        if(newCase.AccountId != null){
            if(newCase.Vazquez_Group_Company__c != null){
                if(!itIsUenoBankCase(newCase.Vazquez_Group_Company__c)){
                    System.debug('No es un caso de ueno');
                    return false;
                }
            }

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


    public static void handle(List<Case> newCases,  Map<Id, Case> newCasesMap, Map<Id, Case> oldCases) {
        if (shouldRunHandle()) {
            Map<String, Case> caseByCaseId = new Map<String, Case>();

            List<RecordType> recordTypeIds = [
                    SELECT Id
                    FROM RecordType
                    WHERE SObjectType = 'Case' AND DeveloperName IN ('Solicitud','Reclamo')
            ];

            if(newCasesMap != null && newCasesMap.size() > 0){

                List<Case> casesToSendNotification = [SELECT Id, Account.PersonCode__c, RecordType.Name FROM Case WHERE Id IN :newCasesMap.keySet()];

                if(casesToSendNotification != null && casesToSendNotification.size() > 0){

                    for (Case currentCase : casesToSendNotification) {
                        if(currentCase.Account.PersonCode__c != null){
                            caseByCaseId.put(currentCase.Id, currentCase);
                        }
                    }
                }

            }

            if(caseByCaseId != null || caseByCaseId.size() > 0){
                //List<SendCaseNotificationServiceBatch.DataInput> dataSendToCallout = new List<SendCaseNotificationServiceBatch.DataInput>();
                List<CaseNotificationRequestDto> dataSendToCallout = new List<CaseNotificationRequestDto>();
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

                            //SendCaseNotificationServiceBatch.DataInput data = new SendCaseNotificationServiceBatch.DataInput(personCode, newCase.Origin, newCase.CaseNumber, recordTypeName, newCase.Braze_Description__c, brazeEvent);
                            CaseNotificationRequestDto request = new CaseNotificationRequestDto();
                            request.personCode = personCode;
                            request.origin = newCase.Origin;
                            request.event = brazeEvent;
                            request.caseId = newCase.Id;
                            request.caseNumber = newCase.CaseNumber;

                            CaseNotificationRequestDto.Typology typo = new CaseNotificationRequestDto.Typology();
                            typo.type = recordTypeName;
                            typo.reason = newCase.Braze_Description__c;
                            request.typology = typo;

                            dataSendToCallout.add(request);
                            //SendCaseNotificationService.send(personCode, newCase.Origin, newCase.CaseNumber, recordTypeName, newCase.Braze_Description__c, brazeEvent);
                        }
                    }

                }

                if(!dataSendToCallout.isEmpty()){
                    Integer batchSize;
                    try {
                        batchSize = Integer.valueOf(Label.BatchSizeCaseNotification);
                    } catch (Exception e) {
                        batchSize = 200; // Valor por defecto
                    }
                    SendCaseNotificationServiceBatch b = new SendCaseNotificationServiceBatch(dataSendToCallout);
                    Database.executeBatch(b, batchSize);
                }
            }

        }
    }
    
    public static Boolean itIsUenoBankCase(String vazquezGroupCompanyId){
        Account company = [SELECT GroupCompaniesUeno__c FROM Account where Id=:vazquezGroupCompanyId];
        if(company.GroupCompaniesUeno__c=='UENO_BANK'){
            return true;
        }
        return false;
    }
}