public class AgentWorkDAO {

    public class ShiftWrapper {
        public Shift__c shift { get; set; }
        public Boolean isDayOff { get; set; }
        public Boolean OtherVariable { get; set; }

        public ShiftWrapper(Shift__c shift, Boolean isDayOff) {
            this.shift = shift;
            this.isDayOff = isDayOff;
        }

        public ShiftWrapper(Object item) {
            Map<String, Object> itemFields = (Map<String, Object>) item;
            this.shift = (Shift__c) itemFields.get('shift');
            this.isDayOff = (Boolean) itemFields.get('isDayOff');
        }
    }

    public static Map<String, List<Object>> getShifts(Date searchDate, String channel) {
        DateTime startOfDay = DateTime.newInstance(searchDate, Time.newInstance(0, 0, 0, 0));
        DateTime endOfDay = DateTime.newInstance(searchDate, Time.newInstance(23, 59, 59, 999));

        List<Id> userIdsFromChannel = retrieveUsersFromChannel(channel);
        
        List<AgentWork> agentWorks = retrieveAgentWork(startOfDay, endOfDay, userIdsFromChannel);
        
        // Extraer ContactIds de los AgentWork
        Set<Id> contactIds = new Set<Id>();
        for (AgentWork aw : agentWorks) {
            if (aw.User.ContactId != null) {
                contactIds.add(aw.User.ContactId);
            }
        }

        List<ShiftWrapper> shiftWrappers = retrieveShifts(startOfDay, endOfDay, userIdsFromChannel);

        // Agregar ContactIds desde los Shifts
        for (ShiftWrapper shiftWrapper : shiftWrappers) {
            if (shiftWrapper.shift.Agent__c != null) {
                contactIds.add(shiftWrapper.shift.Agent__c);
            }
        }

        // Consultar Contactos relacionados
        Map<Id, Contact> contactMap = new Map<Id, Contact>();
        if (!contactIds.isEmpty()) {
            contactMap = new Map<Id, Contact>([SELECT Id, Name, UserId__c 
                                                FROM Contact 
                                                WHERE Id IN :contactIds]);
        }

        // Crear el mapa de resultados
        Map<String, List<Object>> results = new Map<String, List<Object>>();

        // Agregar Shifts al mapa
        for (ShiftWrapper shiftWrapper : shiftWrappers) {
            Shift__c shift = shiftWrapper.shift;
            Boolean isDayOff = shiftWrapper.isDayOff;

            String contactName = (contactMap.containsKey(shift.Agent__c)) ? contactMap.get(shift.Agent__c).Name : 'Desconocido';
            if (!results.containsKey(contactName)) {
                results.put(contactName, new List<Object>());
            }

            // Crear un mapa con información del Shift y si es Día Libre
            Map<String, Object> shiftInfo = new Map<String, Object>{'shift' => shift, 'isDayOff' => isDayOff};
            results.get(contactName).add(shiftInfo);
        }

        // Agregar AgentWork al mapa
        for (AgentWork aw : agentWorks) {
            String contactName = 'Desconocido';
            if (aw.User.ContactId != null && contactMap.containsKey(aw.User.ContactId)) {
                contactName = contactMap.get(aw.User.ContactId).Name;
            } else if (aw.User.Name != null) {
                contactName = aw.User.Name;
            }

            if (!results.containsKey(contactName)) {
                results.put(contactName, new List<Object>());
            }
            results.get(contactName).add(aw);
        }

        return results;
    }

    private static List<Id> retrieveUsersFromChannel(String channel) {
        List<Contact> contacts = [SELECT UserId__c 
                FROM Contact 
                WHERE Channel__c = :channel];

        List<Id> userIds = new List<Id>();
        for (Contact cnt : contacts) {
            userIds.add(cnt.UserId__c);
        }
        return userIds;
    }

    private static List<AgentWork> retrieveAgentWork(Datetime startOfDay, Datetime endOfDay, List<Id> userIds) {
        return [SELECT UserId, User.Name, User.ContactId, AcceptDateTime, CloseDateTime, WorkItemId,
                TYPEOF WorkItem
                        WHEN Case THEN Id
                        WHEN VoiceCall THEN Id
                        WHEN MessagingSession THEN Id
                        ELSE Id
                END
        FROM AgentWork
        WHERE AcceptDateTime >= :startOfDay
        AND AcceptDateTime <= :endOfDay
        AND UserId IN :userIds
        ];
    }

    private static List<ShiftWrapper> retrieveShifts(Datetime startOfDay, Datetime endOfDay, List<Id> userIds) {
        // Consultar todos los Shift__c en el rango de fechas
        List<Shift__c> shifts = [
            SELECT Id, Start__c, End__c, Agent__c
            FROM Shift__c 
            WHERE Start__c >= :startOfDay 
            AND Start__c <= :endOfDay
            AND Agent__r.UserId__c IN :userIds
        ];

        // Consultar los Shift_Block__c relacionados con 'Dia libre'
        Map<Id, Boolean> shiftDayOffMap = new Map<Id, Boolean>();
        for (AggregateResult ar : [
            SELECT Shift__c Id
            FROM Shift_Block__c
            WHERE Type__c = 'Dia libre'
            GROUP BY Shift__c
        ]) {
            shiftDayOffMap.put((Id) ar.get('Id'), true);
        }

        // Construir la lista de ShiftWrapper con la información de 'Dia libre'
        List<ShiftWrapper> shiftWrappers = new List<ShiftWrapper>();
        for (Shift__c shift : shifts) {
            Boolean isDayOff = shiftDayOffMap.containsKey(shift.Id);
            shiftWrappers.add(new ShiftWrapper(shift, isDayOff));
        }

        return shiftWrappers;
    }
}