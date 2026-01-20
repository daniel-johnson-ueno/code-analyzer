@IsTest
private class ShiftDayOffHandlerTest {
    @TestSetup
    static void setup() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contact contact1 = new Contact(
                FirstName = 'John',
                LastName = 'Doe',
                Email = 'johndoe@test.com',
                AccountId = testAccount.Id,
                Channel__c = 'Telefono',
                UserId__c = UserInfo.getUserId()
        );

        Contact contact2 = new Contact(
                FirstName = 'Jane',
                LastName = 'Smith',
                Email = 'janesmith@test.com',
                AccountId = testAccount.Id,
                Channel__c = 'Telefono'
        );

        insert new List<Contact>{ contact1, contact2 };

        Shift__c shift1 = new Shift__c(
                Start__c = DateTime.newInstance(2024, 12, 6, 10, 0, 0),
                End__c = DateTime.newInstance(2024, 12, 6, 18, 0, 0),
                Agent__c = contact1.Id
        );

        Shift__c shift2 = new Shift__c(
                Start__c = DateTime.newInstance(2024, 12, 8, 10, 0, 0),
                End__c = DateTime.newInstance(2024, 12, 8, 18, 0, 0),
                Agent__c = contact2.Id
        );

        insert new List<Shift__c>{ shift1, shift2 };
        Shift_Block__c objShiftBlock = new Shift_Block__c(
                Shift__c = shift1.Id,
                Start__c =DateTime.newInstance(2024, 12, 6, 10, 0, 0),
                End__c = DateTime.newInstance(2024, 12, 6, 18, 0, 0)
        );

        insert new List<Shift_Block__c>{ objShiftBlock };
    }

    @IsTest
    static void sendDayOffForApprovalTest() {
        Date searchDate = Date.newInstance(2024, 12, 6);
        List<Shift__c> lstShifts = [SELECT Id, ToApprove__c, ToDelete__c, Day_Off_Type__c FROM Shift__c WHERE Date__c =: String.valueOf(searchDate)];
        List<ShiftDayOffHandler.ShiftRequest> lstRequests = new List<ShiftDayOffHandler.ShiftRequest>();

        for(Shift__c shift : lstShifts){
            shift.ToApprove__c = true;
            shift.Day_Off_Type__c = 'Day Off';
        }
        Database.update(lstShifts);

        ShiftDayOffHandler.ShiftRequest request = new ShiftDayOffHandler.ShiftRequest();
        request.shiftId = lstShifts[0].Id;
        lstRequests.add(request);
        Test.startTest();
        ShiftDayOffHandler.handleDayOff(lstRequests);
        Test.stopTest();
        List<Shift_Block__c> lstShiftBlocks = [SELECT Id, Type__c FROM Shift_Block__c WHERE Shift__c =: lstShifts[0].Id AND Type__c = 'Day Off'];
        System.Assert(lstShiftBlocks.size()>0);
    }
}