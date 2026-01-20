public without sharing class OpportunitiesListViewHelper {
    public class PlatformEventCreationResponse {
        @AuraEnabled
        public Boolean success;
        @AuraEnabled
        public String message;
    
        public PlatformEventCreationResponse(Boolean success, String message) {
          this.success = success;
          this.message = message;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getOpportunities(){
        List<Opportunity> options = [SELECT Id, Name, AccountId, Account.Name, Amount, CloseDate, StageName, OwnerId, Owner.Name
                                        FROM Opportunity WHERE StageName != 'Exitoso' AND  StageName != 'Rechazado' 
                                        AND StageName != 'Perdida POS' AND  StageName != 'Closed Won' AND StageName != 'Desembolso y Cierre' 
                                        AND StageName != 'No exitoso' AND StageName != 'Closed Lost' ORDER BY createdDate desc LIMIT 1000];

        
        Map<String, String> stageMap = getPicklistValues('Opportunity', 'StageName');
        // Mapear los valores de picklist a los registros
        for (Opportunity option : options) {
            option.StageName = stageMap.get(option.StageName);
        }
        
        return options;
    }

    private static Map<String, String> getPicklistValues(String sObjectName, String fieldName) {
        Map<String, String> picklistMap = new Map<String, String>();
        Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap().get(fieldName).getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
        
        for (Schema.PicklistEntry entry : picklistEntries) {
            picklistMap.put(entry.getValue(), entry.getLabel());
        }
        
        return picklistMap;
    }

    @AuraEnabled(cacheable=true)
    public static List<Opportunity> searchOpportunities(String searchString) {
        try {
            String query = '%' + searchString + '%';
            List<Opportunity> results = [SELECT  Id, Name, AccountId, Account.Name,  Amount, CloseDate, StageName, OwnerId, Owner.Name
                                                FROM Opportunity
                                                WHERE Account.Name LIKE :query
                                                OR Name LIKE :query
                                                OR Owner.Name LIKE :query
                                                OR StageName LIKE :query
                                                LIMIT 1000];
            Map<String, String> stageMap = getPicklistValues('Opportunity', 'StageName');
          
            for (Opportunity result : results) {
                result.StageName = stageMap.get(result.StageName); 
            }                                    
            return results;
        } catch (Exception e) { System.debug('Error en searchOpportunities: ' + e.getMessage());  return new List<Opportunity>();
        }
    }

    @AuraEnabled
    public static Map<String, Object> updateOpportunities(List<Id> selectedIds, Map<String, Object> updatedValues, String baseUrl) {
        Map<String, Object> response = new Map<String, Object>();
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();

        try {
            String ownerValue = (String) updatedValues.get('OwnerId');
            System.debug('OwnerId recibido en Apex: ' + ownerValue);

            List<Opportunity> opportunities = [
                SELECT Id, Name, Owner.Email
                FROM Opportunity 
                WHERE Id IN :selectedIds
            ];

            for (Opportunity oppToUpdate : opportunities) {
                oppToUpdate.OwnerId = ownerValue; 
                opportunitiesToUpdate.add(oppToUpdate);
            }

            update opportunitiesToUpdate;

            User newOwner = [SELECT Id, Name, Email FROM User WHERE Id = :ownerValue LIMIT 1];

            String emailBody = 'Hola ' + newOwner.Name + ',<br/><br/>';
            emailBody += 'Se te han asignado las siguientes oportunidades de forma masiva:<br/><ul>';

            for (Opportunity opp : opportunitiesToUpdate) {
                String oppLink = baseUrl + '/' + opp.Id;
                emailBody += '<li><a href="' + oppLink + '">' + opp.Name + '</a></li>';
            }
            emailBody += '</ul><br/>Por favor revisa Salesforce para más detalles.<br/><br/>Gracias.';

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { newOwner.Email });
            email.setSubject('Asignación masiva de oportunidades');
            email.setHtmlBody(emailBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });

            response.put('success', true);
            response.put('message', 'Oportunidades actualizadas y notificación enviada correctamente.');

        } catch (Exception e) {
            response.put('success', false);
            response.put('message', 'Error al actualizar la oportunidad: ' + e.getMessage());
        }

        return response;
    }

    @AuraEnabled(cacheable=true)
    public static List<User> getActiveUsers() {
        return [SELECT Id, Name FROM User WHERE IsActive = true ORDER BY Name];
    }
  
}