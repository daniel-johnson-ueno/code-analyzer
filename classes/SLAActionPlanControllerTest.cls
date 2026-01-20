@isTest(seeAllData=true)
private class SLAActionPlanControllerTest {
    @isTest
    static void testGetActionPlansWithSLAEAS() {
        // Usamos una oportunidad existente, respetando la consulta que has proporcionado
        Opportunity opp = [
            SELECT Id, Name, ActionPlanCompleted__c, StageName
            FROM Opportunity 
            WHERE RecordType.DeveloperName = 'Onboarding' 
            AND Name LIKE 'Onboarding -%'
            AND CompanyType__c = 'EAS'
            AND ActionPlanCompleted__c = true
            LIMIT 1
        ];
        
        
        // Verificar que se ha encontrado una oportunidad
        System.assertNotEquals(null, opp, 'No se encontró ninguna oportunidad que coincida con los criterios');


        // Iniciar el test
        Test.startTest();

        // Llamar al método que obtiene los Action Plans y el SLA de la oportunidad
        List<SLAActionPlanController.ActionPlanSLAInfo> result = 
            SLAActionPlanController.getActionPlansWithSLA(opp.Id);
        SLAActionPlanController.OpportunitySLAInfo opportunitySLA = 
            SLAActionPlanController.getOpportunitySLA(opp.Id);

        Test.stopTest();

        // Validaciones de los resultados de Action Plans
        System.assertNotEquals(null, result);
        System.assert(result.size() > 0, 'Debe haber al menos un resultado de Action Plans');
        System.assert(result[0].elapsedSeconds > 0);
        System.assert(result[0].slaSeconds > 0);

        // Validaciones del SLA de la oportunidad
        System.assertNotEquals(null, opportunitySLA);
        System.assertEquals(opportunitySLA.isExpired, opportunitySLA.elapsedSeconds > opportunitySLA.slaSeconds);
    }

    @isTest
    static void testGetActionPlansWithSLAUnipersonal() {
        // Usamos una oportunidad existente, respetando la consulta que has proporcionado
        Opportunity opp = [
            SELECT Id, Name, ActionPlanCompleted__c, StageName
            FROM Opportunity 
            WHERE RecordType.DeveloperName = 'Onboarding' 
            AND Name LIKE 'Onboarding -%'
            AND CompanyType__c = 'Unipersonal'
            AND ActionPlanCompleted__c = true
            LIMIT 1
        ];
        
        
        // Verificar que se ha encontrado una oportunidad
        System.assertNotEquals(null, opp, 'No se encontró ninguna oportunidad que coincida con los criterios');


        // Iniciar el test
        Test.startTest();

        // Llamar al método que obtiene los Action Plans y el SLA de la oportunidad
        List<SLAActionPlanController.ActionPlanSLAInfo> result = 
            SLAActionPlanController.getActionPlansWithSLA(opp.Id);
        SLAActionPlanController.OpportunitySLAInfo opportunitySLA = 
            SLAActionPlanController.getOpportunitySLA(opp.Id);

        Test.stopTest();

        // Validaciones de los resultados de Action Plans
        System.assertNotEquals(null, result);
        System.assert(result.size() > 0, 'Debe haber al menos un resultado de Action Plans');
        System.assert(result[0].elapsedSeconds > 0);
        System.assert(result[0].slaSeconds > 0);

        // Validaciones del SLA de la oportunidad
        System.assertNotEquals(null, opportunitySLA);
        System.assertEquals(opportunitySLA.isExpired, opportunitySLA.elapsedSeconds > opportunitySLA.slaSeconds);
    }
    
    @isTest
    static void testNoOnboardingOpp() {
        // Usamos una oportunidad existente, respetando la consulta que has proporcionado
        Opportunity opp = [
            SELECT Id, Name, ActionPlanCompleted__c, StageName
            FROM Opportunity 
            WHERE RecordType.DeveloperName = 'General'
            LIMIT 1
        ];
        
        
        // Verificar que se ha encontrado una oportunidad
        System.assertNotEquals(null, opp, 'No se encontró ninguna oportunidad que coincida con los criterios');


        // Iniciar el test
        Test.startTest();

        // Llamar al método que obtiene los Action Plans y el SLA de la oportunidad
        List<SLAActionPlanController.ActionPlanSLAInfo> result = 
            SLAActionPlanController.getActionPlansWithSLA(opp.Id);

        Test.stopTest();

        // Validaciones de los resultados de Action Plans
        Assert.isTrue(result.isEmpty(), 'El tipo de registro fue procesado de manera incorrecta, la oportunidad debe ser de Onboarding');
    }
}