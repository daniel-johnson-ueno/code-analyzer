/**
 * @description       : 
 * @author            : Noe Vasquez
 * @group             : 
 * @last modified on  : 06-30-2025
 * @last modified by  : Noe Vasquez
**/
public without sharing class CampaignMemberController {
    private static final Id currentUserId = UserInfo.getUserId();

    private static final String BASE_QUERY = 'SELECT Id, Name, Campaign.Name, CampaignId, Status, AssignedExecutive__c, AssignedExecutive__r.Name, '+
                        'CampaignMember__c, Substatus__c, Priority__c, DueDate__c, BrazeInteraction__c, EntryPeriod__c, Product__c, InteractionType__c, ' +
                        'Comments__c, Phone, Email ' +
                        'FROM CampaignMember ';
    
    private static final String WHERE_CONDITION = 'WHERE AssignedExecutive__c = :currentUserId';
    private static final String ORDER_BY = ' ORDER BY Name, Campaign.Name';

    @AuraEnabled
    public static List<CampaignMember> getFilteredMembers(String viewType) {
        String conditions = '';
        Boolean allowWhereBase = true;
        switch on viewType {
            when 'AsignadosAmi' {
                conditions = '';
            }
            
            when 'Convertidos' {
                conditions = ' AND Status = \'Convertido\'';
            }
            when 'No Interesados' {
                conditions = ' AND Status = \'No interesado\'';
            }
            when 'Pendientes' {
                conditions = ' AND (Status = \'Pendiente\' )';
            
            }
            when 'Todos los Pendientes' {
                allowWhereBase = false;
                conditions = ' WHERE  Status = \'Pendiente\' ';

            }
        }
        if(allowWhereBase) {
            conditions = WHERE_CONDITION + conditions; 
        } 

        return Database.query(BASE_QUERY + conditions + ORDER_BY);
    }

    @AuraEnabled(cacheable=true)
    public static List<CampaignMember> searchCampaignMembersByName(String name, String viewType) {
        Id currentUserId = UserInfo.getUserId();
        String conditions = '';
        Boolean allowWhereBase = true;
        switch on viewType {
            when 'AsignadosAmi' {
                conditions = '';
            }
            
            when 'Convertidos' {
                conditions = ' AND Status = \'Convertido\'';
            }
            when 'No Interesados' {
                conditions = ' AND Status = \'No interesado\'';
            }
            when 'Pendientes' {
                conditions = ' AND (Status = \'Pendiente\' )';

            }
            when 'Todos los Pendientes' {
                allowWhereBase = false;
                conditions = ' WHERE  Status = \'Pendiente\' ';


            }
        }
        
        if(name != null && name != '') {
            name = '%' + name + '%';
            conditions +=  ' AND (Name LIKE :name OR Campaign.Name LIKE :name OR Status LIKE :name '+ 
            'OR Substatus__c LIKE :name OR AssignedExecutive__r.Name LIKE :name)';
        }
        
        if(allowWhereBase) { //no es admin
            conditions = WHERE_CONDITION + conditions; 
        } 

        System.debug('Query: ' + BASE_QUERY + conditions + ORDER_BY);
        return Database.query(BASE_QUERY + conditions + ORDER_BY);
    }

    @AuraEnabled(cacheable=true)
    public static List<PermissionSetAssignment> getUserPermissionsSet() {
        List<PermissionSetAssignment> permissionSetList = new List<PermissionSetAssignment>();
        
        List<PermissionSetAssignment> psaList = [
            SELECT PermissionSet.Name
            FROM PermissionSetAssignment
            WHERE AssigneeId = :UserInfo.getUserId()
        ];
        
        for (PermissionSetAssignment psa : psaList) {
            permissionSetList.add(psa);
        }
        return permissionSetList;
    }

    @AuraEnabled(cacheable=true)
    public static List<Manager_CampaignMembers__mdt> getMetadataProfiles() {
        
        List<Manager_CampaignMembers__mdt> profileSettings = [
            SELECT Id, Label, DeveloperName, isManager__c FROM Manager_CampaignMembers__mdt WHERE Activo__c = true
        ];
        
        List<Manager_CampaignMembers__mdt> permissionSetsNames = new List<Manager_CampaignMembers__mdt>();
        for (Manager_CampaignMembers__mdt setting : profileSettings) {
            permissionSetsNames.add(setting);
        }
        return permissionSetsNames;
    }
    

    @AuraEnabled
    public static void updateCampaignMembers(List<Id> campaignMemberIds, Id newContactId) {
        List<CampaignMember> membersToUpdate = [SELECT Id, AssignedExecutive__c FROM CampaignMember WHERE Id IN :campaignMemberIds];

        for (CampaignMember cm : membersToUpdate) {
            cm.AssignedExecutive__c = newContactId;
        }
        try {
            update membersToUpdate;

        }
        catch(Exception ex) {
            System.debug('Error al actualizar miembro de campaña: ' + ex.getMessage());
        }
    }
    
}