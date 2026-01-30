/**
 * Created by cris on 03/07/2024.
 */
@IsTest
private class AccountDAOTest {

    @TestSetup
    private static void setup(){
        Account company = TestFactory.createCompanyAccount();
        Account person = TestFactory.createPersonAccount();
        Informacion_Financiera__c financialInformation = TestFactory.createInformacionFinanciera(company.Id);
        Vinculo_Persona_Empresa__c vinculo = new Vinculo_Persona_Empresa__c(Cuenta__c = company.Id);

    }

    @IsTest
    private static void getAccountByIdTest(){
        Account company = [SELECT Id, Name FROM Account WHERE IsPersonAccount = false];

        Account account = AccountDAO.getAccountById(company.Id);

        System.assertEquals('Test Account', account.Name);
    }

    @IsTest
    private static void getCompanyFinancialInfoTest(){
        Account company = [SELECT Id FROM Account WHERE IsPersonAccount = false];
        List<Informacion_Financiera__c> financialInformation = AccountDAO.getCompanyFinancialInfo(company.Id);

        System.assertEquals(1, financialInformation.size());
    }

    @IsTest
    private static void getPersonCompanyLinksTest(){
        Account company = [SELECT Id FROM Account WHERE IsPersonAccount = false];
        List<Vinculo_Persona_Empresa__c> links = AccountDAO.getPersonCompanyLinks(company.Id);

        System.assertEquals(0, links.size());
    }

    @IsTest
    private static void getAccountByTypeAndDocumentNumberTest(){
        Account personAccount = [SELECT Id, Type_and_Document_Number__c FROM Account WHERE IsPersonAccount = TRUE LIMIT 1];
        personAccount.Type_and_Document_Number__c = '1_123456';

        update personAccount;

        List<Account> person = AccountDAO.getAccountByTypeAndDocumentNumber(personAccount.Type_and_Document_Number__c);

        System.assertEquals(1, person.size());
    }

    @IsTest
    private static void getAccountByTemporaryKeyTest(){
        Account personAccount = [SELECT Id, Phone, PersonEmail FROM Account WHERE IsPersonAccount = TRUE LIMIT 1];
        personAccount.Phone = '1234556';
        personAccount.PersonEmail = 'test@mail.com';
        update personAccount;

        List<Account> accounts = AccountDAO.getAccountByTemporaryKey(personAccount.PersonEmail, personAccount.Phone);

        System.assertEquals(1, accounts.size());
    }

    @IsTest
    private static void getAccountByIdFailTest(){

        Test.startTest();
        try{
            Account account = AccountDAO.getAccountById('Simulate Exception');

        } catch (Exception e){
            System.assertEquals('Simulated exception', e.getMessage());

        }
        Test.stopTest();
    }

    @IsTest
    private static void getCompanyFinancialInfoFailTest(){

        Test.startTest();
        try{
            List<Informacion_Financiera__c> financialInformation = AccountDAO.getCompanyFinancialInfo('Simulate Exception');

        } catch (Exception e){
            System.assertEquals('Simulated exception', e.getMessage());

        }
        Test.stopTest();
    }

    @IsTest
    private static void getPersonCompanyLinksFailTest(){

        Test.startTest();
        try{
            List<Vinculo_Persona_Empresa__c> links = AccountDAO.getPersonCompanyLinks('Simulate Exception');

        } catch (Exception e){
            System.assertEquals('Simulated exception', e.getMessage());

        }
        Test.stopTest();
    }

    @IsTest
    static void getAccountByPhone(){
        Account personAccount = [SELECT Id, Phone FROM Account WHERE IsPersonAccount = TRUE LIMIT 1];
        personAccount.Phone = '1123456';
        update personAccount;
        List<Account> person = AccountDAO.getAccountByPhone(personAccount.Phone);
        Assert.areEqual(1, person.size());
    }

    @IsTest
    static void getAccountByTypeAndDocNumberTest(){
        Account personAccount = [SELECT Id, DocumentNumber__c, DocumentType__c FROM Account WHERE IsPersonAccount = TRUE LIMIT 1];
        personAccount.DocumentNumber__c = '123456';
        personAccount.DocumentType__c = '1';
        update personAccount;
        List<Account> person = AccountDAO.getAccountByTypeAndDocumentNumber(personAccount.DocumentNumber__c, personAccount.DocumentType__c);
        System.assertEquals(1, person.size());
    }
}