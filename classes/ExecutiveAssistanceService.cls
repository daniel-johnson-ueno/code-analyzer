public with sharing class ExecutiveAssistanceService {
    /* TODO: Las querys deberian estar en un DAO.
     */

    public class ExecutiveAssistanceWrapper {
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String channel;
        @AuraEnabled
        public String manager;
        @AuraEnabled
        public String programmedTime;
        @AuraEnabled
        public String totalProgrammedHours;
        @AuraEnabled
        public String executiveFirstLogin;
        @AuraEnabled
        public String executiveLastLogin;
        @AuraEnabled
        public String connectedTime;
        @AuraEnabled
        public Boolean connectedWithoutShift;
        @AuraEnabled
        public Boolean earlyLogout;
        @AuraEnabled
        public Boolean connectedLate;
        @AuraEnabled
        public String connectedLateTime;
        @AuraEnabled
        public Boolean absent;

        public ExecutiveAssistanceWrapper() {
            this.name = '-';
            this.channel = '-';
            this.manager = '-';
            this.programmedTime = '-';
            this.executiveFirstLogin = '-';
            this.executiveLastLogin = '-';
            this.connectedTime = '-';
            this.connectedLateTime = '-';
            this.connectedWithoutShift = true;
            this.earlyLogout = false;
            this.connectedLate = false;
            this.totalProgrammedHours = '-';
            this.absent = false;
        }

    }
    //TODO: Crear DAO para las querys realizadas en el código.
    public static List<ExecutiveAssistanceWrapper> getExecutiveAssistanceResponse(Date selectedDate) {

        //Custom label que define que perfiles van a ser excluidos de la busqueda de ususarios.
        List<Executive_Assistance_Filter__mdt> filter = Executive_Assistance_Filter__mdt.getAll().values();

        List<String> usersFilterList = new List<String>();

        for(Executive_Assistance_Filter__mdt currentFilter : filter){
            usersFilterList.add(currentFilter.ProfileName__c);
        }

        List<User> activeUsers = [SELECT Id, FirstName, LastName, Division, Leader__c, Leader__r.Name, Assigned_Team__c
                                    FROM User
                                    WHERE IsActive = TRUE AND UserType ='Standard' AND Profile.Name NOT IN: usersFilterList ORDER BY Name
                                    ];

        //Crear DAO que maneje este llamado
        List<Shift__c> executiveShifts = [SELECT Id, Start__c, End__c, Executive__c, Executive__r.Name, Executive__r.Division, Executive__r.Leader__c, Executive__r.Leader__r.Name , Assigned_Hours__c
                                            FROM Shift__c
                                            WHERE DAY_ONLY(Start__c) =: selectedDate
                                        ];

//        System.debug('executiveShifts: ');
//        System.debug(executiveShifts);
//        Set<Date> shiftStartDate = new Set<Date>();
        Set<Date> shiftDate = new Set<Date>{selectedDate};

        Map<String, Shift__c> shiftsByUserId = new Map<String, Shift__c>();
        //armado de mapa de shifts por Id de usuario y fechas de inicio y fin de los turnos.
        for(Shift__c currentShift : executiveShifts){
            shiftsByUserId.put(currentShift.Executive__c, currentShift);
            shiftDate.add(currentShift.End__c.date());

        }

        Map<String, List<UserServicePresence>> USPbyUserId = getUSPByUser(shiftDate);

        if(USPbyUserId.containsKey('005Vv000003bSA6IAM') || USPbyUserId.containsKey('005Vv000003B7l1IAC') || USPbyUserId.containsKey('005Vv000002bUOXIA2')){
            for(String userId : USPbyUserId.keySet()){
                if(userId == '005Vv000003bSA6IAM' || userId == '005Vv000003B7l1IAC' || userId == '005Vv000002bUOXIA2'){
                    for(UserServicePresence presence : USPbyUserId.get(userId)){
                        System.debug(presence);
                    }
                }

            }
        }

        List<ExecutiveAssistanceWrapper> processedData = processExecutiveAssistanceData(activeUsers, shiftsByUserId, USPbyUserId);

        return processedData;
    }

    public static List<ExecutiveAssistanceWrapper> processExecutiveAssistanceData (List<User> users, Map<String, Shift__c> shiftsByUserId, Map<String, List<UserServicePresence>> USPbyUserId) {

        List<ExecutiveAssistanceWrapper> executiveAssistanceData = new List<ExecutiveAssistanceWrapper>();
        Datetime currentDateTime = Datetime.now();

        Map<Id, UserServicePresence> firstLoginPerUser = getFirstLoginAndLastLogout(USPbyUserId , true);
        Map<Id, UserServicePresence> lastLogoutPerUser = getFirstLoginAndLastLogout(USPbyUserId, false);
//        System.debug(firstLoginPerUser);
//        System.debug(lastLogoutPerUser);
        for(User currentUser : users){
//            System.debug(currentUser.FirstName);
//            System.debug(currentUser.LastName);

            String completeName = currentUser.FirstName + ' ' + currentUser.LastName;
            String programmedTime = '-';
            ExecutiveAssistanceWrapper executiveAssistance = new ExecutiveAssistanceWrapper();
            executiveAssistance.name = completeName;
            executiveAssistance.channel = currentUser.Assigned_Team__c;
            executiveAssistance.manager = currentUser.Leader__c != null ? currentUser.Leader__r.Name : '-' ;
            executiveAssistance.executiveFirstLogin = '-'; //mejorar
            executiveAssistance.executiveLastLogin = '-';//mejorar

            if(firstLoginPerUser.containsKey(currentUser.Id)){
                System.debug(firstLoginPerUser.get(currentUser.Id));
                executiveAssistance.executiveFirstLogin = firstLoginPerUser.get(currentUser.Id).CreatedDate != null ? firstLoginPerUser.get(currentUser.Id).CreatedDate.format('HH:mm') : '-';
            }

            if(lastLogoutPerUser.containsKey(currentUser.Id)){
                executiveAssistance.executiveLastLogin = lastLogoutPerUser.get(currentUser.Id).StatusEndDate != null ? lastLogoutPerUser.get(currentUser.Id).StatusEndDate.format('HH:mm') : '-';
            }

            if(shiftsByUserId.containsKey(currentUser.Id)){
                programmedTime = String.valueOf(shiftsByUserId.get(currentUser.Id).Start__c.format('HH:mm') + ' - ' + shiftsByUserId.get(currentUser.Id).End__c.format('HH:mm'));
                executiveAssistance.totalProgrammedHours = String.valueOf(shiftsByUserId.get(currentUser.Id).Assigned_Hours__c);
                executiveAssistance.connectedLateTime = connectedLateTime(executiveAssistance.executiveFirstLogin, shiftsByUserId.get(currentUser.Id));

                if(currentDateTime >= shiftsByUserId.get(currentUser.Id).End__c){
                    executiveAssistance.earlyLogout = shiftsByUserId.get(currentUser.Id).End__c.format('HH:mm') > executiveAssistance.executiveLastLogin ? true : false; //mejorar earlyLogout
                    executiveAssistance.absent = executiveAssistance.executiveFirstLogin == '-' ? true : false;

                }
            }

            executiveAssistance.programmedTime = programmedTime;
            executiveAssistance.connectedWithoutShift = programmedTime == '-' && executiveAssistance.executiveFirstLogin != '-' ? true : false;

            if(USPbyUserId.containsKey(currentUser.Id)){
                executiveAssistance.connectedTime = calculateConnectedTime(USPbyUserId.get(currentUser.Id));
            }

            //executiveAssistance.disconnectedTime = aca va un metodo que me devuelva el tiempo desconectado
            executiveAssistance.connectedLate = executiveAssistance.connectedLateTime != '-' ? true : false;
            executiveAssistanceData.add(executiveAssistance);

            System.debug(executiveAssistance);


        }
        return executiveAssistanceData;
    }

    public static Map<Id, UserServicePresence> getFirstLoginAndLastLogout(Map<String, List<UserServicePresence>> USPByUser, Boolean isFirstLogin) {

        Map<Id, UserServicePresence> presencePerUser = new Map<Id, UserServicePresence>();
        try{
            if(isFirstLogin){
                //Recorre el resultado y agrega los registros al mapa
                for (String userId : USPByUser.keySet()) {
                    if (!presencePerUser.containsKey(userId)) {
                        // Si el usuario aún no tiene un registro en el mapa, lo agregamos
                        if(USPByUser.containsKey(userId)){
                            presencePerUser.put(userId, USPByUser.get(userId)[0] ?? null);
                        }

                    }
                }
            }  else {
                //recorrer y guardar logins DESC para obtener los ultimos
                for (String userId : USPByUser.keySet()) {

                    if (!presencePerUser.containsKey(userId)) {
                        // Si el usuario aún no tiene un registro en el mapa, lo agregamos
                        if(USPByUser.containsKey(userId)){
                            presencePerUser.put(userId, USPByUser.get(userId)[USPByUser.get(userId).size()-1] ?? null);
                        }
                    }
                }
                System.debug('presencePerUser: ' + presencePerUser.size());

            }
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            System.debug('Line: ' + e.getLineNumber());
        }

        return presencePerUser;
    }




    public static Map<String, List<UserServicePresence>> getUSPByUser (Set<Date> dates){
        Map<String, List<UserServicePresence>> USPByUserId = new Map<String, List<UserServicePresence>>();
        System.debug(dates);

        List<Service_Presence_Status__mdt> presenceStatuses = Service_Presence_Status__mdt.getAll().values();

        List<String> presenceStatusesList = new List<String>();
        for (Service_Presence_Status__mdt presenceStatus : presenceStatuses) {
            if(presenceStatus.Available__c == true){
                presenceStatusesList.add(presenceStatus.Presence_Developer_Name__c);
            }

        }

        List<UserServicePresence> result = [SELECT UserId, ServicePresenceStatus.MasterLabel, User.Name, CreatedDate, StatusEndDate
        FROM UserServicePresence
        WHERE ServicePresenceStatus.DeveloperName IN : presenceStatusesList
        AND DAY_ONLY(CreatedDate) IN : dates
        ORDER BY CreatedDate ASC
        ];

        System.debug(result);

        for (UserServicePresence presence : result) {
            System.debug(presence);
            if (!USPByUserId.containsKey(presence.UserId)) {
                USPByUserId.put(presence.UserId, new List<UserServicePresence>{presence});
            } else {
                USPByUserId.get(presence.UserId).add(presence);
            }
        }

        return USPByUserId;
    }

    /*public static String connectedLateTime(String firstLoginTime, Shift__c shift) {
        Time timeFirstLogin;
        Datetime currentDateTime = Datetime.now();

        if(firstLoginTime == '-'){

            if(currentDateTime.date() == shift.Start__c.date()){
                timeFirstLogin = Time.newInstance(currentDateTime.hour(), currentDateTime.minute(), 0, 0);
            } else {
                return firstLoginTime;
            }

        } else {
            timeFirstLogin = Time.newInstance(Integer.valueOf(firstLoginTime.split(':')[0]), Integer.valueOf(firstLoginTime.split(':')[1]), 0, 0);
        }

        Time timeShiftStart = Time.newInstance(shift.Start__c.hour(), shift.Start__c.minute(), 0, 0);

//        System.debug('timeFirstLogin: ' + timeFirstLogin);
//        System.debug('timeShiftStart: ' + timeShiftStart);

        Datetime dateTimeFirstLogin = Datetime.newInstance(Date.today(), timeFirstLogin);
        Datetime dateTimeShiftStart = Datetime.newInstance(Date.today(), timeShiftStart);

        Long diffMillis = dateTimeFirstLogin.getTime() - dateTimeShiftStart.getTime();

        Long diffSeconds = diffMillis / 1000;
        Long hours = diffSeconds / 3600;
        diffSeconds = Math.mod(diffSeconds,3600);
        Long minutes = diffSeconds / 60;

        String result = '';
        if (hours > 0) {
            result += hours + ' h ';
        }
        if (minutes > 0 || hours > 0) {
            result += minutes + ' m ';
        }

        return result;
    }*/

    public static String connectedLateTime(String firstLoginTime, Shift__c shift) {

        Time timeFirstLogin;
        Datetime currentDateTime = Datetime.now();

        if(firstLoginTime == '-'){

            if(currentDateTime.date() == shift.Start__c.date()){
                timeFirstLogin = Time.newInstance(currentDateTime.hour(), currentDateTime.minute(), 0, 0);
            } else {
                return firstLoginTime;
            }

        } else {
            timeFirstLogin = Time.newInstance(Integer.valueOf(firstLoginTime.split(':')[0]), Integer.valueOf(firstLoginTime.split(':')[1]), 0, 0);
        }

        Time timeShiftStart = Time.newInstance(shift.Start__c.hour(), shift.Start__c.minute(), 0, 0);

//        System.debug('timeFirstLogin: ' + timeFirstLogin);
//        System.debug('timeShiftStart: ' + timeShiftStart);

        Datetime dateTimeFirstLogin = Datetime.newInstance(Date.today(), timeFirstLogin);
        Datetime dateTimeShiftStart = Datetime.newInstance(Date.today(), timeShiftStart);

//        Datetime shiftStart = shift.Start__c;

        Long diffMillis = dateTimeFirstLogin.getTime() - dateTimeShiftStart.getTime();
        Long totalSeconds = 0;
        if (diffMillis > 0) {
            totalSeconds = diffMillis / 1000;
            return String.valueOf(totalSeconds);
        }

        return '-';
    }

    public static String calculateConnectedTime(List<UserServicePresence> userServicePresences) {
        Long totalSeconds = 0;

        if (userServicePresences.size() > 0 && userServicePresences[userServicePresences.size()-1].StatusEndDate != null) {
            Datetime startDateTime = userServicePresences[0].CreatedDate;
            Datetime endDateTime = userServicePresences[userServicePresences.size()-1].StatusEndDate;

            Long diffMillis = endDateTime.getTime() - startDateTime.getTime();
            totalSeconds = diffMillis / 1000;
        }

        return String.valueOf(totalSeconds);
    }


    /*public static String calculateConnectedTime(List<UserServicePresence> userServicePresences){

        String result = '';

        if (userServicePresences.size() > 0 && userServicePresences[userServicePresences.size()-1].StatusEndDate != null) {

            Long diffMillis = userServicePresences[userServicePresences.size()-1].StatusEndDate.getTime() - userServicePresences[0].CreatedDate.getTime();
            Long diffSeconds = diffMillis / 1000;
            Long hours = diffSeconds / 3600;
            diffSeconds = Math.mod(diffSeconds,3600);
            Long minutes = diffSeconds / 60;

            if (hours > 0) {
                result += hours + ' h ';
            }
            if (minutes > 0 || hours > 0) {
                result += minutes + ' m ';
            }

        } else {
            result = '-';
        }
        return result;
    }*/
}