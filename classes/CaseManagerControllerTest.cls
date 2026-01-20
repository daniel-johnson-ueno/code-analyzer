@isTest
public class CaseManagerControllerTest {

    @TestSetup
    static void setup(){
        Account person = TestFactory.createPersonAccount();
    }

    @isTest
    static void getExistingQueuesTest() {
        List<Group> result = CaseManagerController.getExistingQueues();
        System.assert(result.size() > 0);
    }


    @IsTest
    static void getTipificadoresTest() {

        String product = 'Transferencias';
        Test.startTest();
        List<CaseManagerController.ResultWrapper> result = CaseManagerController.getTipificadores(product);
        Test.stopTest();

        System.assert(result.size() > 0);
    }

    @IsTest
    static void getPersonAccountContactTest() {
        Account person = [SELECT Id, PersonContactId FROM Account];

        // Act
        Test.startTest();
        Contact result = CaseManagerController.getPersonAccountContact(person.Id);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, result);
        System.assertEquals(person.PersonContactId, result.Id);
    }


}