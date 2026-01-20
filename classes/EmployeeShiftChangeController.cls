public class EmployeeShiftChangeController {

    public class ShiftWrapper {
        @AuraEnabled public String employeeName { get; set; }
        @AuraEnabled public String employeeId { get; set; }
        @AuraEnabled public Datetime startHour { get; set; }
        @AuraEnabled public Datetime endHour { get; set; }
        @AuraEnabled public String shiftId { get; set; }

        @AuraEnabled public String firstBreakProgramedTime { get; set; }
        @AuraEnabled public String secondBreakProgramedTime { get; set; }
        @AuraEnabled public String trainingProgramedTime { get; set; }
        @AuraEnabled public String isDayOff { get; set; }

        // @AuraEnabled public List<ShiftBlock> ShiftBlocksWrapper { get; set; }
    }
    // public class ShiftBlockWrapper {
    //     @AuraEnabled public Datetime timeIn { get; set; }
    //     @AuraEnabled public Datetime timeOut { get; set; }
    //     @AuraEnabled public String status { get; set; }
    // }

    public class PicklistWrapper {
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String value { get; set; }

        public PicklistWrapper(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    @AuraEnabled
    public static Map<String, Date> getMonthDates(){

        Map<String, Date> monthDates = new Map<String, Date>();

        Date todayDate = Date.today();
        Date endOfMonth = todayDate.toStartOfMonth().addMonths(1).addDays(-1);

        monthDates.put('start', todayDate);
        monthDates.put('end', endOfMonth);

        return monthDates;
    }

    @AuraEnabled
    public static List<Contact> userContactInfo(String userId) {
        List<Contact> currentContact = [SELECT Id, Name, Email, AccountId, Channel__c, UserId__c FROM Contact WHERE UserId__c = :userId];

        return currentContact;
    }

    @AuraEnabled
    public static List<ShiftWrapper> getCurrentContactShifts(String userId) {

        List<ShiftWrapper> shiftList = new List<ShiftWrapper>();
        Date startOfMonth = Date.today().toStartOfMonth();

        List<Contact> uenoContact = [SELECT Id FROM Contact WHERE UserId__c = :userId];

        List<Shift__c> employeeShifts = [
            SELECT Id, Start__c, End__c, Agent__c, Agent__r.Name, Is_Day_Off__c
            FROM Shift__c
            WHERE Agent__c = : uenoContact[0].Id 
            AND Start__c >= :startOfMonth
            AND ToApprove__c = false
            ORDER BY Start__c     
        ];
        list<Id> lstShiftIds = new list<Id>();
        for (Shift__c shift : employeeShifts) {
            lstShiftIds.add(shift.Id);
        }
        List<Shift_Block__c> employeeShiftsBlocks = [
            SELECT Id, Shift__c, Type__c, Start__c, End__c
            FROM Shift_Block__c
            WHERE Shift__c IN :lstShiftIds
            ORDER BY Start__c     
        ];
        map<Id, List<Shift_Block__c>> mapShiftIdLstBlocks = new map<Id, List<Shift_Block__c>>();
        for (Shift_Block__c block : employeeShiftsBlocks) {
            if(!mapShiftIdLstBlocks.containsKey(block.Shift__c)){
                mapShiftIdLstBlocks.put(block.Shift__c, new List<Shift_Block__c>{block});
            } else {
                mapShiftIdLstBlocks.get(block.Shift__c).add(block);
            }
        }

        for(Shift__c shift : employeeShifts) {
            ShiftWrapper shiftWrapper = new ShiftWrapper();
            shiftWrapper.employeeName = shift.Agent__r.Name;
            shiftWrapper.employeeId = shift.Agent__c;
            shiftWrapper.startHour = shift.Start__c;
            shiftWrapper.endHour = shift.End__c;
            shiftWrapper.shiftId = shift.Id;
            if(shift.Is_Day_Off__c){
                shiftWrapper.isDayOff = 'Si';
            }
            if (mapShiftIdLstBlocks.containsKey(shift.Id)) {
                List<Shift_Block__c> lstShiftBlocks = mapShiftIdLstBlocks.get(shift.Id);
                for (Shift_Block__c block : lstShiftBlocks) {
                    if (block.Type__c=='Break' && shiftWrapper.firstBreakProgramedTime==null) {
                        shiftWrapper.firstBreakProgramedTime = block.Start__c.format('HH:mm')+ ' - ' + block.End__c.format('HH:mm');
                        continue;
                    }
                    if (block.Type__c=='Break' && shiftWrapper.secondBreakProgramedTime==null) {
                        shiftWrapper.secondBreakProgramedTime = block.Start__c.format('HH:mm')+ ' - ' + block.End__c.format('HH:mm');
                        continue;
                    }
                    if (block.Type__c=='Training' && shiftWrapper.trainingProgramedTime==null) {
                        shiftWrapper.trainingProgramedTime = block.Start__c.format('HH:mm')+ ' - ' + block.End__c.format('HH:mm');
                        continue;
                    }
                }
            }
            shiftList.add(shiftWrapper);
        }
        System.debug(shiftList);
        return shiftList;
    }

    @AuraEnabled
    public static List<Contact> getContactByLocalAndChannel(Contact currentContact) {

        List<Contact> contacts = new List<Contact>();

        contacts = [
            SELECT Id, Name, Email, AccountId, Channel__c 
            FROM Contact
            WHERE AccountId = :currentContact.AccountId
            AND Channel__c = :currentContact.Channel__c
            AND Id != :currentContact.Id
        ];

        return contacts;

    }

    @AuraEnabled(Cacheable=false)
    public static List<ShiftWrapper> getShiftsToChange(String contactId, String startDate, String endDate){

        List<ShiftWrapper> shiftList = new List<ShiftWrapper>();
        Date dateStartParsed;
        if ( startDate!='' ) {
            List<String> lstDateStart = startDate.split('-');
            dateStartParsed = Date.newInstance(Integer.valueOf(lstDateStart[0]), Integer.valueOf(lstDateStart[1]), Integer.valueOf(lstDateStart[2]));
        }else {
            dateStartParsed = Date.today().toStartOfMonth();
        }

        DateTime dateEndParsed;
        if ( endDate!='' ) {
            List<String> lstDateEnd = endDate.split('-');
            dateEndParsed = Date.newInstance(Integer.valueOf(lstDateEnd[0]), Integer.valueOf(lstDateEnd[1]), Integer.valueOf(lstDateEnd[2]));
        }else {
            dateEndParsed = Date.today();
        }

        List<Shift__c> employeeShifts = [
            SELECT Id, Start__c, End__c, Agent__c, Agent__r.Name, Is_Day_Off__c
            FROM Shift__c
            WHERE Agent__c = : contactId
            AND Start__c >= :dateStartParsed
            AND End__c <= :dateEndParsed
        ];

        list<Id> lstShiftIds = new list<Id>();
        for (Shift__c shift : employeeShifts) {
            lstShiftIds.add(shift.Id);
        }
        List<Shift_Block__c> employeeShiftsBlocks = [
            SELECT Id, Shift__c, Type__c, Start__c, End__c
            FROM Shift_Block__c
            WHERE Shift__c IN :lstShiftIds
            ORDER BY Start__c     
        ];
        map<Id, List<Shift_Block__c>> mapShiftIdLstBlocks = new map<Id, List<Shift_Block__c>>();
        for (Shift_Block__c block : employeeShiftsBlocks) {
            if(!mapShiftIdLstBlocks.containsKey(block.Shift__c)){
                mapShiftIdLstBlocks.put(block.Shift__c, new List<Shift_Block__c>{block});
            } else {
                mapShiftIdLstBlocks.get(block.Shift__c).add(block);
            }
        }
        for(Shift__c shift : employeeShifts) {
            ShiftWrapper shiftWrapper = new ShiftWrapper();
            shiftWrapper.employeeName = shift.Agent__r.Name;
            shiftWrapper.employeeId = shift.Agent__c;
            shiftWrapper.startHour = shift.Start__c;
            shiftWrapper.endHour = shift.End__c;
            shiftWrapper.shiftId = shift.Id;
            if(shift.Is_Day_Off__c){
                shiftWrapper.isDayOff = 'Si';
            }
            if (mapShiftIdLstBlocks.containsKey(shift.Id)) {
                List<Shift_Block__c> lstShiftBlocks = mapShiftIdLstBlocks.get(shift.Id);
                for (Shift_Block__c block : lstShiftBlocks) {
                    if (block.Type__c=='Break' && shiftWrapper.firstBreakProgramedTime==null) {
                        shiftWrapper.firstBreakProgramedTime = block.Start__c.format('HH:mm')+ ' - ' + block.End__c.format('HH:mm');
                        continue;
                    }
                    if (block.Type__c=='Break' && shiftWrapper.secondBreakProgramedTime==null) {
                        shiftWrapper.secondBreakProgramedTime = block.Start__c.format('HH:mm')+ ' - ' + block.End__c.format('HH:mm');
                        continue;
                    }
                    if (block.Type__c=='Training' && shiftWrapper.trainingProgramedTime==null) {
                        shiftWrapper.trainingProgramedTime = block.Start__c.format('HH:mm')+ ' - ' + block.End__c.format('HH:mm');
                        continue;
                    }
                }
            }
            shiftList.add(shiftWrapper);
        }

        return shiftList;

    }

    @AuraEnabled
    public static List<PicklistWrapper> getDayOffTypes() {

        List<PicklistWrapper> picklistOptions = new List<PicklistWrapper>();

        Schema.DescribeFieldResult fieldResult = Shift_Block__c.Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry pickListVal : ple) {
            if(pickListVal.getValue() != 'Work' || pickListVal.getValue() != 'Training' || pickListVal.getValue() != 'Break' ) {
                picklistOptions.add(new PicklistWrapper(pickListVal.getLabel(), pickListVal.getValue()));
            }
        }
        return picklistOptions;
    }

    @AuraEnabled
    public static String sendReplacementForApproval(List<ShiftWrapper> selectedShifts, String contactToAssign, String userRequester){
        try {

            List<Shift__c> lstShiftsToUpdate = getShiftsToUpdate(selectedShifts, contactToAssign);
            if (lstShiftsToUpdate.size()>0) {
                update lstShiftsToUpdate;
            }
            List<Approval.ProcessResult> approvalResult = handleApprovalProcess(userRequester, contactToAssign, lstShiftsToUpdate, 'Shift_Change_Request');
            return 'Success';
        } catch (Exception error) {
            System.debug(error.getMessage() + ' ' + error.getLineNumber());
            throw new AuraHandledException(error.getMessage());
        }
    }

    private static List<Shift__c> getShiftsToUpdate(List<ShiftWrapper> selectedShifts, String contactToAssign){

        Set<Id> setIdShifts = new Set<Id>();
        for (ShiftWrapper objShift : selectedShifts) {
            setIdShifts.add(objShift.shiftId);
        }

        List<Shift__c> lstShifts = [
            SELECT Id, Agent_Suggested_Replacement__c, OwnerId
            FROM Shift__c
            WHERE Id IN :setIdShifts
        ];

        Contact objContact = [
            SELECT Id, UserId__c
            FROM Contact
            WHERE Id =:contactToAssign
        ];

        for (Shift__c objShift : lstShifts) {
            objShift.Agent_Suggested_Replacement__c = contactToAssign;
            objShift.Executive__c = objContact.UserId__c;
        }

        return lstShifts;
    }

    private static List<Approval.ProcessResult> handleApprovalProcess(String userRequester, String contactToAssign, List<Shift__c> lstShiftsToSendRequest, String processName) {
        try {
            List<Id> lstUserIdsToAssign = new List<Id>();
            if (contactToAssign!='') {
                List<Contact> lstContactToAssign = [ SELECT UserId__c, Account.Manager_UenoX__r.UserId__c FROM Contact WHERE Id =:contactToAssign];
                lstUserIdsToAssign.add(Id.valueOf(lstContactToAssign[0].UserId__c));
            }
            List<Approval.ProcessSubmitRequest> lstReqs = new List<Approval.ProcessSubmitRequest>();
            for (Shift__c shift : lstShiftsToSendRequest) {
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setComments('Presentar solicitud de aprobación.');
                req.setObjectId(shift.Id);
                req.setSubmitterId(userRequester);
                req.setProcessDefinitionNameOrId(processName);
                req.setSkipEntryCriteria(true);
                if (lstUserIdsToAssign.size()>0) {
                    req.setNextApproverIds(new List<Id>{lstUserIdsToAssign[0]});
                }
                lstReqs.add(req);
            }
            List<Approval.ProcessResult> results = Approval.process(lstReqs);
            return results;
        } catch (Exception error) {
            System.debug(error.getMessage() + ' ' + error.getLineNumber());
            throw new AuraHandledException(error.getMessage());
        }
    }

    @AuraEnabled
    public static String sendDayOffForApproval(String userRequester, String contactId, String startDate, String endDate, String dayOffType) {

        try {

            List<Contact> currentContact = [SELECT Id, Name, Email, AccountId FROM Contact WHERE Id = :contactId];

            List<String> lstDateStart = startDate.split('-');
            Datetime dateTimeStart00 = DateTime.newInstance(Integer.valueOf(lstDateStart[0]), Integer.valueOf(lstDateStart[1]), Integer.valueOf(lstDateStart[2]), 0, 0, 0);
            Datetime dateTimeStart59 = DateTime.newInstance(Integer.valueOf(lstDateStart[0]), Integer.valueOf(lstDateStart[1]), Integer.valueOf(lstDateStart[2]), 23, 59, 59);
            
            List<String> lstDateEnd = endDate.split('-');
            DateTime dateTimeEnd00 = DateTime.newInstance(Integer.valueOf(lstDateEnd[0]), Integer.valueOf(lstDateEnd[1]), Integer.valueOf(lstDateEnd[2]), 0, 0, 0);
            DateTime dateTimeEnd59 = DateTime.newInstance(Integer.valueOf(lstDateEnd[0]), Integer.valueOf(lstDateEnd[1]), Integer.valueOf(lstDateEnd[2]), 23, 59, 59);

            List<Shift__c> lstShiftsToUpdate = [
                SELECT Id, Agent__c, Start__c, End__c, ToDelete__c, Day_Off_Type__c, Local__c
                FROM Shift__c
                WHERE Agent__c = : contactId
                AND Start__c >= : dateTimeStart00
                AND End__c <= : dateTimeEnd59
            ];

            if (lstShiftsToUpdate.size()>0) {
                for (Shift__c shift : lstShiftsToUpdate) {
                    shift.ToDelete__c = true;//para supuestamente borrar
                }
                update lstShiftsToUpdate;
            }

            Integer intStart = Integer.valueOf(lstDateStart[2]);
            Integer intEnd = Integer.valueOf(lstDateEnd[2]);
            dateTimeStart00 = dateTimeStart00.addDays(-1);
            dateTimeStart59 = dateTimeStart59.addDays(-1);
            List<Shift__c> lstShiftsToProcess = new List<Shift__c>();

            for (Integer i = intStart; i <= intEnd; i++) {
                dateTimeStart00 = dateTimeStart00.addDays(1);
                dateTimeStart59 = dateTimeStart59.addDays(1);
                Shift__c objShift = new Shift__c(
                    Agent__c = contactId,
                    Executive__c = userRequester,
                    Start__c = dateTimeStart00,
                    End__c = dateTimeStart59,
                    ToApprove__c = true,
                    Is_Day_Off__c = true,
                    Day_Off_Type__c = dayOffType,
                    Local__c = currentContact[0]?.AccountId
                );
                lstShiftsToProcess.add(objShift);
            }

            if (lstShiftsToProcess.size()>0) {
                insert lstShiftsToProcess;
                List<Approval.ProcessResult> approvalResult = handleApprovalProcess(userRequester, '', lstShiftsToProcess, 'Shift_Change_DayOff');
            }
            return 'Success';
        } catch (Exception error) {
            System.debug(error);
            throw new AuraHandledException(error.getMessage());
        }
    }
}