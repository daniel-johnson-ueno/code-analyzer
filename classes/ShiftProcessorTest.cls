@IsTest
private class ShiftProcessorTest {

    @IsTest
    static void testImportCsvData() {
        // Arrange
        List<String> csvLines = new List<String>{
            'Email,Nombre y Apellido,Estado,Fecha In,Fecha Out,Time In,Time Out',
            'john.doe@example.com,John Doe,Work,29/01/2025,30/01/2025,18:00,6:00',
            'john.doe@example.com,John Doe,Break1,29/01/2025,29/01/2025,22:30,23:00',
            'john.doe@example.com,John Doe,Break2,30/01/2025,30/01/2025,2:00,2:30',
            'john.doe@example.com,John Doe,Work,30/01/2025,31/01/2025,18:00,6:00',
            'john.doe@example.com,John Doe,Break1,30/01/2025,30/01/2025,22:30,23:00',
            'john.doe@example.com,John Doe,Break2,31/01/2025,31/01/2025,2:00,2:30'
        };

        // Act
        List<ShiftProcessor.Shift> shifts = ShiftProcessor.importCsvData(csvLines);

        // Assert
        System.assertEquals(2, shifts.size(), 'There should be one Shift');
        ShiftProcessor.Shift shift = shifts[0];
        System.assertEquals('john.doe@example.com', shift.employeeEmail, 'Email should match');
        System.assertEquals('John Doe', shift.employeeName, 'Name should match');
        System.assertEquals(2, shift.shiftBlocks.size(), 'There should be two shift blocks');

        // Verify the shift blocks have the correct status and times
        System.assertEquals('Break1', shift.shiftBlocks[0].status, 'block should be Break1');
        System.assertEquals('Break2', shift.shiftBlocks[1].status, 'block should be Break2');
    }

    @IsTest
    static void testInsertNewShifts() {
        // Arrange
        List<String> csvLines = new List<String>{
            'Email,Nombre y Apellido,Estado,Fecha In,Fecha Out,Time In,Time Out',
            'john.doe@example.com,John Doe,Work,29/01/2025,30/01/2025,18:00,6:00',
            'john.doe@example.com,John Doe,Break1,29/01/2025,29/01/2025,22:30,23:00',
            'john.doe@example.com,John Doe,Break2,30/01/2025,30/01/2025,2:00,2:30'
        };
        List<ShiftProcessor.Shift> lstShiftsToInsert = ShiftProcessor.importCsvData(csvLines);
        
        DateTime startHour = DateTime.newInstance(2025, 1, 29, 21, 0, 0);
        Datetime endHour = DateTime.newInstance(2025, 1, 30, 6, 0, 0);

        // Act
        Test.startTest();
        ShiftProcessor.insertNewShifts(lstShiftsToInsert);
        Test.stopTest();

        // Assert
        List<Shift__c> shifts = [SELECT Id, Start__c, End__c FROM Shift__c];
        System.assertEquals(1, shifts.size(), 'There should be one Shift__c record');
        
        Shift__c createdShift = shifts[0];

        List<Shift_Block__c> blocks = [SELECT Id, Type__c, Start__c, End__c FROM Shift_Block__c WHERE Shift__c = :createdShift.Id];
        System.assertEquals(5, blocks.size(), 'There should be five Shift_Block__c records');
    }

    @IsTest
    static void testImportCsvDataWithDayOff() {
        // Arrange
        List<String> csvLines = new List<String>{
            'Email,Nombre y Apellido,Estado,Fecha In,Fecha Out,Time In,Time Out',
            'john.doe@example.com,John Doe,Day Off,29/01/2025,30/01/2025,18:00,6:00'
        };

        // Act
        List<ShiftProcessor.Shift> lstShiftsToInsert = ShiftProcessor.importCsvData(csvLines);
        Test.startTest();
        ShiftProcessor.insertNewShifts(lstShiftsToInsert);
        Test.stopTest();

        // Assert
        List<Shift__c> shifts = [SELECT Id, Is_Day_Off__c FROM Shift__c];
        System.assertEquals(1, shifts.size(), 'There should be one Shift__c record');
        System.assertEquals(true, shifts[0].Is_Day_Off__c, 'There should be a Day Off Shift__c record');
        
        Shift__c createdShift = shifts[0];

        List<Shift_Block__c> blocks = [SELECT Id FROM Shift_Block__c WHERE Shift__c = :createdShift.Id];
        System.assertEquals(1, blocks.size(), 'There should be one Shift_Block__c record');
    }
}