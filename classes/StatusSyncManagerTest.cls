@isTest
private class StatusSyncManagerTest {

    @isTest
    static void testOnSalesforceStatusChange() {
        StatusSyncManager manager = new StatusSyncManager();
    
        List<String> testStatuses = new List<String>{
            'DISPONIBLE - TELEFÓNICO',
            'DISPONIBLE',
            'AUSENTE - BREAK',
            'AUSENTE - ENTRENAMIENTO',
            'OCUPADO',
            null,
            'ESTADO_NO_MAPEADO'
        };
    
        for (String statusName : testStatuses) {
            StatusSyncManager.IncomingStatusChange statusChange = new StatusSyncManager.IncomingStatusChange();
    
            StatusSyncManager.IncomingSalesforceStatus salesforceStatus = new StatusSyncManager.IncomingSalesforceStatus();
            StatusSyncManager.IncomingSalesforceStatusObj currentStatus = new StatusSyncManager.IncomingSalesforceStatusObj();
            StatusSyncManager.IncomingSalesforceStatusObj targetStatus = new StatusSyncManager.IncomingSalesforceStatusObj();
    
            currentStatus.statusApiName = 'currentApiName';
            currentStatus.statusId = 'currentStatusId';
            currentStatus.statusName = 'currentStatusName';
    
            targetStatus.statusApiName = 'targetApiName';
            targetStatus.statusId = 'targetStatusId';
            targetStatus.statusName = statusName;
    
            salesforceStatus.currentStatus = currentStatus;
            salesforceStatus.targetStatus = targetStatus;
    
            StatusSyncManager.IncomingGenesysCloudStatus genesysCloudStatus = new StatusSyncManager.IncomingGenesysCloudStatus();
            genesysCloudStatus.currentStatus = new StatusSyncManager.IncomingGenesysCloudStatusObj();
            genesysCloudStatus.targetStatus = new StatusSyncManager.IncomingGenesysCloudStatusObj();
    
            statusChange.salesforceStatus = salesforceStatus;
            statusChange.genesysCloudStatus = genesysCloudStatus;
    
            String jsonData = JSON.serialize(statusChange);
            String response = manager.onSalesforceStatusChange(jsonData);
    
            System.assertNotEquals(null, response, 'La respuesta no debe ser null');
        }
    }

    @isTest
    static void testOnGenesysCloudStatusChange() {
        StatusSyncManager manager = new StatusSyncManager();

        List<String> testSystemPresences = new List<String>{
            'AVAILABLE',
            'ON_QUEUE',
            'TRAINING',
            'BUSY',
            'MEAL',
            'OFFLINE',
            'ESTADO_NO_MAPEADO'
        };

        for (String systemPresence : testSystemPresences) {
            StatusSyncManager.IncomingStatusChange statusChange = new StatusSyncManager.IncomingStatusChange();

            StatusSyncManager.IncomingGenesysCloudStatus genesysCloudStatus = new StatusSyncManager.IncomingGenesysCloudStatus();
            StatusSyncManager.IncomingGenesysCloudStatusObj currentStatus = new StatusSyncManager.IncomingGenesysCloudStatusObj();
            StatusSyncManager.IncomingGenesysCloudStatusObj targetStatus = new StatusSyncManager.IncomingGenesysCloudStatusObj();

            currentStatus.id = 'currentId';
            currentStatus.systemPresence = 'currentPresence';
            targetStatus.id = 'targetId';
            targetStatus.systemPresence = systemPresence;

            genesysCloudStatus.currentStatus = currentStatus;
            genesysCloudStatus.targetStatus = targetStatus;

            StatusSyncManager.IncomingSalesforceStatus salesforceStatus = new StatusSyncManager.IncomingSalesforceStatus();
            salesforceStatus.currentStatus = new StatusSyncManager.IncomingSalesforceStatusObj();
            salesforceStatus.targetStatus = new StatusSyncManager.IncomingSalesforceStatusObj();

            statusChange.genesysCloudStatus = genesysCloudStatus;
            statusChange.salesforceStatus = salesforceStatus;

            String jsonData = JSON.serialize(statusChange);
            String response = manager.onGenesysCloudStatusChange(jsonData);

            System.assertNotEquals(null, response, 'La respuesta no debe ser null');
        }
    }
}