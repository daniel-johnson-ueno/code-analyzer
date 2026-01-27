/**
 * Created by danieljohnson on 21/01/2026.
 */

public class RulesetTester {

    public void testExcessiveParameters(String p1, String p2, String p3, Integer p4, Boolean p5) {

        if (p1 != null) {
            if (p2 != null) {
                if (p3 != null) {
                    if (p5) {
                        System.debug('Demasiado anidamiento bross');
                    }
                }
            }
        }
    }

    public void testSecurityAndPerformance() {
        String Input = 'Test';
        String varStrings;

        List<Account> accs = Database.query('SELECT Id FROM Account WHERE Name = \'' + input + '\'');

        for (Account a : accs) {
            List<Contact> cons = [SELECT Id FROM Contact WHERE AccountId = :a.Id];
        }
    }

    public void testErrorProneAndCustomRule() {
        try {
            String hardcodedId = '001xx000003DGSWAA4';
            Integer division = 1 / 0;

        } catch (Exception e) {
            System.debug('Error 23: ' + e.getMessage());
        }
    }

    public void testEmptyCatch() {
        try {
            insert new Account(Name='Test');
        } catch (DmlException e) {
        }
    }

    //
    public void MetodoConMayuscula() {
        // VIOLACIÓN: Category/Apex/CodeStyle (IfStmtsMustUseBraces)
        // Las llaves faltantes suelen ser detectadas.
        if (true) System.debug('Faltan llaves');
    }


    public void testEmptyCatch2() {

        try {
            Integer bill;
        } catch (DmlException e) {
        }
    }
}