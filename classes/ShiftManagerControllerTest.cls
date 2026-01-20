@isTest
public class ShiftManagerControllerTest {

    @TestSetup
    static void setup() {
        Contact contact = new Contact(FirstName = 'John', LastName = 'Doe', Email = 'test1@example.com');
        insert contact;
    }

    @isTest
    static void testImportCsvData() {
        // Caso válido: CSV con varios turnos
        List<String> csvLines = new List<String>{
                'Email,Nombre y Apellido,Estado,Fecha in,Fecha out,Time In,Time Out',
                'test1@example.com,John Doe,Work,01/11/2024,01/11/2024,08:00,16:00',
                'test1@example.com,John Doe,Break1,01/11/2024,01/11/2024,10:00,10:15',
                'test1@example.com,John Doe,Break2,01/11/2024,01/11/2024,12:00,12:30',
                'test1@example.com,John Doe,Training,01/11/2024,01/11/2024,11:00,12:00'
        };

        Test.startTest();
        List<ShiftManagerController.ShiftWrapper> shifts = ShiftManagerController.importCsvData(csvLines);
        Test.stopTest();
        System.debug(shifts);
        for(ShiftManagerController.ShiftWrapper shift : shifts){
            System.debug(shift);
            for(ShiftManagerController.ShiftBlockWrapper block : shift.shiftBlocks){
                System.debug(block);
            }
        }

        // Validar resultados
        System.assertEquals(1, shifts.size(), 'Debe haber dos turnos creados');
        System.assertEquals('John Doe', shifts[0].employeeName, 'El nombre del empleado debe coincidir');
        System.assertEquals('08:00 - 16:00', shifts[0].programedWorkingHours, 'Las horas programadas deben coincidir');
        System.assertEquals(3, shifts[0].shiftBlocks.size(), 'Debe haber tres bloques para John Doe');
    }

    @isTest
    static void testInsertNewShifts() {
        // Crear datos de prueba
        List<ShiftManagerController.ShiftWrapper> shiftList = new List<ShiftManagerController.ShiftWrapper>();
        ShiftManagerController.ShiftWrapper shift = new ShiftManagerController.ShiftWrapper();

        shift.employeeName = 'John Doe';
        shift.employeeEmail = 'test1@example.com';
        shift.startHour = Datetime.newInstance(2024, 11, 1, 8, 0, 0);
        shift.endHour = Datetime.newInstance(2024, 11, 1, 16, 0, 0);
        shift.programedWorkingHours = '08:00 - 16:00';
        shift.isDayOff = false;


        // Agregar bloque de turno
        ShiftManagerController.ShiftBlockWrapper block = new ShiftManagerController.ShiftBlockWrapper();
        block.timeIn = Datetime.newInstance(2024, 11, 1, 8, 0, 0);
        block.timeOut = Datetime.newInstance(2024, 11, 1, 10, 0, 0);
        block.status = 'Work';
        ShiftManagerController.ShiftBlockWrapper block2 = new ShiftManagerController.ShiftBlockWrapper();
        block2.timeIn = Datetime.newInstance(2024, 11, 1, 10, 0, 0);
        block2.timeOut = Datetime.newInstance(2024, 11, 1, 10, 30, 0);
        block2.status = 'Break1';
        ShiftManagerController.ShiftBlockWrapper block3 = new ShiftManagerController.ShiftBlockWrapper();
        block3.timeIn = Datetime.newInstance(2024, 11, 1, 10, 30, 0);
        block3.timeOut = Datetime.newInstance(2024, 11, 1, 11, 0, 0);
        block3.status = 'Work';
        ShiftManagerController.ShiftBlockWrapper block4 = new ShiftManagerController.ShiftBlockWrapper();
        block4.timeIn = Datetime.newInstance(2024, 11, 1, 12, 0, 0);
        block4.timeOut = Datetime.newInstance(2024, 11, 1, 12, 40, 0);
        block4.status = 'Break2';
        ShiftManagerController.ShiftBlockWrapper block5 = new ShiftManagerController.ShiftBlockWrapper();
        block5.timeIn = Datetime.newInstance(2024, 11, 1, 12, 40, 0);
        block5.timeOut = Datetime.newInstance(2024, 11, 1, 16, 0, 0);
        block5.status = 'Work';
        ShiftManagerController.ShiftBlockWrapper block6 = new ShiftManagerController.ShiftBlockWrapper();
        block6.timeIn = Datetime.newInstance(2024, 11, 1, 11, 0, 0);
        block6.timeOut = Datetime.newInstance(2024, 11, 1, 12, 0, 0);
        block6.status = 'Training';


        shift.shiftBlocks = new List<ShiftManagerController.ShiftBlockWrapper>{block, block2, block3, block4, block5, block6};


        shiftList.add(shift);

        Test.startTest();
        ShiftManagerController.insertNewShifts(shiftList);
        Test.stopTest();

        // Validar inserción de turnos y bloques
        List<Shift__c> insertedShifts = [SELECT Id, Start__c, End__c, Agent__r.Email FROM Shift__c WHERE Agent__r.Email = 'test1@example.com'];
        System.assertEquals(1, insertedShifts.size(), 'Debe haberse insertado un turno');
        System.assertEquals(Datetime.newInstance(2024, 11, 1, 8, 0, 0), insertedShifts[0].Start__c, 'La hora de inicio debe coincidir');

        List<Shift_Block__c> insertedShiftBlocks = [SELECT Id, Start__c, End__c FROM Shift_Block__c WHERE Shift__c = :insertedShifts[0].Id];
        System.assertEquals(6, insertedShiftBlocks.size(), 'Debe haberse insertado un bloque de turno');
    }

    @isTest
    static void testExceptionHandling() {
        // Caso de excepción: CSV vacío
        List<String> csvLines = new List<String>{
                'Email,Nombre y Apellido,Estado,Fecha in,Fecha out,Time In,Time Out'
        };

        Test.startTest();
        try {
            ShiftManagerController.importCsvData(csvLines);
            System.assert(false, 'Se esperaba una excepción');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage(), 'El mensaje de error debe coincidir');
        }
        Test.stopTest();
    }
}