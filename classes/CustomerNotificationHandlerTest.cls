/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class CustomerNotificationHandlerTest {

    @testSetup
    static void setupData() {
       

        // Custom Setting de Dominio
        Ueno_Service_Domain__c domain = new Ueno_Service_Domain__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            DomainName__c = 'https://api.test.com',
            ApiKey__c = 'mock-api-key'
        );
        insert domain;

        // Record Type para el Case
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' LIMIT 1];

    }   


    @isTest
    static void testBuildCaseNotificationRequest() {
        HttpRequest req = CustomerNotificationHandler.buildCaseNotificationRequest();

        System.assertNotEquals(null, req, 'La request no debe ser null');
        System.assertEquals('https://api.test.com/crm-customer-info/v1/case-notification', req.getEndpoint(), 'Endpoint incorrecto');
        System.assertEquals('application/json', req.getHeader('Content-Type'), 'Content-Type incorrecto');
        System.assertEquals('mock-api-key', req.getHeader('apikey'), 'API Key incorrecta');
        System.assertEquals('POST', req.getMethod(), 'Método HTTP incorrecto');
    }

    @isTest
    static void testCreateNotificationRequest_NewCase() {
        Account acc = new Account(Name = 'Test Account', PersonCode__c = 9876);
        insert acc;

        Case c = new Case(
            Subject = '1',
            Origin = '123',
            Status = 'Abierto',
            RecordTypeId =  '012Dx0000009TXkIAM',
            Braze_Description__c = 'Consulta general'
        );
        
        HttpRequest req = CustomerNotificationHandler.createNotificationRequest(c, acc, true);

        System.assertNotEquals(null, req, 'Request debe existir');
        System.assert(req.getBody().contains('SF_CASE_EVENT_NEW'), 'El body debe contener el evento de caso nuevo');
    }

    @isTest
    static void testCreateNotificationRequest_CaseClosed() {
        Account acc = new Account(Name = 'Test Account', PersonCode__c = 12345);
        insert acc;
        Case c = new Case(
            Subject = 'Caso cerrado',
            Origin = '321',
            Status = 'Cerrado',
            RecordTypeId = '012Dx0000009TXkIAM',
            Braze_Description__c = 'Problema resuelto'
        );
        HttpRequest req = CustomerNotificationHandler.createNotificationRequest(c, acc, false);

        System.assertNotEquals(null, req, 'Request debe existir');
        System.assert(req.getBody().contains('SF_CASE_EVENT_CASE_CLOSED'), 'Debe contener evento de caso cerrado');
    }

  

    @isTest
    static void testCreateNotificationRequest_FromDto() {
        CaseNotificationRequestDto dto = new CaseNotificationRequestDto();
        dto.caseId = '500XYZ';
        dto.personCode = '999';
        dto.origin = 'Call Center';
        dto.event = 'SF_CASE_EVENT_TEST';
        dto.caseNumber = 'CASE001';

        dto.typology = new CaseNotificationRequestDto.Typology();
        dto.typology.type = 'Reclamo';
        dto.typology.reason = 'Error de sistema';

        HttpRequest req = CustomerNotificationHandler.createNotificationRequest(dto);

        System.assertNotEquals(null, req, 'Request debe existir');
        System.assert(req.getBody().contains('SF_CASE_EVENT_TEST'), 'El body debe tener el evento de test');
    }
}