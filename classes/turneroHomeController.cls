/**
 * @name               : turneroHomeController
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 10-12-2024
 * @modification date  : 19-12-2024
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Clase controladora de turneroHomeDetail
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   10-12-2024   Alvaro Gonzales Lapponi   Initial Version
**/
public with sharing class turneroHomeController {

    static final String STATUS_CODE_SUCCESS         = '0';
    static final String STATUS_CODE_EXTERNAL_ERROR  = '-1';
    static final String STATUS_CODE_INTERNAL_ERROR  = '-2';

    /**
    * @description 
    * @author Alvaro Gonzales Lapponi | 07-12-2024 
    * @param String base64Image 
    * @return ResponseWrapper
    **/
    @AuraEnabled(cacheable=true)
    public static ResponseWrapper recognizeClient(String base64Image) {
        ResponseWrapper response = new ResponseWrapper();
        response.identified = false;
        try{
            String documentNumber = '';
            biometrySearch.Response clientResponse = biometrySearch.getClient(base64Image);
            if(!clientResponse.hasException){
                response.statusCode = STATUS_CODE_SUCCESS;
                if(clientResponse.identified){
                    response.documentNumber = clientResponse.serviceResponse.data.matches[0].poi_id.split('CIP')[1];
                    response.name = clientResponse.serviceResponse.data.matches[0].display_name;
                    response.identified = true;
                }                 
                
            } else{
                response.statusCode = STATUS_CODE_EXTERNAL_ERROR;
                response.message = clientResponse.exceptionInfo.getMessage();
            }
        }catch(Exception e){
            response.statusCode = STATUS_CODE_INTERNAL_ERROR;
            response.message = e.getMessage();
        }
        return response;
    }

    public class ResponseWrapper{
        @AuraEnabled public String statusCode;
        @AuraEnabled public String message;
        @AuraEnabled public String documentNumber;
        @AuraEnabled public String name;
        @AuraEnabled public Boolean identified;
    }
}