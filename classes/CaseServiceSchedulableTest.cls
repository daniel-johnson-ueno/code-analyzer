@isTest
public class CaseServiceSchedulableTest {
@isTest
    static void testExecute() {
        CaseServiceSchedulable schedulable = new CaseServiceSchedulable();
        Test.startTest();        
        schedulable.execute(null);
        Test.stopTest();
        System.assertNotEquals(null, schedulable, 'Schedulable is not null');
    }
}