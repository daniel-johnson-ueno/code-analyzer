global with sharing class ShiftDayOffHandler {

    @InvocableMethod(label='Handler Day Off' description='Perform action on Day off shifts')
    global static List<ShiftResult> handleDayOff(List<ShiftRequest> requests) {
        List<ShiftResult> results = new List<ShiftResult>();

        try{

            Set<Id> setIdsToQuery = new Set<Id>();
            for (ShiftRequest request : requests) {
                setIdsToQuery.add(request.shiftId);
            }

            List<Shift__c> lstShifts = [
                SELECT Id, Start__c, End__c, Agent__c, Day_Off_Type__c, ToApprove__c
                FROM Shift__c
                WHERE Id IN : setIdsToQuery
            ];

            Map<String, Shift__c> shiftsByDates = new Map<String, Shift__c>();
            List<Shift__c> allShiftsToDelete = [
                SELECT Id, Start__c, End__c, Agent__c, ToDelete__c
                FROM Shift__c
                WHERE ToDelete__c = TRUE
            ];

            for(Shift__c shift : allShiftsToDelete){
                shiftsByDates.put(shift.Start__c.date() + '' + shift.End__c.date() + '' + shift.Agent__c, shift);
            }



            Set<String> shiftsToDelete = new Set<String>();
            List<Shift_Block__c> lstShiftBlocksToInsert = new List<Shift_Block__c>();

            for (Shift__c shift : lstShifts) {

                    // handel dates
                    Datetime dateTimeStart = DateTime.newInstance(shift.Start__c.year(), shift.Start__c.month(), shift.Start__c.day(), 0, 0, 0);
                    DateTime dateTimeEnd   = DateTime.newInstance(shift.End__c.year(), shift.End__c.month(), shift.End__c.day(), 23, 59, 59);
                    // update shift
                    shift.Start__c = dateTimeStart;
                    shift.End__c = dateTimeEnd;
                    shift.ToApprove__c = false;

                    if(shiftsByDates.containsKey(shift.Start__c.date() + '' + shift.End__c.date() + '' + shift.Agent__c)){
                        shiftsToDelete.add(shiftsByDates.get(shift.Start__c.date() + '' + shift.End__c.date() + '' + shift.Agent__c).Id);
                    }

                    // create shift block
                    Shift_Block__c objShiftBlock = new Shift_Block__c(
                            Shift__c = shift.Id,
                            Type__c = shift.Day_Off_Type__c,
                            Start__c = dateTimeStart,
                            End__c = dateTimeEnd
                    );
                    lstShiftBlocksToInsert.add(objShiftBlock);
            }

            System.debug(shiftsToDelete.size());

            if (shiftsToDelete.size()>0) {

                List<Shift_Block__c> lstShiftBlocksToDelete = [
                    SELECT Id, Shift__c
                    FROM Shift_Block__c
                    WHERE Shift__c IN :shiftsToDelete
                ];

                if(lstShiftBlocksToDelete.size()>0){
                    Database.delete(lstShiftBlocksToDelete);
                }

                List<String> lstShiftIds = new List<String>();
                lstShiftIds.addAll(shiftsToDelete);
                Database.delete(lstShiftIds) ;
            }

            if (lstShiftBlocksToInsert.size()>0) {
                Database.insert(lstShiftBlocksToInsert);
            }

            if (lstShifts.size()>0) {
                Database.update(lstShifts);
            }

            ShiftResult result = new ShiftResult();
            result.success = true;
            result.message = 'success';
            results.add(result);

        } catch(Exception e) {
            System.debug(e);
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'ShiftDayOffHandler', 'handleDayOff');
            return null;
        }
        return results;

    }

    global class ShiftRequest {
        @InvocableVariable(required=true label='Turno ID' description='Shift__c ID')
        global String shiftId;
    }
    
    global class ShiftResult {
        @InvocableVariable(label='Success' description='Resultado verdadero o falso')
        global Boolean success;
        
        @InvocableVariable(label='Message' description='resultado de la operacion')
        global String message;
        
        public ShiftResult(){}
    }
}