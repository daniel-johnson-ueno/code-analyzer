/**
 * Created by danieljohnson on 21/01/2026.
 */

public class RulesetTester {

    // VIOLACIÓN: Category/Apex/Design/ExcessiveParameterList
    // Tu regla dice 'minimum' value="4". Aquí pasamos 5 parámetros.
    public void testExcessiveParameters(String p1, String p2, String p3, Integer p4, Boolean p5) {

        // VIOLACIÓN: Category/Apex/Design/AvoidDeeplyNestedIfStmts
        // Tu regla dice 'problemDepth' value="3". Aquí llegamos a 4.
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

        // VIOLACIÓN: Category/Apex/Security (ApexSOQLInjection)
        // Estás concatenando variables directamente en la query.
        List<Account> accs = Database.query('SELECT Id FROM Account WHERE Name = \'' + input + '\'');

        for (Account a : accs) {
            // VIOLACIÓN: Category/Apex/Performance (AvoidSoqlInLoops)
            // Query dentro de un bucle for.
            List<Contact> cons = [SELECT Id FROM Contact WHERE AccountId = :a.Id];
        }
    }

    public void testErrorProneAndCustomRule() {
        try {
            // VIOLACIÓN: Category/Apex/ErrorProne (AvoidHardcodingId)
            // Uso explícito de un ID de 18 caracteres.
            String hardcodedId = '001xx000003DGSWAA4';

            Integer division = 1 / 0; // Provocar excepción

        } catch (Exception e) {
            // VIOLACIÓN: Custom Rule "EnforceLoggerInCatch"
            // Tu regla XPath exige que haya una llamada a 'GenerateLogEvent...'.
            // Al usar solo System.debug, esta regla debería saltar.
            System.debug('Error: ' + e.getMessage());
        }
    }

    public void testEmptyCatch() {
        try {
            insert new Account(Name='Test');
        } catch (DmlException e) {
            // VIOLACIÓN: Category/Apex/ErrorProne (EmptyCatchBlock)
        }
    }
    // VIOLACIÓN: Category/Apex/BestPractices (MethodNamingConventions)
    // Los métodos deben empezar con minúscula (camelCase).
    public void MetodoConMayuscula() {
        // VIOLACIÓN: Category/Apex/CodeStyle (IfStmtsMustUseBraces)
        // Aunque incluiste CodeStyle, solo excluiste FieldDeclarations.
        // Las llaves faltantes suelen ser detectadas.
        if (true) System.debug('Faltan llaves');
    }
}