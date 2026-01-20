/**
 * @name               : shortMessageServiceTest
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 19-12-2024
 * @modification date  : 19-12-2024
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Clase test de shortMessageService
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   19-12-2024   Alvaro Gonzales Lapponi   Initial Version
**/
@isTest
public with sharing class shortMessageServiceTest {

    /**
    * @description Método test exitoso para obtener enviar SMS
    * @author Alvaro Gonzales Lapponi | 19-12-2024 
    **/
    @isTest
    public static void sendSMSTestOK() {
        String mock = '{"status": "[TWILLIO] Message sent to +59500000000"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok', mock));
        Test.startTest();
        shortMessageService.Response response = shortMessageService.sendSMS('+59500000000','SMS testing message');
        Test.stopTest();
        system.assertEquals(false, response.hasException, 'No debe haber excepciones');
    }

    /**
    * @description Método test fail para obtener enviar SMS
    * @author Alvaro Gonzales Lapponi | 19-12-2024 
    **/
    @isTest
    public static void sendSMSTestException() {
        String mock = 'invalid';
        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok', mock));
        Test.startTest();
        shortMessageService.Response response = shortMessageService.sendSMS('+59500000000','SMS testing message');
        Test.stopTest();
        system.assertEquals(true, response.hasException, 'Se esperaba excepción');
    }
}