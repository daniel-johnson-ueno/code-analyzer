global without sharing class StatusSyncManager implements genesyscloud.GenesysSCVExtension.Status {
    public String onSalesforceStatusChange(String data) {
      IncomingStatusChange statusUpdate = (IncomingStatusChange) JSON.deserialize(data, IncomingStatusChange.class);
      // -----------------------------------------------------------------------------------------------------------------------------------
      // Examples of how to get current Salesforce Status Variables:
      // String salesforceCurrentStatusApiName = statusUpdate.salesforceStatus.currentStatus.statusApiName;
      // String salesforceCurrentStatusId = statusUpdate.salesforceStatus.currentStatus.statusId;
      // String salesforceCurrentStatusName = statusUpdate.salesforceStatus.currentStatus.statusName;
  
      // Examples of how to get target Salesforce Status Variables:
      // String salesforceTargetStatusApiName = statusUpdate.salesforceStatus.targetStatus.statusApiName;
      String salesforceTargetStatusId = statusUpdate.salesforceStatus.targetStatus.statusId;
      String salesforceTargetStatusName = statusUpdate.salesforceStatus.targetStatus.statusName;
      // -----------------------------------------------------------------------------------------------------------------------------------
      // Examples of how to get current Genesys Status Variables:
      // String genesysCurrentId = statusUpdate.genesysCloudStatus.currentStatus.id;
      // String genesysCurrentSystemPresence = statusUpdate.genesysCloudStatus.currentStatus.systemPresence;
  
      // Examples of how to get target Genesys Status Variables:
      String genesysTargetId = statusUpdate.genesysCloudStatus.targetStatus.id;
      // String genesysTargetSystemPresence = statusUpdate.genesysCloudStatus.targetStatus.systemPresence;
      // -----------------------------------------------------------------------------------------------------------------------------------
  
      // These are the variables that will be changed to update the agent's status.
      // These are default values to be sent back if no changes are made to the target statuses.
      // NOTE: If these values are NOT handled below, NO CHANGES will be made to the target statuses.
      String salesforceResponseTargetStatusId = salesforceTargetStatusId;
      String genesysResponseTargetStatusId = genesysTargetId;
  
      if (String.isNotEmpty(salesforceTargetStatusName)) {
        salesforceTargetStatusName = salesforceTargetStatusName.toUpperCase();
      }

      System.debug('test status change SF: ' + salesforceTargetStatusName);
  
      switch on salesforceTargetStatusName {
        when 'DISPONIBLE - TELÉFONO' {
          genesysResponseTargetStatusId = 'e08eaf1b-ee47-4fa9-a231-1200e284798f'; //ON_QUEUE
        }
        when 'DISPONIBLE - TELÉFONO EMPRESAS' {
          genesysResponseTargetStatusId = 'e08eaf1b-ee47-4fa9-a231-1200e284798f'; //ON_QUEUE
        }
        when 'DISPONIBLE - TELEFONO UPAY' {
          genesysResponseTargetStatusId = 'e08eaf1b-ee47-4fa9-a231-1200e284798f'; //ON_QUEUE
        }
        when 'DISPONIBLE - VIDEOLLAMADA' {
          genesysResponseTargetStatusId = 'e08eaf1b-ee47-4fa9-a231-1200e284798f'; //ON_QUEUE
        }
        when 'DISPONIBLE - BOT' {
          genesysResponseTargetStatusId = '31fe3bac-dea6-44b7-bed7-47f91660a1a0'; //BUSY
        }
        when 'DISPONIBLE - CONVERGENTE MASIVO' {
          genesysResponseTargetStatusId = '31fe3bac-dea6-44b7-bed7-47f91660a1a0'; //BUSY
        }
        when 'DISPONIBLE - CONVERGENTE ESPECIALIZADO' {
          genesysResponseTargetStatusId = '31fe3bac-dea6-44b7-bed7-47f91660a1a0'; //BUSY
        }
        when 'DISPONIBLE - PRESENCIAL' {
          genesysResponseTargetStatusId = '31fe3bac-dea6-44b7-bed7-47f91660a1a0'; //BUSY
        }
        when 'DISPONIBLE - ROT' {
          genesysResponseTargetStatusId = '31fe3bac-dea6-44b7-bed7-47f91660a1a0'; //BUSY
        }
        when 'DISPONIBLE - REDES' {
          genesysResponseTargetStatusId = '31fe3bac-dea6-44b7-bed7-47f91660a1a0'; //BUSY
        }
        when 'DISPONIBLE' {
          genesysResponseTargetStatusId = '6a3af858-942f-489d-9700-5f9bcdcdae9b'; //AVAILABLE
        }
        when 'AUSENTE - BREAK' {
          genesysResponseTargetStatusId = '3fd96123-badb-4f69-bc03-1b1ccc6d8014'; //MEAL
        }
        when 'AUSENTE - SANITARIO' {
          genesysResponseTargetStatusId = '227b37e2-f1d0-4dd0-8f50-badd7cf6d158'; //BREAK
        }
        when 'AUSENTE - ENTRENAMIENTO' {
          genesysResponseTargetStatusId = 'd2390a99-8546-bad9-8f0a-219548e8aeb0'; //TRAINING
        }
        when 'AUSENTE - COACHING' {
          genesysResponseTargetStatusId = 'bbdff279-7ae1-48ea-bade-7831d7234c64'; //MEETING
        }
        when 'AUSENTE - ENFERMERIA' {
        genesysResponseTargetStatusId = '5e5c5c66-ea97-4e7f-ac41-6424784829f2'; //AWAY
        }
        when 'INCONVENIENTE TÉCNICO' {
          genesysResponseTargetStatusId = '5e5c5c66-ea97-4e7f-ac41-6424784829f2'; //AWAY
        }
        when 'NO DISPONIBLE - LLAMADA SALIENTE' {
          genesysResponseTargetStatusId = '6a3af858-942f-489d-9700-5f9bcdcdae9b'; //AVAILABLE
        }
        when 'NO DISPONIBLE - TAREAS ADMINISTRATIVAS' {
          genesysResponseTargetStatusId = '31fe3bac-dea6-44b7-bed7-47f91660a1a0'; //BUSY
        }
        when 'OCUPADO' {
            genesysResponseTargetStatusId = '31fe3bac-dea6-44b7-bed7-47f91660a1a0'; //BUSY
        }
        when null {
          // Agent clicked Offline in Omni-Channel
          genesysResponseTargetStatusId = 'ccf3c10a-aa2c-4845-8e8d-f59fa48c58e5'; //OFFLINE
        }
        when else { 
          System.debug(logginglevel.WARN, 'Salesforce status NOT HANDLED: ' + salesforceTargetStatusName);
          genesysResponseTargetStatusId = '6a3af858-942f-489d-9700-5f9bcdcdae9b'; //AVAILABLE
        }
      }
  
      // -----------------------------------------------------------------------------------------------------------------
      // Form response object... shouldn't need to be touched.
      return JSON.serialize(new Response(genesysResponseTargetStatusId, salesforceResponseTargetStatusId));
    }
  
    public String onGenesysCloudStatusChange(String data) {
      IncomingStatusChange statusUpdate = (IncomingStatusChange) JSON.deserialize(data, IncomingStatusChange.class);
      // -----------------------------------------------------------------------------------------------------------------------------------
      // Examples of how to get current Salesforce Status Variables:
      // String salesforceCurrentStatusApiName = statusUpdate.salesforceStatus.currentStatus.statusApiName;
      // String salesforceCurrentStatusId = statusUpdate.salesforceStatus.currentStatus.statusId;
      // String salesforceCurrentStatusName = statusUpdate.salesforceStatus.currentStatus.statusName;
  
      // Examples of how to get target Salesforce Status Variables:
      // String salesforceTargetStatusApiName = statusUpdate.salesforceStatus.targetStatus.statusApiName;
      String salesforceTargetStatusId = statusUpdate.salesforceStatus.targetStatus.statusId;
      // String salesforceTargetStatusName = statusUpdate.salesforceStatus.targetStatus.statusName;
      // -----------------------------------------------------------------------------------------------------------------------------------
      // Examples of how to get current Genesys Status Variables:
      // String genesysCurrentId = statusUpdate.genesysCloudStatus.currentStatus.id;
      // String genesysCurrentSystemPresence = statusUpdate.genesysCloudStatus.currentStatus.systemPresence;
  
      // Examples of how to get target Genesys Status Variables:
      String genesysTargetId = statusUpdate.genesysCloudStatus.targetStatus.id;
      String genesysTargetSystemPresence = statusUpdate.genesysCloudStatus.targetStatus.systemPresence;
      // -----------------------------------------------------------------------------------------------------------------------------------
  
      // These are the variables that will be changed to update the agent's status.
      // These are default values to be sent back if no changes are made to the target statuses.
      // NOTE: If these values are NOT handled below, NO CHANGES will be made to the target statuses.
      String salesforceResponseTargetStatusId = salesforceTargetStatusId;
      String genesysResponseTargetStatusId = genesysTargetId;
  
      if (String.isNotEmpty(genesysTargetSystemPresence)) {
        genesysTargetSystemPresence = genesysTargetSystemPresence.toUpperCase();
      }

      System.debug('test status change GEN: ' + genesysTargetSystemPresence);
  
      switch on genesysTargetSystemPresence {
        when 'AVAILABLE' {
          salesforceResponseTargetStatusId = '0N5Vv00000000zJKAQ'; //Disponible
        }
        when 'ON_QUEUE' {
          salesforceResponseTargetStatusId = '0N5Vv000000018zKAA'; //Disponible - Teléfono
        }
        when 'TRAINING' {
            salesforceResponseTargetStatusId = '0N5Vv00000000uTKAQ'; //Ausente - Entrenamiento
        }
        when 'BUSY' {
            salesforceResponseTargetStatusId = '0N5Vv00000001DpKAI'; //Ocupado
        }
        when 'BREAK' {
          salesforceResponseTargetStatusId = '0N5Vv00000000srKAA'; // Ausente - Break
        }
        when 'AWAY' {
          salesforceResponseTargetStatusId = '0N5Vv00000000w5KAA'; // Ausente - Sanitario
        }
        when 'MEETING' {
          salesforceResponseTargetStatusId = '0N5Vv00000001NVKAY'; // Ausente - Coaching
        }
        when 'OFFLINE' {
          // Sets agent to Offline in Omni-Channel
          salesforceResponseTargetStatusId = '0';
        }
        when else { //falta mapeo de Ausente - Sanitario
          System.debug(logginglevel.WARN, 'Genesys Cloud status NOT HANDLED: ' + genesysTargetSystemPresence);
        }
      }
  
      // -----------------------------------------------------------------------------------------------------------------
      // Form response object... shouldn't need to be touched.
      return JSON.serialize(new Response(genesysResponseTargetStatusId, salesforceResponseTargetStatusId));
    }
  
    // No need to change below --------------------------------------------------------------------------------------------------------
    //#region Response Obj
    public class Response {
      public ResponseGenesysCloudStatusObj genesysCloudStatus;
      public ResponseSalesforceStatusObj salesforceStatus;
      public Response(String genesysResponseTargetStatusId, String salesforceResponseTargetStatusId) {
        this.genesysCloudStatus = new ResponseGenesysCloudStatusObj(genesysResponseTargetStatusId);
        this.salesforceStatus = new ResponseSalesforceStatusObj(salesforceResponseTargetStatusId);
      }
    }
    public class ResponseGenesysCloudStatus {
      public String id;
      public ResponseGenesysCloudStatus(String id) {
        this.id = id;
      }
    }
    public class ResponseGenesysCloudStatusObj {
      public ResponseGenesysCloudStatus targetStatus;
      public ResponseGenesysCloudStatusObj(String genesysResponseTargetStatusId) {
        this.targetStatus = new ResponseGenesysCloudStatus(genesysResponseTargetStatusId);
      }
    }
    public class ResponseSalesforceStatus {
      public String statusId;
      public ResponseSalesforceStatus(String statusId) {
        this.statusId = statusId;
      }
    }
    public class ResponseSalesforceStatusObj {
      public ResponseSalesforceStatus targetStatus;
      public ResponseSalesforceStatusObj(String salesforceResponseTargetStatusId) {
        this.targetStatus = new ResponseSalesforceStatus(salesforceResponseTargetStatusId);
      }
    }
    //#endregion Response Obj
  
    //#region IncomingStatusChange Obj
    public class IncomingStatusChange {
      public IncomingSalesforceStatus salesforceStatus;
      public IncomingGenesysCloudStatus genesysCloudStatus;
    }
    public class IncomingSalesforceStatusObj {
      public String statusApiName;
      public String statusId;
      public String statusName;
    }
    public class IncomingSalesforceStatus {
      public IncomingSalesforceStatusObj targetStatus;
      public IncomingSalesforceStatusObj currentStatus;
    }
    public class IncomingGenesysCloudStatusObj {
      public String id;
      public String systemPresence;
    }
    public class IncomingGenesysCloudStatus {
      public IncomingGenesysCloudStatusObj targetStatus;
      public IncomingGenesysCloudStatusObj currentStatus;
    }
    //#endregion IncomingStatusChange Obj
    // -----------------------------------------------------------------------------------------------------------------
  }