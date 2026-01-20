/**
 * @description       : 
 * @author            : Noe Vasquez
 * @group             : 
 * @last modified on  : 06-18-2025
 * @last modified by  : Noe Vasquez
**/
global class CloseExpiredCampaignMembersBatch implements Database.Batchable<SObject>, Schedulable  {

    private static final String FINAL_STATUS = 'Vencido';
    private static final Set<String> PENDING_STATUS= new Set<String>{'Pendiente'};

    global Database.QueryLocator start(Database.BatchableContext bc) {
        Date hoy = Date.today();
        return Database.getQueryLocator([
            SELECT Id, Status, DueDate__c
            FROM CampaignMember
            WHERE DueDate__c != null
            AND DueDate__c < :hoy
            AND Status IN: PENDING_STATUS
        ]);
    }

    global void execute(Database.BatchableContext bc, List<CampaignMember> scope) {
        for (CampaignMember cm : scope) {
            cm.Status = FINAL_STATUS;
        }

        Database.SaveResult[] results = Database.update(scope, false);

        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                for (Database.Error err : results[i].getErrors()) {
                    handleError(new DmlException(err.getMessage()), scope[i].Id);
                }
            }
        }
    }


    global void finish(Database.BatchableContext bc) {
        System.debug('Actualizacion automática de status de Miembros de campaña finalizado');
    }

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new CloseExpiredCampaignMembersBatch(), 100);
    }

    public virtual void handleError(Exception err, Id recordId) {
        GenerateLogEvent.generateErrorLogEvent(
            new DmlException(err.getMessage()),
            UserInfo.getUserId(),
            'CloseExpiredCampaignMembersBatch',
            'execute - Record Id: ' + recordId
        );
    }

}