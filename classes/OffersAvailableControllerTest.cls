@IsTest
public with sharing class OffersAvailableControllerTest {

    @TestSetup
    public static void setup() {
        Ueno_Service_Domain__c uenoDomain = TestFactory.createDomain();
        Account person = TestFactory.createPersonAccount();
    }

    @IsTest
    public static void getOffersTest() {
        Account person = [SELECT Id FROM Account LIMIT 1];

        String mock = '{"id":"string","personCode":"string","expirationDate":"2024-05-21","maxAssumableRisk":1234.56,"installmentIncomeRelation":1234.56,"status":"string","availableProducts":{"loans":[{"id":"string","currencyType":"string","limits":{"creditAmount":1234.56,"availableAmount":1234.56,"monthlyAmount":1234.56,"installmentsQuantity":0,"availableMonthlyAmount":1234.56}}],"cards":[{"id":"string","currencyType":"string","limits":{"creditAmount":1234.56,"availableAmount":1234.56,"monthlyAmount":1234.56,"installmentsQuantity":0,"availableMonthlyAmount":1234.56}}]}}';

        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok', mock));

        Test.startTest();
        List<OffersAvailableController.OffersAvailableResponse> offers = OffersAvailableController.offersAvailableCallout(person.Id);
        System.assertNotEquals(0, offers.size());
        Test.stopTest();

    }

    @IsTest
    public static void getOffersErrorTest() {
        Account person = [SELECT Id FROM Account LIMIT 1];

        String mock = '{"id":"string","personCode":"string","expirationDate":"2024-05-21","maxAssumableRisk":1234.56,"installmentIncomeRelation":1234.56,"status":"string","availableProducts":{"loans":[{"id":"string","currencyType":"string","limits":{"creditAmount":1234.56,"availableAmount":1234.56,"monthlyAmount":1234.56,"installmentsQuantity":0,"availableMonthlyAmount":1234.56}}],"cards":[{"id":"string","currencyType":"string","limits":{"creditAmount":1234.56,"availableAmount":1234.56,"monthlyAmount":1234.56,"installmentsQuantity":0,"availableMonthlyAmount":1234.56}}]}}';

        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(400, 'Ok', mock));

        Test.startTest();
        List<OffersAvailableController.OffersAvailableResponse> offers = OffersAvailableController.offersAvailableCallout(person.Id);
        System.assertEquals(0, offers.size());
        Test.stopTest();

    }

    @IsTest
    public static void getOffersCatchTest() {

        Test.startTest();
        try{
            List<OffersAvailableController.OffersAvailableResponse> offers = OffersAvailableController.offersAvailableCallout('003d');
        } catch (Exception e) {
            System.debug('catch ' + e);
        }
        Test.stopTest();

    }

}