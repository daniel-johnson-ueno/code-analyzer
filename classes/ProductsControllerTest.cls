/**
 * @description       : 
 * @author            : marco.casanova@vurpix.com
 * @TKs               : 
 * @group             : 
 * @last modified on  : 06-13-2024
 * @last modified by  : marco.casanova@vurpix.com
**/
@isTest
public class ProductsControllerTest {

    @TestSetup static void setup() {
        Account account = TestFactory.createPersonAccount();
    }

    @isTest
    public static void getAccountTest(){
        Account acc = [SELECT Id, PersonCode__c FROM Account LIMIT 1];
        Test.startTest();
            Account result = ProductsController.getAccount(acc.Id);
        Test.stopTest();

        System.Assert(result.PersonCode__c != null);
    }
}