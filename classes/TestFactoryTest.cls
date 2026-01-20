/**
 * Created by cris on 05/07/2024.
 */
@IsTest
private class TestFactoryTest {

//    @TestSetup
//    private static void setup(){
//        Ueno_Service_Domain__c testUrl= new Ueno_Service_Domain__c(ApiKey__c = '555-555-555',DomainName__c='https://kongcloud.ind-dev-sae1.ueno.com.py');
//        insert  testUrl;
//    }

    @IsTest
    private static void createTestObjects (){
        Account company = TestFactory.createCompanyAccount();
        Account person = TestFactory.createPersonAccount();
        Informacion_Financiera__c financialInformation = TestFactory.createInformacionFinanciera(company.Id);
        Informacion_Financiera__c financialInformationCustom = TestFactory.createInformacionFinancieraCustom(company.Id, 'Concepto', 5000, 'USD', Date.today());
        Vinculo_Persona_Empresa__c link = TestFactory.createVinculoPersonaEmpresa(company.Id, person.Id);
        Case newCase = TestFactory.createCase('Asignado', 'Reclamo', person.Id);
        Survey__c survey = TestFactory.createSurvey(person.Id, 'Relacionamiento_de_marca');
        Survey__c survey2 = TestFactory.createSurvey(person.Id, 'Relacionamiento_de_producto');
        Ueno_Service_Domain__c domain = TestFactory.createDomain();
        Knowledge__kav kav = TestFactory.createKnowledgeArticle('FAQ');
    }

}