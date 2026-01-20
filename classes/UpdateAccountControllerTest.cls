@IsTest
private class UpdateAccountControllerTest {
    
    @testSetup 
    static void testSetup(){
        Account person = (Account)TestFactoryFramework.createSObject(new Account(), 'TestFactoryFrameworkDefaults.PersonAccountDefaults', true);
        Ueno_Service_Domain__c testUrl= new Ueno_Service_Domain__c(ApiKey__c = '555-555-555',DomainName__c='https://kongcloud.ind-dev-sae1.ueno.com.py');
        insert testUrl;
    }

    @IsTest
    static void testUpdateAccountCalloutSuccess() {
        
        //Given: 
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok', getPersonOk()));
        Account person = [SELECT Id, UniqueId__c FROM Account LIMIT 1];
        //When:
        UpdateAccountController.UpdateAccountResponseWrapper response = UpdateAccountController.updateAccountCallout('123456789', '1',person.id);
        
        Test.stopTest();
        
        //Then
        System.assertNotEquals(null, response);
        System.assertEquals(false, response.hasError);
        System.assertEquals(null, response.errorMessage);
        System.assertEquals(null, response.errorCode);
    }
    
    @IsTest
    static void testUpdateAccountCalloutError() {

        //Given:
        Test.startTest();

        
        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(404, 'Error', getPersonNotFound()));
        Account person = [SELECT Id, UniqueId__c FROM Account LIMIT 1];
        //When:
        UpdateAccountController.UpdateAccountResponseWrapper response = UpdateAccountController.updateAccountCallout('987654321', '1',person.Id);
        
        Test.stopTest();
        
        //Then:
        System.assertNotEquals(null, response);
        System.assertEquals(true, response.hasError);
        System.assertEquals('Error en el servicio: Customer not found. 404', response.errorMessage);
        System.assertEquals('404', response.errorCode);
    }

    public static String getPersonNotFound() {
        return '{"code":404,"type":"Not Found","message":"Customer not found."}';
    }
    public static String getPersonOk() {
        return '{  "personCode": "123456789",'
        +'  "documentType": 1,'
        +'  "documentNumber": "123456789",'
        +'  "isPerson": true,'
        +'  "addresses": ['
        +'    {'
        +'      "type": "L",'
        +'      "street": "CALLE 1 Y CALLE 2",'
        +'      "city": "MINGA GUAZU",'
        +'      "country": "PARAGUAY",'
        +'      "primary": false'
        +'    },'
        +'    {'
        +'      "type": "P",'
        +'      "street": "CALLE 1 Y CALLE 2",'
        +'      "city": "ASUNCION",'
        +'      "state": "BELLA VISTA",'
        +'      "country": "PARAGUAY",'
        +'      "latitude": "-27.3607717",'
        +'      "longitude": "-55.8491571",'
        +'      "primary": true'
        +'    }'
        +'  ],'
        +'  "phone": "0992900382",'
        +'  "email": "XXXXX@UENO.COM",'
        +'  "taxesType": "NC",'
        +'  "isFATCA": true,'
        +'  "isEmployee": false,'
        +'  "businessArea": "MICROEMPRESA",'
        +'  "accountOfficer": "XXXX XXXX XXXX XXXX",'
        +'  "originCountry": "PARAGUAY",'
        +'  "completeName": "CARLOS AGUILERA INCHAUSTI",'
        +'  "citizenship": "PARAGUAYA",'
        +'  "birthDate": "1961-12-28",'
        +'  "accountSource": "BankItti",'
        +'  "marriageStatus": "C",'
        +'  "children": 0,'
        +'  "genderIdentity": "M",'
        +'  "spouse": {'
        +'    "personCode": "8661960",'
        +'    "documentType": 1,'
        +'    "documentNumber": "8661960",'
        +'    "addresses": ['
        +'      {'
        +'        "type": "P",'
        +'        "street": "XXXXXXXXXXXXXXXXXXXX",'
        +'        "city": "MINGA GUAZU",'
        +'        "country": "PARAGUAY",'
        +'        "primary": true'
        +'      },'
        +'      {'
        +'        "type": "L",'
        +'        "street": "XXXXXXXXXXXXXXXXXXXX",'
        +'        "city": "MINGA GUAZU",'
        +'        "country": "PARAGUAY",'
        +'        "primary": false'
        +'      }'
        +'    ],'
        +'    "phone": { "number": "186619" },'
        +'    "taxesType": "NC",'
        +'    "isFATCA": false,'
        +'    "originCountry": "PARAGUAY",'
        +'    "completeName": "FFFF FFFF FFFF FFFF",'
        +'    "citizenship": "PARAGUAYA",'
        +'    "birthDate": "1971-01-12",'
        +'    "accountSource": "BankItti",'
        +'    "marriageStatus": "C",'
        +'    "children": 0,'
        +'    "genderIdentity": "F",'
        +'    "education": "SIN ESTUDIOS",'
        +'    "occupation": "ALQUILER DE BIENES    ",'
        +'    "housing": "COMPARTIDA FAMILIAR",'
        +'    "registerDate": "2023-12-07 00:00:00-04:00",'
        +'    "migrationFrom": "No Migrado"'
        +'  },'
        +'    "income": {'
        +'        "code": "PYG",'
        +'        "description": "GUARANIES",'
        +'        "value":22222'
        +'    },'
        +'  "education": "SIN ESTUDIOS",'
        +'  "occupation": "ALQUILER DE BIENES    ",'
        +'  "housing": "COMPARTIDA FAMILIAR",'
        +'  "registerDate": "2023-12-07 00:00:00-04:00",'
        +'  "migrationFrom": "No Migrado",'
        +'  "isPEP": false,'
        +'  "images": ['
        +'    {'
        +'      "url": "http://fo-live01-srv.lnx.elcomercio.local:92/api/Documents/4ac69dc3-78c5-4416-82ca-94e9f4c8c575",'
        +'      "description": "CEDULA IDENTIDAD - FRENTE"'
        +'    },'
        +'    {'
        +'      "url": "http://fo-live01-srv.lnx.elcomercio.local:92/api/Documents/45ffd913-5b9f-42d9-82a4-1c9c28784005",'
        +'      "description": "CEDULA DE INDENTIDAD -REVERSO"'
        +'    },'
        +'    {'
        +'      "url": "http://fo-live01-srv.lnx.elcomercio.local:92/api/Documents/ea450f39-da73-4886-8ff0-92eea216e95e",'
        +'      "description": "FOTOGRAFIA"'
        +'    }'
        +'  ]'
        +'}';
    }
}