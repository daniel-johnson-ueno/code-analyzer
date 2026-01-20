@isTest
private class LoanRequestsControllerTest {

    @TestSetup
    private static void setup(){
        Ueno_Service_Domain__c uenoDomain = TestFactory.createDomain();
        Account account = TestFactory.createPersonAccount();
    }

    @isTest
    public static void getLoanRequestsTest() {
        Account account = [SELECT Id FROM Account LIMIT 1];

        String mock = '{"loans":[{"id":"5d373255-2864-4d46-a822-f98cdc6d078d","currency":"GS","amount":500000,"state":"SIMULATED","installments":48,"expirationDay":30,"account":"619398596","owner":{"personCode":"1023660","documentType":"CI","documentNumber":"5707000"},"coOwners":[],"lineType":"CDD","metadata":{"termsUrl":"","originalAmount":"","provider":"SANTANDER","offerId":"57a240f4-d75d-4375-adf8-358c783a1b95","alias":"Compra de Deuda","mandateIsSigned":"false","mandateUrl":"","simulationId":"896264"},"createdAt":"2024-11-06","updatedAt":"2024-10-25","documents":[]},{"id":"d9154fca-f723-4990-a48c-32d44ced5f1a","currency":"GS","amount":500000,"state":"SIMULATED","installments":48,"expirationDay":30,"account":"619398596","owner":{"personCode":"1023660","documentType":"CI","documentNumber":"5707000"},"coOwners":[],"lineType":"CDD","metadata":{"termsUrl":"","originalAmount":"","provider":"SANTANDER","offerId":"57a240f4-d75d-4375-adf8-358c783a1b95","alias":"Compra de Deuda","mandateIsSigned":"false","mandateUrl":"","simulationId":"896267"},"createdAt":"2024-11-06","updatedAt":"2024-10-25","documents":[]}]}';

        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok', mock));

        Test.startTest();
        List<LoanRequestsController.LoanRequest> loanRequests = LoanRequestsController.findLoanRequests(account.Id);
        System.assertNotEquals(0, loanRequests.size());
        Test.stopTest();
    }

    @IsTest
    public static void getLoanRequestsErrorTest() {
        Account account = [SELECT Id FROM Account LIMIT 1];

        String mock = '{"loans":[{"id":"5d373255-2864-4d46-a822-f98cdc6d078d","currency":"GS","amount":500000,"state":"SIMULATED","installments":48,"expirationDay":30,"account":"619398596","owner":{"personCode":"1023660","documentType":"CI","documentNumber":"5707000"},"coOwners":[],"lineType":"CDD","metadata":{"termsUrl":"","originalAmount":"","provider":"SANTANDER","offerId":"57a240f4-d75d-4375-adf8-358c783a1b95","alias":"Compra de Deuda","mandateIsSigned":"false","mandateUrl":"","simulationId":"896264"},"createdAt":"2024-11-06","updatedAt":"2024-10-25","documents":[]},{"id":"d9154fca-f723-4990-a48c-32d44ced5f1a","currency":"GS","amount":500000,"state":"SIMULATED","installments":48,"expirationDay":30,"account":"619398596","owner":{"personCode":"1023660","documentType":"CI","documentNumber":"5707000"},"coOwners":[],"lineType":"CDD","metadata":{"termsUrl":"","originalAmount":"","provider":"SANTANDER","offerId":"57a240f4-d75d-4375-adf8-358c783a1b95","alias":"Compra de Deuda","mandateIsSigned":"false","mandateUrl":"","simulationId":"896267"},"createdAt":"2024-11-06","updatedAt":"2024-10-25","documents":[]}]}';

        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(400, 'Ok', mock));

        Test.startTest();
        List<LoanRequestsController.LoanRequest> loanRequests = LoanRequestsController.findLoanRequests(account.Id);
        System.assertEquals(0, loanRequests.size());
        Test.stopTest();

    }

    @IsTest
    public static void getLoanRequestsCatchTest() {

        Test.startTest();
        try{
            List<LoanRequestsController.LoanRequest> loanRequests = LoanRequestsController.findLoanRequests('003d');
        } catch (Exception e) {
            System.debug('catch ' + e);
        }
        Test.stopTest();

    }
}