/**
 * @name               : biometryAuthenticationTest
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 05-12-2024
 * @modification date  : 05-12-2024
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Clase test de biometryAuthentication
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   05-12-2024   Alvaro Gonzales Lapponi   Initial Version
**/
@isTest
public with sharing class biometryAuthenticationTest {

    /**
    * @description Método test Correcto para obtener token de biometría
    * @author Alvaro Gonzales Lapponi | 05-12-2024 
    **/
    @isTest
    public static void biometryAuthenticationOkTest() {
        String mock = '{"metadata": {"msg": "success"},"data": {"name": "Busqueda de rostro"},"access_token": "b86c4cb34a211e632a66da8503ghjfhd743653h5ed","token_type": "Bearer"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok', mock));
        Test.startTest();
        biometryAuthentication.Response response = biometryAuthentication.getToken();
        Test.stopTest();
        system.assertEquals('b86c4cb34a211e632a66da8503ghjfhd743653h5ed', response.serviceResponse.access_token, 'Token incorrecto');
    }
    
    /**
    * @description Método test con Exception para obtener token de biometría
    * @author Alvaro Gonzales Lapponi | 05-12-2024 
    **/
    @isTest
    public static void biometryAuthenticationExceptionTest() {
        String mock = 'invalid';
        Test.setMock(HttpCalloutMock.class, new MockHttpCallOut(200, 'Ok', mock));
        Test.startTest();
        biometryAuthentication.Response response = biometryAuthentication.getToken();
        Test.stopTest();
        system.assertEquals(true, response.hasException, 'Se esperaba exception');
    }
}