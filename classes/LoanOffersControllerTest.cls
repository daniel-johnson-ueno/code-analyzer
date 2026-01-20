@isTest
private class LoanOffersControllerTest {

    @TestSetup
    private static void setup(){
        Ueno_Service_Domain__c uenoDomain = TestFactory.createDomain();
        Account account = TestFactory.createPersonAccount();
    }

    @isTest
    public static void getLoanOffersTest() {
        Account account = [SELECT Id FROM Account LIMIT 1];

        String mock = '{"loans":[{"id":"9537cf86-b85d-47d0-ab5e-33041a03c08d","validFrom":"2024-08-21","expirationDate":"2024-11-21","provider":"ITAU","lineType":"CDD","currency":"GS","canBeAcquired":true,"acquisitionBlockers":[],"limits":{"creditAmount":35000000,"availableAmount":35000000,"amountWithoutContract":35000000,"monthlyAmount":729166.67,"installmentsQuantity":48,"availableMonthlyAmount":0,"minimumAllowedAmount":50000}}]}';

        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok', mock));

        Test.startTest();
        List<LoanOffersController.LoanOffer> loanOffers = LoanOffersController.findLoanOffers(account.Id);
        System.assertNotEquals(0, loanOffers.size());
        Test.stopTest();
    }

    @IsTest
    public static void getLoanOffersErrorTest() {
        Account account = [SELECT Id FROM Account LIMIT 1];

        String mock = '{"loans":[{"id":"9537cf86-b85d-47d0-ab5e-33041a03c08d","validFrom":"2024-08-21","expirationDate":"2024-11-21","provider":"ITAU","lineType":"CDD","currency":"GS","canBeAcquired":true,"acquisitionBlockers":[],"limits":{"creditAmount":35000000,"availableAmount":35000000,"amountWithoutContract":35000000,"monthlyAmount":729166.67,"installmentsQuantity":48,"availableMonthlyAmount":0,"minimumAllowedAmount":50000}}]}';

        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(400, 'Ok', mock));

        Test.startTest();
        List<LoanOffersController.LoanOffer> loanOffers = LoanOffersController.findLoanOffers(account.Id);
        System.assertEquals(0, loanOffers.size());
        Test.stopTest();

    }

    @IsTest
    public static void getLoanOffersCatchTest() {

        Test.startTest();
        try{
            List<LoanRequestsController.LoanRequest> loanRequests = LoanRequestsController.findLoanRequests('003d');
        } catch (Exception e) {
            System.debug('catch ' + e);
        }
        Test.stopTest();

    }
}