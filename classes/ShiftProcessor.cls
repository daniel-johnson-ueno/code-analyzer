public class ShiftProcessor {
    public class Shift {
        @AuraEnabled public String employeeName { get; set; }
        @AuraEnabled public String employeeEmail { get; set; }
        @AuraEnabled public DateTime startHour { get; set; }
        @AuraEnabled public DateTime endHour { get; set; }
        @AuraEnabled public String programedWorkingHours { get; set; }
        @AuraEnabled public String firstBreakProgramedTime { get; set; }
        @AuraEnabled public String secondBreakProgramedTime { get; set; }
        @AuraEnabled public String trainingProgramedTime { get; set; }
        @AuraEnabled public String otherProgramedTime { get; set; }
        @AuraEnabled public String programedDateIn { get; set; }
        @AuraEnabled public String programedDateOut { get; set; }
        @AuraEnabled public Boolean isDayOff { get; set; }

        @AuraEnabled public List<ShiftBlock> shiftBlocks { get; set; }
    }

    public class ShiftBlock implements Comparable {
        @AuraEnabled public Datetime timeIn { get; set; }
        @AuraEnabled public Datetime timeOut { get; set; }
        @AuraEnabled public String status { get; set; }

        // Implementing Comparable to allow sorting by timeIn
        public Integer compareTo(Object compareTo) {
            ShiftBlock other = (ShiftBlock) compareTo;
            if (timeIn == other.timeIn) {
                return 0;
            } else if (timeIn > other.timeIn) {
                return 1;
            } else {
                return -1;
            }
        }
    }

    @AuraEnabled
    public static List<Shift> importCsvData(List<String> csvLines) {
        try{
            List<Map<String, String>> parsedCSVData = parseCSVLines(csvLines);
            List<Shift> shiftList = new List<Shift>();

            // Parse CSV data and organize into shiftList
            for (Map<String, String> row : parsedCSVData) {
                String email = row.get('Email').trim();
                String name = row.get('Nombre y Apellido').trim();
                String statusParsed = row.get('Estado').trim();
                String dateIn = row.get('Fecha In').trim();
                String dateOut = row.get('Fecha Out').trim();
                String timeIn = row.get('Time In').trim();
                String timeOut = row.get('Time Out').trim();

                if (
                    String.isBlank(email) || String.isEmpty(email) ||
                    String.isBlank(name) || String.isEmpty(name) ||
                    String.isBlank(statusParsed) || String.isEmpty(statusParsed) ||    
                    String.isBlank(dateIn) || String.isEmpty(dateIn) ||
                    String.isBlank(dateOut) || String.isEmpty(dateOut) ||
                    String.isBlank(timeIn) || String.isEmpty(timeIn) ||
                    String.isBlank(timeOut) || String.isEmpty(timeOut)
                ) {
                    continue;
                }

                String employeeEmail = email;
                String status = statusParsed;
                DateTime formatedStartDate = formatDateTime(dateIn, timeIn);
                DateTime formatedEndDate = formatDateTime(dateOut, timeOut);

                if (status == 'Day Off' || status == 'Half-yearly day off' || status == 'Unpaid day off' || status == 'Paid day off' || status == 'Birthday') {
                    System.debug('Day Off');
                    // Crear solo un bloque para "Day Off"
                    ShiftBlock shiftBlock = new ShiftBlock();
                    shiftBlock.status = status;
                    shiftBlock.timeIn = formatedStartDate;
                    shiftBlock.timeOut = formatedEndDate;

                    // Actualizar detalles del turno principal
                    Shift shift = new Shift();
                    shift.isDayOff = true;
                    shift.shiftBlocks = new List<ShiftBlock>{shiftBlock};
                    shift.employeeEmail = employeeEmail;
                    shift.employeeName = name;
                    shift.startHour = formatedStartDate;
                    shift.endHour = formatedEndDate;
                    shift.programedWorkingHours = timeIn + ' - ' + timeOut;
                    shift.programedDateIn = dateIn;
                    shift.programedDateOut = dateOut;
                    shift.otherProgramedTime = status;
                    shiftList.add(shift);
                    
                    // Salir del procesamiento de este turno
                    continue;
                }
                if (status == 'Work') {
                    System.debug('Work');
                    // Create a new shift for each "Work" status row
                    Shift shift = new Shift();
                    shift.isDayOff = false;
                    shift.employeeEmail = employeeEmail;
                    shift.employeeName = name;
                    shift.startHour = formatedStartDate;
                    shift.endHour = formatedEndDate;
                    shift.programedDateIn = dateIn;
                    shift.programedDateOut = dateOut;
                    shift.programedWorkingHours = timeIn + ' - ' + timeOut;
                    shift.shiftBlocks = new List<ShiftBlock>();
                    shiftList.add(shift);
                } else {
                    // Find the corresponding shift and add the block
                    for (Shift shift : shiftList) {
                        // Ensure the break is within the shift duration
                        if (
                            (shift.employeeEmail == employeeEmail && formatedStartDate >= shift.startHour && formatedEndDate <= shift.endHour) &&
                            (shift.isDayOff==false)
                        ) {
                            ShiftBlock block = new ShiftBlock();
                            block.status = status;
                            block.timeIn = formatedStartDate;
                            block.timeOut = formatedEndDate;
                            if (status == 'Break1' && shift.firstBreakProgramedTime == null) {
                                shift.firstBreakProgramedTime = timeIn + ' - ' + timeOut;
                            } 
                            else if (status == 'Break2' && shift.secondBreakProgramedTime == null) {
                                shift.secondBreakProgramedTime = timeIn + ' - ' + timeOut;
                            } 
                            else if (status == 'Training' && shift.trainingProgramedTime == null) {
                                shift.trainingProgramedTime = timeIn + ' - ' + timeOut;
                            }
                            shift.shiftBlocks.add(block);
                            break; // Once the block is added, break out of the loop
                        }
                        else if (shift.isDayOff==true && (status == 'Day Off' || status == 'Half-yearly day off' || status == 'Unpaid day off' || status == 'Paid day off' || status == 'Birthday') ){
                            ShiftBlock block = new ShiftBlock();
                            block.status = status;
                            block.timeIn = formatedStartDate;
                            block.timeOut = formatedEndDate;
                            shift.shiftBlocks.add(block);
                        }
                    }
                }
            }

            return shiftList;

        } catch(Exception e){
            System.debug(e);
            AuraHandledException ex = new AuraHandledException(e.getMessage());
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'ShiftProcessor', 'importCsvData');
            throw ex;
        }
    }

    @AuraEnabled
    public static void insertNewShifts(List<Shift> shiftList) {
        try{
            shiftList = sortBlocksAddWork(shiftList);
            List<Shift__c> shiftsToInsert = new List<Shift__c>();
            List<Shift_Block__c> blocksToInsert = new List<Shift_Block__c>();
            Map<Id, Shift> shiftIdToShiftMap = new Map<Id, Shift>();
            List<Shift__c> shiftsToDelete = new List<Shift__c>();
            
            Set<String> employeeEmails = new Set<String>();
            for (Shift shift : shiftList) {
                employeeEmails.add(shift.employeeEmail);
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

            List<Contact> employees = [SELECT Id, Email, AccountId, UserId__c FROM Contact WHERE Email IN :employeeEmails];
            Map<String, Contact> employeeByEmail = new Map<String, Contact>();
            for (Contact employee : employees) {
                employeeByEmail.put(employee.Email, employee);
            }

            // Shift__c to insert
            for (Shift shiftData : shiftList) {
                if (shiftData.startHour != null && shiftData.endHour != null) {
                    Shift__c newShift = new Shift__c();
                    newShift.Start__c = shiftData.startHour;
                    newShift.End__c = shiftData.endHour;
                    newShift.Is_Day_Off__c = shiftData.isDayOff;
                    newShift.Agent__c = employeeByEmail.get(shiftData.employeeEmail)?.Id;
                    newShift.Executive__c = employeeByEmail.get(shiftData.employeeEmail)?.UserId__c;
                    newShift.Local__c = employeeByEmail.get(shiftData.employeeEmail)?.AccountId;
                    shiftsToInsert.add(newShift);
                    // Shifts to Delete
                    String startDate = String.valueOf(newShift.Start__c.year()) + '-' + String.valueOf(newShift.Start__c.month()) + '-' + String.valueOf(newShift.Start__c.day());
                    String endDate = String.valueOf(newShift.End__c.year()) + '-' + String.valueOf(newShift.End__c.month()) + '-' + String.valueOf(newShift.End__c.day());
                    if(shiftsByDate.size() > 0){
                        if(shiftsByDate.containsKey(startDate + '' + endDate + '' + newShift.Agent__c)){
                            shiftsToDelete.addAll(shiftsByDate.get(startDate + '' + endDate + '' + newShift.Agent__c));
                        }
                    }
                }
            }
            if(!shiftsToDelete.isEmpty()){
                List<Shift_Block__c> shiftBlocksToDelete = [SELECT Id FROM Shift_Block__c WHERE Shift__c IN :shiftsToDelete];
                if(!shiftBlocksToDelete.isEmpty()){
                    Database.delete(shiftBlocksToDelete);
                }
                Database.delete(shiftsToDelete);
            }
            if (!shiftsToInsert.isEmpty()) {
                Database.insert(shiftsToInsert);
                for (Integer i = 0; i < shiftsToInsert.size(); i++) {
                    shiftIdToShiftMap.put(shiftsToInsert[i].Id, shiftList[i]);
                }
                for (Shift__c insertedShift : shiftsToInsert) {
                    Shift shiftData = shiftIdToShiftMap.get(insertedShift.Id);
                    for (ShiftBlock blockData : shiftData.shiftBlocks) {
                        Shift_Block__c newBlock = new Shift_Block__c();
                        newBlock.Type__c = blockData.status.equals('Break1') || blockData.status.equals('Break2') ? 'Break' : blockData.status;
                        newBlock.Start__c = blockData.timeIn;
                        newBlock.End__c = blockData.timeOut;
                        newBlock.Shift__c = insertedShift.Id;
                        blocksToInsert.add(newBlock);
                    }
                }
                if (!blocksToInsert.isEmpty()) {
                    Database.insert(blocksToInsert);
                }
            }
        } catch (Exception e) {
            System.debug(e.getLineNumber() + ' ' + e.getMessage());
            AuraHandledException ex = new AuraHandledException(e.getMessage());
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'ShiftProcessor', 'insertNewShifts');
            throw ex;
        }
    }

    private static List<Map<String, String>> parseCSVLines(List<String> csvLines) {
        List<Map<String, String>> parsedCSVData = new List<Map<String, String>>();
        if (csvLines.isEmpty()) return parsedCSVData;

        // The first line contains headers
        List<String> headers = csvLines[0].split(',');
        // Iterate over each subsequent line
        for (Integer i = 1; i < csvLines.size(); i++) {
            String line = csvLines[i].trim();
            List<String> values = line.split(',');

            if (values.size() == headers.size()) {
                Map<String, String> rowMap = new Map<String, String>();

                // Create a map for each line
                for (Integer j = 0; j < headers.size(); j++) {
                    rowMap.put(headers[j].trim().remove('"'), values[j].trim().remove('"'));
                }

                parsedCSVData.add(rowMap);
            } else {
                System.debug('Mismatch between headers and values count on line ' + (i + 1));
            }
        }
        return parsedCSVData;
    }

    private static Datetime formatDateTime(String dateStr, String timeStr) {
        Date newDate = Date.parse(dateStr);
        String[] timeParts = timeStr.split(':');
        Integer hour = Integer.valueOf(timeParts[0]);
        Integer minute = Integer.valueOf(timeParts[1]);
        return DateTime.newInstance(newDate, Time.newInstance(hour, minute, 0, 0));
    }

    private static Shift_Block__c createShiftBlock(DateTime start, DateTime dtEnd, String status) {
        Shift_Block__c block = new Shift_Block__c();
        block.Start__c = start;
        block.End__c = dtEnd;
        block.Type__c = status;
        return block;
    }

    private static List<Shift> sortBlocksAddWork(List<Shift> shiftList){
        // Process each shift to sort blocks and add work segments
        for (Shift shift : shiftList) {
            if (shift.isDayOff==false) {
                // Get sorted shift blocks with work segments
                List<Shift_Block__c> sortedShiftBlocks = sortShiftBlocks(shift.shiftBlocks, shift.startHour, shift.endHour);
                // Replace the shift blocks with sorted and processed ones
                shift.shiftBlocks.clear();
                for (Shift_Block__c block : sortedShiftBlocks) {
                    ShiftBlock newBlock = new ShiftBlock();
                    newBlock.status = block.Type__c;
                    newBlock.timeIn = block.Start__c;
                    newBlock.timeOut = block.End__c;
                    shift.shiftBlocks.add(newBlock);
                }
            }
        }
        return shiftList;
    }

    private static List<Shift_Block__c> sortShiftBlocks(List<ShiftBlock> shiftBlocks, DateTime startDatetime, DateTime endDatetime) {
        shiftBlocks.sort(); // Use the Comparable interface to sort by timeIn

        List<Shift_Block__c> sortedShiftBlocks = new List<Shift_Block__c>();
        if (shiftBlocks.size() != 0) {
            if (shiftBlocks[0].timeIn != null && shiftBlocks[0].timeIn > startDatetime) {
                Shift_Block__c firstShiftBlock = createShiftBlock(startDatetime, shiftBlocks[0].timeIn, 'Work');
                sortedShiftBlocks.add(firstShiftBlock);
            }

            if (shiftBlocks[shiftBlocks.size() - 1].timeOut != null && shiftBlocks[shiftBlocks.size() - 1].timeOut < endDatetime) {
                Shift_Block__c lastShiftBlock = createShiftBlock(shiftBlocks[shiftBlocks.size() - 1].timeOut, endDatetime, 'Work');
                sortedShiftBlocks.add(lastShiftBlock);
            }
        }

        for (Integer i = 0; i < shiftBlocks.size(); i++) {
            ShiftBlock block = shiftBlocks[i];
            Shift_Block__c shiftBlock = createShiftBlock(block.timeIn, block.timeOut, block.status);
            sortedShiftBlocks.add(shiftBlock);
            if (i < shiftBlocks.size() - 1) {
                ShiftBlock nextBlock = shiftBlocks[i + 1];
                if (block.timeOut != null && nextBlock.timeIn != null && block.timeOut < nextBlock.timeIn) {
                    Shift_Block__c intermediateWorkBlock = createShiftBlock(block.timeOut, nextBlock.timeIn, 'Work');
                    sortedShiftBlocks.add(intermediateWorkBlock);
                }
            }
        }

        return sortedShiftBlocks;
    }
}