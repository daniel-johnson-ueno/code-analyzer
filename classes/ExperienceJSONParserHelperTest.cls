@isTest
private class ExperienceJSONParserHelperTest {

    @isTest
    static void testParseAndValidateIds() {
        // Crear datos de prueba
        Account testAccount = new Account(Name='Test Account');
        insert testAccount;
        
        Case testCase = new Case(Status='New', Subject='Test Case');
        insert testCase;
        
        // JSON válido con IDs de prueba
        String validJson = '{"salesforceAccountId": "' + testAccount.Id + '", "salesforceCaseId": "' + testCase.Id + '"}';
        
        // JSON con IDs inválidos
        String invalidJson = '{"salesforceAccountId": "001ABC000000123XYZ", "salesforceCaseId": "500XYZ000000456ABC"}';
        
        // Lista con los JSON de prueba
        List<String> jsonInputs = new List<String>{ validJson, invalidJson };
        
        // Ejecutar el método de Apex
        Test.startTest();
        List<ExperienceJSONParserHelper.ParsedIds> results = ExperienceJSONParserHelper.parseAndValidateIds(jsonInputs);
        Test.stopTest();
        
        // Validar la respuesta para el JSON válido
        System.assertEquals(2, results.size(), 'Debería haber dos resultados en la lista');
        System.assertEquals(testAccount.Id, results[0].salesforceAccountId, 'El Account ID debería ser válido');
        System.assertEquals(testCase.Id, results[0].salesforceCaseId, 'El Case ID debería ser válido');
        
        // Validar la respuesta para el JSON inválido
        System.assertEquals(null, results[1].salesforceAccountId, 'El Account ID inválido debería devolver null');
        System.assertEquals(null, results[1].salesforceCaseId, 'El Case ID inválido debería devolver null');
    }
}