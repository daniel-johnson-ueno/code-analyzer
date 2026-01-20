/**
 * Created by cris on 05/07/2024.
 */
@IsTest
private class FinancialInformationControllerTest {

    @TestSetup
    private static void setup (){
        Account company = TestFactory.createCompanyAccount();
        Informacion_Financiera__c financialInformation = TestFactory.createInformacionFinanciera(company.Id);
    }

    @IsTest
    private static void getCompanyFinancialInfoTest (){

        Account company = [SELECT Id FROM Account];
        List<Informacion_Financiera__c> financialInformation = FinancialInformationController.getCompanyFinancialInfo(company.Id);

        System.assertEquals(1, financialInformation.size());
    }

    @IsTest
    private static void getCompanyFinancialInfoFailTest (){

        Test.startTest();
        try{
            List<Informacion_Financiera__c> financialInformation = FinancialInformationController.getCompanyFinancialInfo('Simulate Exception');
        }catch (Exception e) {
            System.assert( e.getMessage() != '');
        }
        Test.stopTest();
    }
}