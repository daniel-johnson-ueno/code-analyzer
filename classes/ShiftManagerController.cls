public with sharing class ShiftManagerController {

    public class ShiftWrapper {
        @AuraEnabled public String employeeName { get; set; }
        @AuraEnabled public String employeeEmail { get; set; }
        @AuraEnabled public Datetime startHour { get; set; }
        @AuraEnabled public Datetime endHour { get; set; }
        @AuraEnabled public String programedWorkingHours { get; set; }
        @AuraEnabled public String firstBreakProgramedTime { get; set; }
        @AuraEnabled public String secondBreakProgramedTime { get; set; }
        @AuraEnabled public String trainingProgramedTime { get; set; }
        @AuraEnabled public String programedDateIn { get; set; }
        @AuraEnabled public String programedDateOut { get; set; }
        @AuraEnabled public Boolean isDayOff { get; set; }

        @AuraEnabled public List<ShiftBlockWrapper> shiftBlocks { get; set; }
    }

    public class ShiftBlockWrapper {
        @AuraEnabled public Datetime timeIn { get; set; }
        @AuraEnabled public Datetime timeOut { get; set; }
        @AuraEnabled public String status { get; set; }
    }

    // Método para cargar datos CSV y procesarlos en ShiftWrapper y ShiftBlockWrapper
    @AuraEnabled
    public static List<ShiftWrapper> importCsvData(List<String> csvLines) {

        try{
            if (csvLines == null || csvLines.isEmpty() || csvLines.size() < 2) {
                throw new AuraHandledException('El archivo CSV no contiene datos.');
            }
            Map<String, Map<String, ShiftWrapper>> shiftWrapperListByDate = new Map<String, Map<String, ShiftWrapper>>();

            for (Integer i = 1; i < csvLines.size(); i++) {
                String line = csvLines[i];
                List<String> values = line.split(',');

                if (values.size() < 7) {
                    continue;
                }

                String email = values[0].trim();
                String name = values[1].trim();
                String status = values[2].trim();
                String dateIn = values[3].trim();
                String dateOut = values[4].trim();
                String timeIn = values[5].trim();
                String timeOut = values[6].trim();

                if (timeIn != 'NA' && timeOut != 'NA') {
                    Datetime formatedStartDate = formatDateTime(dateIn, timeIn);
                    Datetime formatedEndDate = formatDateTime(dateOut, timeOut);

                    String dateKey = dateIn + '-' + dateOut;
                    if (!shiftWrapperListByDate.containsKey(dateKey)) {
                        shiftWrapperListByDate.put(dateKey, new Map<String, ShiftWrapper>());
                    }

                    Map<String, ShiftWrapper> shiftMapByName = shiftWrapperListByDate.get(dateKey);
                    if (!shiftMapByName.containsKey(name)) {
                        ShiftWrapper shift = new ShiftWrapper();
                        shift.employeeName = name;
                        shift.employeeEmail = email;
                        shift.shiftBlocks = new List<ShiftBlockWrapper>();
                        shiftMapByName.put(name, shift);
                    }

                    ShiftWrapper currentShift = shiftMapByName.get(name);
                    currentShift.isDayOff = false;
                    if (status == 'Day Off' || status == 'Half-yearly day off' || status == 'Unpaid day off' || status == 'Paid day off' || status == 'Birthday') {
                        // Crear solo un bloque para "Day Off"
                        ShiftBlockWrapper shiftBlock = new ShiftBlockWrapper();
                        shiftBlock.status = status;
                        shiftBlock.timeIn = formatedStartDate;
                        shiftBlock.timeOut = formatedEndDate;
                        currentShift.isDayOff = true;
                        currentShift.shiftBlocks.clear(); // Asegura que no existan otros bloques
                        currentShift.shiftBlocks.add(shiftBlock);

                        // Actualizar detalles del turno principal
                        currentShift.startHour = formatedStartDate;
                        currentShift.endHour = formatedEndDate;
                        currentShift.programedWorkingHours = timeIn + ' - ' + timeOut;
                        currentShift.programedDateIn = dateIn;
                        currentShift.programedDateOut = dateOut;

                        // Salir del procesamiento de este turno
                        continue;
                    }

                    // Procesamiento de otros estados como "Work", "Break1", "Break2", etc.
                    ShiftBlockWrapper shiftBlock = new ShiftBlockWrapper();
                    if (status != 'Work') {
                        shiftBlock.status = status;
                        shiftBlock.timeIn = formatedStartDate;
                        shiftBlock.timeOut = formatedEndDate;
                        currentShift.shiftBlocks.add(shiftBlock);
                    }

                    if (status == 'Work' && currentShift.programedWorkingHours == null) {
                        currentShift.startHour = formatedStartDate;
                        currentShift.endHour = formatedEndDate;
                        currentShift.programedWorkingHours = timeIn + ' - ' + timeOut;
                        currentShift.programedDateIn = dateIn;
                        currentShift.programedDateOut = dateOut;
                    } else if (status == 'Break1' && currentShift.firstBreakProgramedTime == null) {
                        currentShift.firstBreakProgramedTime = timeIn + ' - ' + timeOut;
                    } else if (status == 'Break2' && currentShift.secondBreakProgramedTime == null) {
                        currentShift.secondBreakProgramedTime = timeIn + ' - ' + timeOut;
                    } else if (status == 'Training' && currentShift.trainingProgramedTime == null) {
                        currentShift.trainingProgramedTime = timeIn + ' - ' + timeOut;
                    }
                }

            }

            // Consolidar la lista final de turnos
            List<ShiftWrapper> shiftList = new List<ShiftWrapper>();
            for (String dateKey : shiftWrapperListByDate.keySet()) {
                shiftList.addAll(shiftWrapperListByDate.get(dateKey).values());
            }
            return shiftList;

        }catch(Exception e){
            System.debug(e);
            AuraHandledException ex = new AuraHandledException(e.getMessage());
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'ShiftManagerController', 'importCsvData');
            throw ex;
        }

    }

    @AuraEnabled
    public static void insertNewShifts(List<ShiftWrapper> shiftList) {

        List<Shift__c> shiftsToInsert = new List<Shift__c>();
        Map<ShiftWrapper, List<Shift_Block__c>> shiftBlocksByWrapper = new Map<ShiftWrapper, List<Shift_Block__c>>();
        Set<String> employeeEmails = new Set<String>();

        try{

            for (ShiftWrapper sw : shiftList) {
                employeeEmails.add(sw.employeeEmail);
            }

            Date startOfMonthMinus15 = Date.today().toStartOfMonth().addDays(-15);

            //map to store existing shifts
            Map<String, List<Shift__c>> shiftsByDate = new Map<String, List<Shift__c>>();
            List<Shift__c> existingShifts = [SELECT Id, Start__c, End__c, Agent__c, Agent__r.Name, Agent__r.Email FROM Shift__c WHERE Start__c >= : startOfMonthMinus15 AND Agent__r.Email IN :employeeEmails];

            if(existingShifts.size() > 0){
                for(Shift__c shift : existingShifts){

                    String startDate = String.valueOf(shift.Start__c.year()) + '-' + String.valueOf(shift.Start__c.month()) + '-' + String.valueOf(shift.Start__c.day());
                    String endDate = String.valueOf(shift.End__c.year()) + '-' + String.valueOf(shift.End__c.month()) + '-' + String.valueOf(shift.End__c.day());


                    if(!shiftsByDate.containsKey(startDate + '' + endDate + '' + shift.Agent__c)){
                        shiftsByDate.put(startDate + '' + endDate + '' + shift.Agent__c, new List<Shift__c>{shift});
                    } else {
                        shiftsByDate.get(startDate + '' + endDate + '' + shift.Agent__c).add(shift);
                    }
                }
            }
            //end
            List<Contact> employees = [SELECT Id, Email, AccountId FROM Contact WHERE Email IN :employeeEmails];
            List<Shift__c> shiftsToDelete = new List<Shift__c>();
            Map<String, Contact> employeeByEmail = new Map<String, Contact>();
            for (Contact employee : employees) {
                employeeByEmail.put(employee.Email, employee);
            }

            for (ShiftWrapper currentShift : shiftList) {
                Shift__c shift = new Shift__c();
                shift.Start__c = currentShift.startHour;
                shift.End__c = currentShift.endHour;
                shift.Agent__c = employeeByEmail.get(currentShift.employeeEmail)?.Id;
                shift.Local__c = employeeByEmail.get(currentShift.employeeEmail)?.AccountId;
                System.debug(currentShift.isDayOff);
                shift.Is_Day_Off__c = currentShift.isDayOff;
                System.debug(currentShift.employeeEmail);
                System.debug(shift.Start__c);
                System.debug(shift.End__c);
                String startDate = String.valueOf(shift.Start__c.year()) + '-' + String.valueOf(shift.Start__c.month()) + '-' + String.valueOf(shift.Start__c.day());
                String endDate = String.valueOf(shift.End__c.year()) + '-' + String.valueOf(shift.End__c.month()) + '-' + String.valueOf(shift.End__c.day());


                if(shiftsByDate.size() > 0){
                    if(shiftsByDate.containsKey(startDate + '' + endDate + '' + shift.Agent__c)){
                        shiftsToDelete.addAll(shiftsByDate.get(startDate + '' + endDate + '' + shift.Agent__c));
                    }
                }

                shiftsToInsert.add(shift);

                shiftBlocksByWrapper.put(currentShift, sortShiftBlocks(currentShift.shiftBlocks, shift.Start__c, shift.End__c));
            }

            if(!shiftsToDelete.isEmpty()){
                List<Shift_Block__c> shiftBlocksToDelete = [SELECT Id FROM Shift_Block__c WHERE Shift__c IN :shiftsToDelete];
                if(!shiftBlocksToDelete.isEmpty()){
                    Database.delete(shiftBlocksToDelete);
                }
                Database.delete(shiftsToDelete);
            }

            if (!shiftsToInsert.isEmpty()) {
                System.debug('insert1');
                Database.insert(shiftsToInsert);

                Map<ShiftWrapper, Shift__c> shiftByWrapper = new Map<ShiftWrapper, Shift__c>();
                for (Integer i = 0; i < shiftsToInsert.size(); i++) {
                    shiftByWrapper.put(shiftList[i], shiftsToInsert[i]);
                }

                List<Shift_Block__c> shiftBlocksToInsert = new List<Shift_Block__c>();
                for (ShiftWrapper wrapper : shiftBlocksByWrapper.keySet()) {
                    Shift__c insertedShift = shiftByWrapper.get(wrapper);
                    for (Shift_Block__c shiftBlock : shiftBlocksByWrapper.get(wrapper)) {
                        shiftBlock.Shift__c = insertedShift?.Id;
                        shiftBlocksToInsert.add(shiftBlock);
                    }
                }

                if (!shiftBlocksToInsert.isEmpty()) {
                    Database.insert(shiftBlocksToInsert);
                }
            }
        }catch (Exception e) {
            System.debug(e.getLineNumber() + ' ' + e.getMessage());
            AuraHandledException ex = new AuraHandledException(e.getMessage());
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'ShiftManagerController', 'insertNewShifts');
            throw ex;
        }
    }


    private static Shift_Block__c createShiftBlock(Datetime startTime, Datetime endTime, String type) {


        Shift_Block__c shiftBlock = new Shift_Block__c();
        shiftBlock.Start__c = startTime;
        shiftBlock.End__c = endTime;

        if(type =='Break1' || type == 'Break2'){
            shiftBlock.Type__c = 'Break';
        } else {
            shiftBlock.Type__c = type;
        }

        return shiftBlock;
    }

    private static Datetime formatDateTime(String dateValue, String timeValue) {
        List<String> dateParts = dateValue.split('/');
        System.debug(dateParts);
        Date parsedDate = Date.newInstance(Integer.valueOf(dateParts[2]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[0]));

        List<String> timeParts = timeValue.split(':');
        Integer hours = Integer.valueOf(timeParts[0]);
        Integer minutes = Integer.valueOf(timeParts[1].trim());
        Time parsedTime = Time.newInstance(hours, minutes, 0, 0);

        Datetime parsedDateTime = Datetime.newInstance(parsedDate, parsedTime);
        return parsedDateTime;
    }

    private static List<Shift_Block__c> sortShiftBlocks(List<ShiftBlockWrapper> shiftBlocks, Datetime startDatetime, Datetime endDatetime) {

        shiftBlocks.sort(new ShiftBlockComparator());
        List<Shift_Block__c> sortedShiftBlocks = new List<Shift_Block__c>();

        if(shiftBlocks.size() != 0){

            if(shiftBlocks[0].timeIn != null && shiftBlocks[0].timeIn > startDatetime){
                Shift_Block__c firstShiftBlock = createShiftBlock(startDatetime, shiftBlocks[0].timeIn, 'Work');
                sortedShiftBlocks.add(firstShiftBlock);
            }

            if(shiftBlocks[shiftBlocks.size()-1].timeOut != null && shiftBlocks[shiftBlocks.size()-1].timeOut < endDatetime ){
                Shift_Block__c lastShiftBlock = createShiftBlock(shiftBlocks[shiftBlocks.size() - 1].timeOut, endDatetime, 'Work');
                sortedShiftBlocks.add(lastShiftBlock);
            }
        }



        for (Integer i = 0; i < shiftBlocks.size(); i++) {
            ShiftBlockWrapper block = shiftBlocks[i];

            Shift_Block__c shiftBlock = createShiftBlock(block.timeIn, block.timeOut, block.status);
            sortedShiftBlocks.add(shiftBlock);


            if (i < shiftBlocks.size() - 1) {
                ShiftBlockWrapper nextBlock = shiftBlocks[i + 1];
                if (block.timeOut != null && nextBlock.timeIn != null && block.timeOut < nextBlock.timeIn) {

                    Shift_Block__c intermediateWorkBlock = createShiftBlock(
                            block.timeOut,
                            nextBlock.timeIn,
                            'Work'
                    );
                    sortedShiftBlocks.add(intermediateWorkBlock);
                }
            }
        }

        return sortedShiftBlocks;
    }

    public class ShiftBlockComparator implements Comparator<ShiftBlockWrapper> {
        public Integer compare(Object o1, Object o2) {
            ShiftBlockWrapper blockA = (ShiftBlockWrapper)o1;
            ShiftBlockWrapper blockB = (ShiftBlockWrapper)o2;

            if (blockA.timeIn == null && blockB.timeIn == null) {
                return 0;
            } else if (blockA.timeIn == null) {
                return -1;
            } else if (blockB.timeIn == null) {
                return 1;
            }

            return blockA.timeIn.getTime() < blockB.timeIn.getTime() ? -1 :
                    blockA.timeIn.getTime() > blockB.timeIn.getTime() ? 1 : 0;
        }
    }
}