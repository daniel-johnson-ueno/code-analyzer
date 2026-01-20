/**
 * @name               : personSearchIDLTest
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 29-01-2025
 * @modification date  : 29-01-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Clase test de personSearchIDL
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   29-01-2025  Alvaro Gonzales Lapponi   Initial Version
**/
@isTest
public class personSearchIDLTest {

    /**
    * @description Método con callout exitoso de searchIsCustomer
    * @author Alvaro Gonzales Lapponi | 24-01-2025 
    * @return Response 
    **/
    @isTest
    public static void searchIsCustomerTestOK(){
        String mock = '[{"firstName":"Pedro","lastName":"Perez","cedulaIdentidad":"","phone":"091234567"}]';
        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok', mock));
        Test.startTest();
        personSearchIDL.Response response = personSearchIDL.searchIsCustomer('cedulaIdentidad','0000ABCD');
        Test.stopTest();
        system.AssertEquals(false,response.hasException,'No debe haber excepciones');
    }
    
    /**
    * @description Método con callout fallido de searchIsCustomer
    * @author Alvaro Gonzales Lapponi | 24-01-2025 
    * @return Response 
    **/
    @isTest
    public static void searchIsCustomerTestException(){
        String mock = '<xml>ERROR</xml>';
        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok', mock));
        Test.startTest();
        personSearchIDL.Response response = personSearchIDL.searchIsCustomer('cedulaIdentidad','0000ABCD');
        Test.stopTest();
        system.AssertEquals(true,response.hasException,'No debe haber excepciones');
    }
}