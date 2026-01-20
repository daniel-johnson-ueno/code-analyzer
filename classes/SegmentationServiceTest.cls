@IsTest
private class SegmentationServiceTest {
    @TestSetup
    private static void setup(){
        Ueno_Service_Domain__c testUrl= new Ueno_Service_Domain__c(ApiKey__c = '555-555-555',DomainName__c='https://kongcloud.ind-dev-sae1.ueno.com.py');
        Account person = (Account)TestFactoryFramework.createSObject(new Account(), 'TestFactoryFrameworkDefaults.PersonAccountDefaults', true);
        insert  testUrl;
    }
    @isTest
    static void testSegmentationCalloutSuccess() {
        String mockJson = '{"id": "23", "segmentationType": "PERSONA", "value": "SIMPLE"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'OK', mockJson));

        Account person = [SELECT Id, UniqueId__c FROM Account LIMIT 1];
        person.UniqueId__c = '12394hfha-01909cna';
        person.IsPerson__c = true;
        update person;
        Test.startTest();
        SegmentationService.SegmentationWrapper result = SegmentationService.getSegmentationData(person.Id);
        Test.stopTest();

        System.assertEquals('23', result.id, 'El ID de segmentación no es el esperado');
        System.assertEquals('PERSONA', result.segmentationType, 'Tipo de segmentación incorrecto');
        System.assertEquals('SIMPLE', result.value, 'Valor de segmentación incorrecto'); 
    }
    @isTest
    static void testSegmentationRucCalloutSuccess() {
        String mockJson = '{"id": "23", "segmentationType": "EMPRESA", "value": "SIMPLE"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'OK', mockJson));

        Account person = [SELECT Id, UniqueId__c FROM Account LIMIT 1];
        person.DocumentNumber__c = '8888888';
        person.IsPerson__c = false;
        update person;
        Test.startTest();
        SegmentationService.SegmentationWrapper result = SegmentationService.getSegmentationData(person.Id);
        Test.stopTest();

        System.assertEquals('23', result.id, 'El ID de segmentación no es el esperado');
        System.assertEquals('EMPRESA', result.segmentationType, 'Tipo de segmentación incorrecto');
        System.assertEquals('SIMPLE', result.value, 'Valor de segmentación incorrecto'); 
    }
    @isTest
    static void testSegmentationRucCalloutFail() {
        String mockJson = '{"id": "23", "segmentationType": "EMPRESA", "value": "SIMPLE"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'OK', mockJson));

        Account person = [SELECT Id, UniqueId__c FROM Account LIMIT 1];
        person.IsPerson__c = false;
        update person;
        Test.startTest();
        SegmentationService.SegmentationWrapper result = SegmentationService.getSegmentationData(person.Id);
        Test.stopTest();

        System.assertEquals('0', result.id, 'El ID de segmentación no es el esperado');
        System.assertEquals('', result.value, 'Valor de segmentación incorrecto'); 
    }
    @isTest
    static void testSegmentationCalloutHttpError() {
        String errorJson = '{"code":400,"type":"NotFound","message":"No encontrado"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(400, 'Bad Request', errorJson));
    
        Account person = [SELECT Id, UniqueId__c FROM Account LIMIT 1];
        person.UniqueId__c = '12394hfha-01909cna';
        person.IsPerson__c = true;
        update person;
        Test.startTest();
     
        SegmentationService.SegmentationWrapper result = SegmentationService.getSegmentationData(person.Id);
        System.assertEquals('', result.id, 'El ID de segmentación no es el esperado');
        Test.stopTest();
    }


}