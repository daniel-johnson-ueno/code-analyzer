public class CampaignMemberTriggerHandler {
    public static void handleBeforeDelete(List<CampaignMember> oldList) {
        
        User currentUser = [SELECT Id, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
        String profileName = currentUser.Profile.Name;

        Boolean hasCustomPermission = FeatureManagement.checkPermission('DeleteCampaignMembers');

        if (profileName != 'System Administrator' && !hasCustomPermission) {
            for (CampaignMember cm : oldList) { cm.addError('Permisos insuficientes. Tu usuario no tiene permisos para hacer esta acción. Para hacerlo, ponte en contacto con tu administrador.');}
        }
    }
}