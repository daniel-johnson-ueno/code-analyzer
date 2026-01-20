public without sharing class TA_ChangeCaseArea{
    public static void handleChangeCaseArea(List<Case> newCases, Map<Id, Case> oldCaseMap) {

        Set<Id> queueIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        
        List<Case> casesToUpdate = new List<Case>();

        // Identificar los casos que deben actualizarse y los ids de usuario y cola correspondientes
        for (Case c : newCases) {
            Case oldCase = oldCaseMap != null ? oldCaseMap.get(c.Id) : null;
            
            // Si el caso es nuevo, o el OwnerId ha cambiado
            if (oldCase == null || oldCase.OwnerId != c.OwnerId) {
                casesToUpdate.add(c);
                if (String.valueOf(c.OwnerId).startsWith('00G')) {
                    queueIds.add(c.OwnerId);  // ID de cola
                } else if (String.valueOf(c.OwnerId).startsWith('005')) {
                    userIds.add(c.OwnerId);   // ID de usuario
                }
            }
        }

        // Si existen casos a actualizar, obtener información de las colas y usuarios
        if (!casesToUpdate.isEmpty()) {
            if (!queueIds.isEmpty()) {
                getQueueInfo(casesToUpdate, queueIds);
            }
            if (!userIds.isEmpty()) {
                getUserInfo(casesToUpdate, userIds);
            }
        }
    }

    private static void getQueueInfo(List<Case> newCases, Set<Id> queueIds) {
        Map<Id, Group> queueMap = new Map<Id, Group>();
        
        if (!queueIds.isEmpty()) {
            for (Group g : [SELECT Id, Name, Description FROM Group WHERE Type = 'Queue' AND Id IN :queueIds]) {
                queueMap.put(g.Id, g);
            }
        }

        for (Case c : newCases) {
            if (c.OwnerId != null && queueMap.containsKey(c.OwnerId)) {
                Group queue = queueMap.get(c.OwnerId);
                c.Area_actual__c = queue.Description;
                c.Equipo_Actual__c = queue.Name;
            } else {
                c.Area_actual__c = null;
                c.Equipo_Actual__c = null;
            }
        }
    }

    private static void getUserInfo(List<Case> newCases, Set<Id> userIds) {
        Map<Id, User> userMap = new Map<Id, User>();

        if (!userIds.isEmpty()) {
            for (User u : [SELECT Id, Division, Assigned_Team__c FROM User WHERE Id IN :userIds]) {
                userMap.put(u.Id, u);
            }
        }

        for (Case c : newCases) {
            User userOwner = userMap.get(c.OwnerId);
            if (userOwner != null) {
                c.Area_actual__c = String.isNotBlank(userOwner.Division) ? userOwner.Division : 'Sin area';
                c.Equipo_Actual__c = String.isNotBlank(userOwner.Assigned_Team__c) ? userOwner.Assigned_Team__c : 'Sin equipo';
            } else {
                c.Area_actual__c = 'Sin area';
                c.Equipo_Actual__c = 'Sin equipo';
            }
        }
    }
}