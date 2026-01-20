/**
 * @name               : turneroHomeControllerTest
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 19-12-2024
 * @modification date  : 20-12-2024
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Clase test de turneroHomeController
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   19-12-2024   Alvaro Gonzales Lapponi   Initial Version
**/
@isTest
public with sharing class turneroHomeControllerTest {
    
    static final String STATUS_CODE_SUCCESS         = '0';
    static final String STATUS_CODE_EXTERNAL_ERROR  = '-1';
    static final String STATUS_CODE_INTERNAL_ERROR  = '-2';

    final static String BASE64_CLIENT_PICTURE = '/9j/4AAQSkZJRgABAQAAAQABAAD/spk';

    /**
    * @description Método test exitoso de recognizeClient
    * @author Alvaro Gonzales Lapponi | 19-12-2024 
    **/
    @isTest
    public static void recognizeClientTestOk() {

        String mockToken = '{"metadata": {"msg": "success"},"data": {"name": "Busqueda de rostro"},"access_token": "b86c4cb34a211e632a66da8503ghjfhd743653h5ed","token_type": "Bearer"}';
        String mockSearch = '{"metadata":{"msg":"success"},"data":{"matches":[{"poi_id":"CIP10000900","display_name":"PedroRodriguez","poi_confidence":93.420061800215,"watchlists":[{"watchlist_notes":{"properties":[]},"watchlist_id":"4cc091f7-e6b6-41a7-832b-8fc46bedfcd9"}]}]}}';
        MockHttpCallOut fakeToken =  new MockHttpCallOut(200, 'Ok', mockToken);
        MockHttpCallOut fakeSearch =  new MockHttpCallOut(200, 'Ok', mockSearch);
        Map<String, HttpCalloutMock> endpointTestResp = new Map<String,HttpCalloutMock>();
        endpointTestResp.put('callout:biometry/user.php/auth/login', fakeToken);
        endpointTestResp.put('callout:biometry/face.php?action=search', fakeSearch);

        MockHttpCallOut.MultiRequestMock multiCalloutMock = new MockHttpCallOut.MultiRequestMock(endpointTestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);

        Test.startTest();
        turneroHomeController.ResponseWrapper response = turneroHomeController.recognizeClient(BASE64_CLIENT_PICTURE);
        Test.stopTest();
        system.assertEquals( STATUS_CODE_SUCCESS, response.statusCode, 'Status code incorrecto' );
        system.assertEquals( '10000900', response.documentNumber, 'Parámetro incorrecto' );
    }

    /**
    * @description Método test fail externo de recognizeClient
    * @author Alvaro Gonzales Lapponi | 19-12-2024 
    **/
    @isTest
    public static void recognizeClientTestCalloutException() {

        String mockToken = 'fail';
        MockHttpCallOut fakeToken =  new MockHttpCallOut(200, 'Ok', mockToken);
        Map<String, HttpCalloutMock> endpointTestResp = new Map<String,HttpCalloutMock>();
        endpointTestResp.put('callout:biometry/user.php/auth/login', fakeToken);

        MockHttpCallOut.MultiRequestMock multiCalloutMock = new MockHttpCallOut.MultiRequestMock(endpointTestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);

        Test.startTest();
        turneroHomeController.ResponseWrapper response = turneroHomeController.recognizeClient(BASE64_CLIENT_PICTURE);
        Test.stopTest();
        system.assertEquals( STATUS_CODE_EXTERNAL_ERROR, response.statusCode, 'Status code incorrecto' );
    }


    /**
    * @description Método test fail interno de recognizeClient
    * @author Alvaro Gonzales Lapponi | 19-12-2024 
    **/
    @isTest
    public static void recognizeClientTestLogicException() {

        String mockToken = '{"metadata": {"msg": "success"},"data": {"name": "Busqueda de rostro"},"access_token": "b86c4cb34a211e632a66da8503ghjfhd743653h5ed","token_type": "Bearer"}';
        String mockSearch = '{"metadata":{"msg":"success"},"data":{"matches":[]}}';
        MockHttpCallOut fakeToken =  new MockHttpCallOut(200, 'Ok', mockToken);
        MockHttpCallOut fakeSearch =  new MockHttpCallOut(200, 'Ok', mockSearch);
        Map<String, HttpCalloutMock> endpointTestResp = new Map<String,HttpCalloutMock>();
        endpointTestResp.put('callout:biometry/user.php/auth/login', fakeToken);
        endpointTestResp.put('callout:biometry/face.php?action=search', fakeSearch);

        MockHttpCallOut.MultiRequestMock multiCalloutMock = new MockHttpCallOut.MultiRequestMock(endpointTestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);

        Test.startTest();
        turneroHomeController.ResponseWrapper response = turneroHomeController.recognizeClient(BASE64_CLIENT_PICTURE);
        Test.stopTest();
        system.assertEquals( STATUS_CODE_INTERNAL_ERROR, response.statusCode, 'Status code incorrecto' );
    }
}