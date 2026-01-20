@IsTest
private class MappingHelperTest {

    @TestSetup
    private static void setup (){
        Ueno_Service_Domain__c testUrl= new Ueno_Service_Domain__c(ApiKey__c = '555-555-555',DomainName__c='https://kongcloud.ind-dev-sae1.ueno.com.py');
        insert testUrl;
        Account person = (Account)TestFactoryFramework.createSObject(new Account(), 'TestFactoryFrameworkDefaults.PersonAccountDefaults', true);
    }

    @IsTest
    private static void getAccountFromBankittiTest(){

        String json = '{"personCode":"1","documentType":6,"documentNumber":"1","isPerson":false,"phone":"110006","email":"XXXXX@UENO.COM","taxesType":"CO","isFATCA":false,"isEmployee":false,"businessArea":"MICROEMPRESA","accountOfficer":"XXXX XXXX XXXX XXXX","originCountry":"PARAGUAY","documentExpirationDate":"2024-09-30","migrationFrom":"No Migrado","addresses":[{"type":"L","street":"XXXXXXXXXXXXXXXXXXXX","city":"ASUNCION","country":"PARAGUAY","primary":true}],"companyName":"JJJJ JJJJ JJJJ JJJJ","fantasyName":"JJJJ JJJJ JJJJ JJJJ","capital":{},"mainActivity":"OTROS SERVICIOS PRESTADOS A EMPRESA NO ESPECIFICADA","isTaxRetentionAgent":false,"financialInfo":[{"operationType":"Ingreso","concept":"OTROS INGRESOS","amount":8041119,"currency":"GS","informationDate":"2023-12-06"}],"persons":[{"personCode":"539144","documentType":1,"documentNumber":"539144","phone":"153914","email":"XXXXX@UENO.COM","taxesType":"NC","isFATCA":false,"originCountry":"PARAGUAY","migrationFrom":"No Migrado","addresses":[{"type":"P","street":"XXXXXXXXXXXXXXXXXXXX","city":"ASUNCION","state":"BELLA VISTA","country":"PARAGUAY","latitude":"-25.287905065366335","longitude":"-57.582856547141056","primary":true}],"completeName":"FFFF FFFF FFFF FFFF","citizenship":"PARAGUAYA","birthDate":"1995-06-13","accountSource":"Bankitti","marriageStatus":"S","genderIdentity":"M","occupation":"ABOGADO/A","housing":"COMPARTIDA FAMILIAR","registerDate":"2023-12-07 00:00:00-04:00","relationType":"APODERADO","expirationDate":"2024-09-30","status":"A","isActive":true},{"personCode":"539144","documentType":1,"documentNumber":"539144","phone":"153914","email":"XXXXX@UENO.COM","taxesType":"NC","isFATCA":false,"originCountry":"PARAGUAY","migrationFrom":"No Migrado","addresses":[{"type":"P","street":"XXXXXXXXXXXXXXXXXXXX","city":"ASUNCION","state":"BELLA VISTA","country":"PARAGUAY","latitude":"-25.287905065366335","longitude":"-57.582856547141056","primary":true}],"completeName":"FFFF FFFF FFFF FFFF","citizenship":"PARAGUAYA","birthDate":"1995-06-13","accountSource":"Bankitti","marriageStatus":"S","genderIdentity":"M","occupation":"ABOGADO/A","housing":"COMPARTIDA FAMILIAR","registerDate":"2023-12-07 00:00:00-04:00","relationType":"OPERADOR HOMEBANKING","profileCode":"COMPLETO 2 FIRMAS","profileDescription":"TODO CON FIRMA CONJUNTA","status":"A","isActive":true},{"personCode":"8244697","documentType":1,"documentNumber":"8244697","phone":"482446","email":"XXXXX@UENO.COM\\n","taxesType":"NC","isFATCA":false,"originCountry":"PARAGUAY","migrationFrom":"No Migrado","addresses":[{"type":"L","street":"XXXXXXXXXXXXXXXXXXXX","city":"ASUNCION","country":"PARAGUAY","primary":false},{"type":"O","street":"XXXXXXXXXXXXXXXXXXXX","city":"ASUNCION","country":"PARAGUAY","primary":false},{"type":"P","street":"XXXXXXXXXXXXXXXXXXXX","city":"ASUNCION","state":"BELLA VISTA","country":"PARAGUAY","latitude":"-25.2890492","longitude":"-57.6078092","primary":true},{"type":"P","street":"XXXXXXXXXXXXXXXXXXXX","city":"LUQUE","country":"PARAGUAY","primary":false}],"completeName":"FFFF FFFF FFFF FFFF","citizenship":"PARAGUAYA","birthDate":"1988-05-20","accountSource":"Bankitti","marriageStatus":"S","children":0,"genderIdentity":"F","education":"SIN ESTUDIOS","occupation":"ARTISTA-ACTOR","housing":"COMPARTIDA FAMILIAR","registerDate":"2023-12-07 00:00:00-04:00","relationType":"OPERADOR HOMEBANKING","profileCode":"REGISTRA (2 FIRMAS)","profileDescription":"REGISTRA CON 2 FIRMAS","status":"A","isActive":false},{"personCode":"949259","documentType":1,"documentNumber":"949259","phone":"194925","email":"XXXXX@UENO.COM","taxesType":"NC","isFATCA":false,"originCountry":"PARAGUAY","migrationFrom":"No Migrado","addresses":[{"type":"P","street":"XXXXXXXXXXXXXXXXXXXX","city":"ASUNCION","state":"BELLA VISTA","country":"PARAGUAY","latitude":"-25.28397434212624","longitude":"-57.564068781502414","primary":true},{"type":"L","street":"XXXXXXXXXXXXXXXXXXXX","city":"ASUNCION","state":"4 MOJONES","country":"PARAGUAY","primary":false}],"completeName":"FFFF FFFF FFFF FFFF","citizenship":"PARAGUAYA","birthDate":"1997-11-13","accountSource":"Bankitti","marriageStatus":"S","genderIdentity":"F","occupation":"ABOGADO/A","housing":"COMPARTIDA FAMILIAR","registerDate":"2023-12-07 00:00:00-04:00","relationType":"APODERADO","expirationDate":"2024-09-30","status":"A","isActive":true},{"personCode":"949259","documentType":1,"documentNumber":"949259","phone":"194925","email":"XXXXX@UENO.COM","taxesType":"NC","isFATCA":false,"originCountry":"PARAGUAY","migrationFrom":"No Migrado","addresses":[{"type":"P","street":"XXXXXXXXXXXXXXXXXXXX","city":"ASUNCION","state":"BELLA VISTA","country":"PARAGUAY","latitude":"-25.28397434212624","longitude":"-57.564068781502414","primary":true},{"type":"L","street":"XXXXXXXXXXXXXXXXXXXX","city":"ASUNCION","state":"4 MOJONES","country":"PARAGUAY","primary":false}],"completeName":"FFFF FFFF FFFF FFFF","citizenship":"PARAGUAYA","birthDate":"1997-11-13","accountSource":"Bankitti","marriageStatus":"S","genderIdentity":"F","occupation":"ABOGADO/A","housing":"COMPARTIDA FAMILIAR","registerDate":"2023-12-07 00:00:00-04:00","relationType":"OPERADOR HOMEBANKING","profileCode":"COMPLETO 2 FIRMAS","profileDescription":"TODO CON FIRMA CONJUNTA","status":"A","isActive":true}}';

        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok', json));
        Test.startTest();

        MappingHelper.Wrapper wrapper = MappingHelper.getAccountFromBankitti('1', '6');
        Test.stopTest();
    }
    @IsTest
    private static void setSegmentationTest(){

        SegmentationService.SegmentationWrapper segment = new SegmentationService.SegmentationWrapper();
        segment.id = '0';
        segment.value = 'SIMPLE';
        
        Account person = [SELECT Id, UniqueId__c FROM Account LIMIT 1];
        person.UniqueId__c = '12394hfha-01909cna';
        person.IsPerson__c = true;
        update person;
        system.debug(person.id);
        Test.startTest();
        MappingHelper.setSegmentation(segment, person.Id);
        Test.stopTest();
        person = [SELECT Id, UniqueId__c, Segment__c FROM Account LIMIT 1];
        System.assertEquals('SIMPLE', person.Segment__c, 'Valor de segmentación incorrecto'); 
    }

    @IsTest
    static void testGetAccountFromSalesforce() {
        String documentNumber = '999999';
        String documentType = '99999';
                  
        AccountRemoteSiteConnectionMock fakeResponse;
        fakeResponse = new AccountRemoteSiteConnectionMock(404, 'Not Found','Customer not found.', AccountRemoteSiteConnectionMock.getPerson_NotFound());
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Test.startTest(); 
            Map<String, Object> accountMap = AccountRemoteSiteManager.getAccount(documentNumber, documentType);
            MappingHelper.Wrapper wrapper = MappingHelper.getAccountFromSalesforce('1','6',accountMap);
        Test.stopTest();
        Assert.areNotEqual(null, wrapper, 'wrapper shoud not be empty');
    }


}