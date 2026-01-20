@IsTest
public with sharing class RefundHistoryControllerTest {

    @TestSetup
    public static void setup() {
        Account person = TestFactory.createPersonAccount();

        Ueno_Service_Domain__c testUrl= new Ueno_Service_Domain__c(ApiKey__c = '555-555-555',DomainName__c='https://kongcloud.ind-dev-sae1.ueno.com.py');
        insert  testUrl;
    }

    @IsTest
    public static void getRefundHistoryTest() {

        Account person = [SELECT Id FROM Account LIMIT 1];

        String mock ='[{"description":"Reintegro 20%","store":"Nombre comercio","date":"2024-02-18","amount":"43500"},{"description":"Reintegro 12%","store":"Heladería H","date":"2024-02-19","amount":"28000"},{"description":"Reintegro 30%","store":"Biggie express","date":"2024-02-21","amount":"75000"},{"description":"Reintegro 5%","store":"Librería D","date":"2024-02-22","amount":"15000"},{"description":"Reintegro 18%","store":"Café I","date":"2024-02-23","amount":"35000"},{"description":"Reintegro 22%","store":"Zapatería J","date":"2024-02-25","amount":"92000"},{"description":"Reintegro 10%","store":"Comercio C","date":"2024-02-28","amount":"30000"},{"description":"Reintegro 25%","store":"Tienda B","date":"2024-03-05","amount":"95000"},{"description":"Reintegro 40%","store":"Farmacia F","date":"2024-03-09","amount":"72000"},{"description":"Reintegro 15%","store":"Supermercado A","date":"2024-03-10","amount":"125000"},{"description":"Reintegro 35%","store":"Restaurante E","date":"2024-03-11","amount":"65000"},{"description":"Reintegro 50%","store":"Tienda G","date":"2024-03-14","amount":"50000"}]';

        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok', mock));

        Test.startTest();
        List<RefundHistoryController.RefundHistoryWrapper> wrapperList = RefundHistoryController.getRefundHistory(person.Id);
        System.assert(wrapperList.size() > 0);
        Test.stopTest();
    }
}