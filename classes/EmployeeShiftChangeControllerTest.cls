@IsTest
private class EmployeeShiftChangeControllerTest {

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
                Start__c = Datetime.now(),
                End__c = Datetime.now().addHours(8),
                Agent__c = contact1.Id
        );

        Shift__c shift2 = new Shift__c(
                Start__c = Datetime.now().addDays(2),
                End__c = Datetime.now().addDays(2).addHours(8),
                Agent__c = contact2.Id
        );
        Shift__c shift3 = new Shift__c(
            Start__c = Datetime.now().addDays(2),
            End__c = Datetime.now().addDays(2).addHours(8),
            Agent__c = contact2.Id,
            Is_Day_Off__c = true
        );

        insert new List<Shift__c>{ shift1, shift2 };

        Shift_Block__c sBlock = new Shift_Block__c(
            Shift__c = shift1.Id,
            Start__c = Datetime.now(),
            End__c = Datetime.now().addHours(1),
            Type__c='Break'
        );

        Shift_Block__c sBlock2 = new Shift_Block__c(
            Shift__c = shift1.Id,
            Start__c = Datetime.now(),
            End__c = Datetime.now().addHours(1),
            Type__c='Training'
        );
        
        insert new List<Shift_Block__c>{ sBlock, sBlock2 };
    }

    @IsTest
    static void getMonthDatesTest() {
        Map<String, Date> result = EmployeeShiftChangeController.getMonthDates();
        System.assertNotEquals(null, result);
        System.assert(result.containsKey('start'));
        System.assert(result.containsKey('end'));
    }

    @IsTest
    static void userContactInfoTest() {
        List<Contact> contacts = EmployeeShiftChangeController.userContactInfo(UserInfo.getUserId());
        System.assertEquals(1, contacts.size());
        System.assertEquals('John Doe', contacts[0].Name);
    }

    @IsTest
    static void getCurrentContactShiftsTest() {
        List<Contact> contacts = EmployeeShiftChangeController.userContactInfo(UserInfo.getUserId());
        List<EmployeeShiftChangeController.ShiftWrapper> shifts =
                EmployeeShiftChangeController.getCurrentContactShifts(contacts[0].UserId__c);

        System.assertEquals(1, shifts.size());
        System.assertEquals('John Doe', shifts[0].employeeName);
    }

    @IsTest
    static void getContactByLocalAndChannelTest() {
        List<Contact> contacts = [SELECT Id, AccountId, Channel__c, UserId__c FROM Contact LIMIT 1];
        List<Contact> relatedContacts = EmployeeShiftChangeController.getContactByLocalAndChannel(contacts[0]);
        System.assertEquals(1, relatedContacts.size());
    }

    @IsTest
    static void getShiftsToChangeTest() {
        List<Contact> contacts = [SELECT Id, AccountId, Channel__c, UserId__c FROM Contact LIMIT 1];
        List<EmployeeShiftChangeController.ShiftWrapper> shifts =
                EmployeeShiftChangeController.getShiftsToChange(
                        contacts[0].Id,
                        String.valueOf(Date.today().year() + '-01-01'),
                        String.valueOf(Date.today().year() + '-12-31')
                );
        System.assert(shifts.size() > 0);
    }

    @IsTest
    static void sendReplacmentForApprovalTest() {
        List<Shift__c> shifts = [SELECT Id FROM Shift__c LIMIT 1];
        List<Contact> contacts = [SELECT Id, AccountId, Channel__c, UserId__c FROM Contact LIMIT 1];

        List<EmployeeShiftChangeController.ShiftWrapper> lstShifts = new List<EmployeeShiftChangeController.ShiftWrapper>();
        EmployeeShiftChangeController.ShiftWrapper shiftWrapper = new EmployeeShiftChangeController.ShiftWrapper();
        shiftWrapper.shiftId = shifts[0].Id;
        lstShifts.add(shiftWrapper);

        Test.startTest();
        EmployeeShiftChangeController.sendReplacementForApproval(
            lstShifts,
            String.valueOf(contacts[0].Id),
            String.valueOf(UserInfo.getUserId())
        );
        Test.stopTest();

        Shift__c updatedShift = [SELECT Agent_Suggested_Replacement__c FROM Shift__c WHERE Id = :shifts[0].Id];
        System.assertEquals(contacts[0].Id, updatedShift.Agent_Suggested_Replacement__c);
    }

    @IsTest
    static void sendDayOffForApprovalTest() {
        List<Contact> contacts = [SELECT Id, UserId__c FROM Contact WHERE UserId__c =:UserInfo.getUserId() LIMIT 1];
        Date dtStart = Date.today();
        Date dtEnd   = Date.today().addDays(4);
        Test.startTest();
        EmployeeShiftChangeController.sendDayOffForApproval(
            String.valueOf(UserInfo.getUserId()),
            String.valueOf(contacts[0].Id),
            String.valueOf(dtStart),
            String.valueOf(dtEnd),
            'Vacaciones'
        );
        Test.stopTest();

        List<Shift__c> lstShiftsToApprove = [SELECT Id, ToApprove__c FROM Shift__c WHERE ToApprove__c = TRUE];
//        System.debug(lstShiftsToApprove);
//        System.Assert(lstShiftsToApprove.size()>0);
    }

    @IsTest
    static void testGetDayOffTypes() {
        List<EmployeeShiftChangeController.PicklistWrapper> result = EmployeeShiftChangeController.getDayOffTypes();
        Assert.areNotEqual(0,result.size());
    }
}