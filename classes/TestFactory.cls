/**
 * Created by cris on 05/07/2024.
 */

public with sharing class TestFactory {

    public static Account createCompanyAccount(){

        Account company = new Account();
        company.Name = 'Test Account';
        company.PersonCode__c = 123456;

        Database.insert(company);

        return company;
    }

    public static Account createPersonAccount(){

        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount');
        String personRecordTypeId = recordTypeInfo.getRecordTypeId();


        Account person = new Account();
        person.RecordTypeId = personRecordTypeId;
        person.FirstName = 'Test';
        person.LastName = 'Person Account';
        person.PersonCode__c = 123456;

        Database.insert(person);

        return person;
    }

    public static Informacion_Financiera__c createInformacionFinanciera (String accountId){

        Informacion_Financiera__c financialInformation = new Informacion_Financiera__c();
        financialInformation.Cuenta__c = accountId;
        financialInformation.Concepto__c = 'Test concept';
        financialInformation.Monto__c = 10000;
        financialInformation.Moneda__c = 'GS';
        financialInformation.Fecha_de_la_Informacion__c = Date.today().addMonths(-1);

        Database.insert(financialInformation);

        return financialInformation;
    }

    public static Informacion_Financiera__c createInformacionFinancieraCustom (String accountId, String concept, Decimal amount, String currencyType, Date informationDate){

        Informacion_Financiera__c financialInformation = new Informacion_Financiera__c();
        financialInformation.Cuenta__c = accountId;
        financialInformation.Concepto__c = concept;
        financialInformation.Monto__c = amount;
        financialInformation.Moneda__c = currencyType;
        financialInformation.Fecha_de_la_Informacion__c = informationDate;

        Database.insert(financialInformation);

        return financialInformation;
    }

    public static Vinculo_Persona_Empresa__c createVinculoPersonaEmpresa (String accountId, String personaId){

        Vinculo_Persona_Empresa__c link = new Vinculo_Persona_Empresa__c();
        link.Cuenta__c = accountId;
        link.Persona__c = personaId;
        link.Descripcion__c = 'Test Description';
        link.Type_and_Document_Number__c = '1-12346789';

        return link;
    }

    public static Case createCase (String status, String recordType, String accountId){
        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get(recordType);
        String caseRecordTypeId = recordTypeInfo.getRecordTypeId();

        Case caseTest = new Case();
        caseTest.Origin = 'Telefono';
        caseTest.Type = 'Reclamo';
        caseTest.Casuistry__c = 'No llega el OTP';
        caseTest.Status = status;
        caseTest.RecordTypeId = caseRecordTypeId;
        caseTest.AccountId = accountId;

        Database.insert(caseTest);
        
        return caseTest;
    }

    public static Survey__c createSurvey (String accountId, String recordType){
        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Survey__c').getDescribe().getRecordTypeInfosByDeveloperName().get(recordType);
        String surveyRecordTypeId = recordTypeInfo.getRecordTypeId();

        Survey__c surveyTest = new Survey__c();
        surveyTest.Cuenta__c = accountId;
        surveyTest.RecordTypeId = surveyRecordTypeId;
        surveyTest.Record_Type_Encuesta__c = recordType;


        if(recordType == 'Relacionamiento_de_marca'){
            surveyTest.CSAT_Cliente__c = '1 Muy mala';
        } else if (recordType == 'Relacionamiento_de_producto'){
            surveyTest.CSAT_Duo_Card__c = '5 Muy buena';
            surveyTest.CSAT_QR__c = '3 Regular';
            surveyTest.CSAT_Prestamos__c = '5 Muy buena';
            surveyTest.CSAT_Transferencias_y_Cuentas__c = '5 Muy buena';
            surveyTest.CSAT_Pago_de_servicios__c = '5 Muy buena';
        } else if(recordType == 'Onboarding_Personas'){
            surveyTest.CSAT_Onboarding_Personas__c = '3 Ni fácil ni difícil';
        }else if(recordType == 'Onboarding_Empresas'){
            surveyTest.CSAT_Onboarding_Empresas__c = '2 Difícil';
        }else if(recordType == 'Satisfaccion_y_resolucion_de_caso'){
            surveyTest.RES_de_atencion__c = 'Sí';
            surveyTest.CSAT_Ejecutivo__c = '5 Muy buena';
        }

        Database.insert(surveyTest);

        return surveyTest;
    }

    public static Ueno_Service_Domain__c createDomain() {
        Ueno_Service_Domain__c uenoDomain = new Ueno_Service_Domain__c();
        uenoDomain.ApiKey__c = '555-555-555';
        uenoDomain.DomainName__c = 'https://kongcloud.ind-dev-sae1.ueno.com.py';
        insert uenoDomain;

        return uenoDomain;
    }

    public static Knowledge__kav createKnowledgeArticle(String recordType){

        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Knowledge__kav').getDescribe().getRecordTypeInfosByDeveloperName().get(recordType);
        String FAQRecordTypeId = recordTypeInfo.getRecordTypeId();

        Knowledge__kav kav = new Knowledge__kav();
        kav.RecordTypeId = FAQRecordTypeId;
        kav.Language = 'es';
        kav.ValidationStatus = 'Validated';
        kav.Title = 'Titulo';
        kav.UrlName = 'Titulo-' + Integer.valueof((Math.random() * 1000));
        kav.Question__c = 'esto es un Test?';

        Database.insert(kav);

        return kav;
    }
}