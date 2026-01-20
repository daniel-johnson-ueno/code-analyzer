/**
 * @name               : biometrySearchTest
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 19-12-2024
 * @modification date  : 19-12-2024
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Clase test de biometrySearch
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   19-12-2024   Alvaro Gonzales Lapponi   Initial Version
**/
@isTest
public with sharing class biometrySearchTest {

    final static String BASE64_CLIENT_PICTURE = '/9j/4AAQSkZJRgABAQAAAQABAAD/spk';

    /**
    * @description Método test exitoso para obtener información de cliente por biometría
    * @author Alvaro Gonzales Lapponi | 19-12-2024 
    **/
    @isTest
    public static void getClientTestOK() {
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
        biometrySearch.Response response = biometrySearch.getClient(BASE64_CLIENT_PICTURE);
        Test.stopTest();
        system.assertEquals(false, response.hasException, 'No debe haber excepciones');
        system.assertEquals(false, response.serviceResponse.data.matches.isEmpty(), 'Debería haber un resultado');
    }
    
    /**
    * @description Método test fail para obtener información de cliente por biometría
    * @author Alvaro Gonzales Lapponi | 19-12-2024 
    **/
    @isTest
    public static void getClientTestNoIdentified() {
        String mockToken = '{"metadata": {"msg": "success"},"data": {"name": "Busqueda de rostro"},"access_token": "b86c4cb34a211e632a66da8503ghjfhd743653h5ed","token_type": "Bearer"}';
        String mockSearch = '{[]}';
        MockHttpCallOut fakeToken =  new MockHttpCallOut(200, 'Ok', mockToken);
        MockHttpCallOut fakeSearch =  new MockHttpCallOut(200, 'Ok', mockSearch);
        Map<String, HttpCalloutMock> endpointTestResp = new Map<String,HttpCalloutMock>();
        endpointTestResp.put('callout:biometry/user.php/auth/login', fakeToken);
        endpointTestResp.put('callout:biometry/face.php?action=search', fakeSearch);

        MockHttpCallOut.MultiRequestMock multiCalloutMock = new MockHttpCallOut.MultiRequestMock(endpointTestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        Test.startTest();
        biometrySearch.Response response = biometrySearch.getClient(BASE64_CLIENT_PICTURE);
        Test.stopTest();
        system.assertEquals(false, response.identified, 'No debe encontrar persona para esta búsqueda');
    }
}