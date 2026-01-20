/*
@author Veronica Zarza
@date 22/10/2024
@description Clase Test CalculateHoursByState
*/
@isTest
public class CalculateHoursByStateTest{
    @isTest
    static void testCalculateHoursByState(){
        Id bhId = [SELECT Id FROM BusinessHours WHERE Name = 'Horario Ueno' LIMIT 1].Id;

        Datetime startDateTime = Datetime.newInstanceGmt(2024,08,30,16,0,0);
        Datetime endDateTime = Datetime.newInstanceGmt(2024,08,30,17,30,0);
        
        CalculateHoursByState.FlowInputs inputs = new CalculateHoursByState.FlowInputs();
        inputs.businessHoursId = bhId;
        inputs.startDate = startDateTime;
        inputs.endDate = endDateTime;
		Test.startTest();
        List<Double> result = CalculateHoursByState.calculateHoursInSecondsByState(new List<CalculateHoursByState.FlowInputs>{inputs});
		Test.stopTest();
        Assert.areEqual(5400,result[0],'Debe devolver 5400 segundos');
    }

    @isTest
    static void testCalculateHoursByStateOnlyMins(){
        Id bhId = [SELECT Id FROM BusinessHours WHERE Name = 'Horario Ueno' LIMIT 1].Id;
        Datetime startDateTime = Datetime.newInstanceGmt(2024,08,30,16,0,0);
        Datetime endDateTime = Datetime.newInstanceGmt(2024,08,30,16,30,0);
        CalculateHoursByState.FlowInputs inputs = new CalculateHoursByState.FlowInputs();
        inputs.businessHoursId = bhId;
        inputs.startDate = startDateTime;
        inputs.endDate = endDateTime;
		Test.startTest();
        List<Double> result = CalculateHoursByState.calculateHoursInSecondsByState(new List<CalculateHoursByState.FlowInputs>{inputs});
		Test.stopTest();
        Assert.areEqual(1800,result[0],'Debe devolver 1800 segundos');
    }

    @isTest
    static void testCalculateSecondsDifferenceInStage(){
        String caseDateTimeLastStatusChange = '2025-03-19T15:01:25.000Z';
        Datetime caseDateTimeLastStatusChangeDateTime = Datetime.valueOfGmt(caseDateTimeLastStatusChange.replace('T', ' ').replace('Z', ''));
        Datetime fakeDatetimeNow = caseDateTimeLastStatusChangeDateTime.addSeconds(10800);
        Test.startTest();
        Double result = CalculateHoursByState.calculateSecondsDifferenceInStage(caseDateTimeLastStatusChange, fakeDatetimeNow);
        Test.stopTest();
        Assert.areEqual(10800, result, 'Debe devolver 10800 segundos');
    } 

    @isTest
    static void testCalculateSecondsDifferenceInStageWhenTimeLastStatusIsNull(){
        String caseDateTimeLastStatusChange = null;
        Test.startTest();
        Double result = CalculateHoursByState.calculateSecondsDifferenceInStage(caseDateTimeLastStatusChange);
        Test.stopTest();
        Assert.areEqual(0, result, 'Debe devolver 0 segundos');
    } 

    @isTest
    static void testItIsWorkingHoursOutOfWorkingHours(){
        String fakeDateTimeNowString = '2025-03-19T00:00:00.000Z';
        Datetime fakeDateTimeNow = Datetime.valueOfGmt(fakeDateTimeNowString.replace('T', ' ').replace('Z', ''));
        Test.startTest();
        Boolean result = CalculateHoursByState.checkItIsWorkingHours(fakeDateTimeNow);
        Test.stopTest();
        Assert.areEqual(false, result, 'Debe devolver false porque la hora es fuera de horario');
    } 

    @isTest
    static void testItIsWorkingHoursWithinWorkingHours(){
        String fakeDateTimeNowString = '2025-03-19T12:00:00.000Z';
        Datetime fakeDateTimeNow = Datetime.valueOfGmt(fakeDateTimeNowString.replace('T', ' ').replace('Z', ''));
        Test.startTest();
        Boolean result = CalculateHoursByState.checkItIsWorkingHours(fakeDateTimeNow);
        Test.stopTest();
        Assert.areEqual(true, result, 'Debe devolver true porque la hora es dentro de horario');
    } 
}