/**
 * @name               : biometrySearch
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 06-12-2024
 * @modification date  : 19-12-2024
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Clase de consumo API para buscar un rostro por biometría
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   04-12-2024   Alvaro Gonzales Lapponi   Initial Version
**/
public with sharing class biometrySearch {

    static final Decimal SEARCH_MIN_CONFIDENCE = 70;

    /**
    * @description Método para obtener token de biometría
    * @param String base64Image 
    * @return Response 
    **/
    public static Response getClient(String base64Image) {
        Response response = new Response();
        try{
            String token = authenticate();
            biometrySearchWrapper.ServiceRequest request = buildRequest(base64Image);
            String body = JSON.serialize(request,true);
            HttpResponse res = makeCallout(token, body);
            try{
                response.serviceResponse = (biometrySearchWrapper.ServiceResponse) JSON.deserialize(res.getBody(), biometrySearchWrapper.ServiceResponse.class);
                response.identified = true;
            }
            catch(Exception e){
                response.identified = false;
            }
            
            response.hasException = false;
        } catch(Exception e){
            response.hasException = true;
            response.exceptionInfo = e;
        }
        return response;
    }
    
    /**
    * @description 
    * @author Alvaro Gonzales Lapponi | 07-12-2024 
    * @param String base64Image 
    * @return biometrySearchWrapper.ServiceRequest 
    **/
    private static biometrySearchWrapper.ServiceRequest buildRequest(String base64Image){
        biometrySearchWrapper.ServiceRequest request = new biometrySearchWrapper.ServiceRequest();
        request.image_payload = new biometrySearchWrapper.ImagePayload();
        request.image_payload.img = base64Image;
        request.image_payload.detect = false;
        request.image_payload.use_detector_lms = true;
        request.image_payload.fail_on_multiple_faces = true;
        request.get_crops = true;
        request.get_signature_payload = false;
        request.min_confidence = SEARCH_MIN_CONFIDENCE;
        request.max_matches = 0;
        request.watchLists = new List<String>();
        return request;
    }

    /**
    * @description 
    * @author Alvaro Gonzales Lapponi | 07-12-2024 
    * @param String token 
    * @param String body 
    * @return HttpResponse 
    **/
    private static HttpResponse makeCallout(String token, String body){
        HttpRequest req = new HttpRequest();
        req.setTimeout(60000);
        req.setEndpoint('callout:biometry/face.php?action=search');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setBody(body);
        HttpResponse res = new Http().send(req);
        return res;
    }

    /**
    * @description 
    * @author Alvaro Gonzales Lapponi | 07-12-2024 
    * @return String 
    **/
    private static String authenticate(){
        String token;
        biometryAuthentication.Response authenticationResponse = biometryAuthentication.getToken();
        if(!authenticationResponse.hasException){
            token = authenticationResponse.serviceResponse.access_token;
        }
        return token;
    }
    
    public class Response {
        public Boolean hasException;
        public Exception exceptionInfo;
        public Boolean identified;
        public biometrySearchWrapper.ServiceResponse serviceResponse;
    }

}