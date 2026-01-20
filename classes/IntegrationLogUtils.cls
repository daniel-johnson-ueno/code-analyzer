public class IntegrationLogUtils {
	
    /*IntegrationLogUtils.insertIntegrationServiceLog(request, response, endpoint)*/
    public static void insertIntegrationServiceLog(HttpRequest request, HttpResponse response, String endpoint,String documentId,String message){
        Integration_Log__c intLog = new Integration_Log__c();
        String body = response.getBody();
        String requestAsString = '';
        Map<String, Object> parsedResponse = new Map<String, Object>();
        parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(body);
          if (request != null) {
                requestAsString = 'Method: ' + request.getMethod() + '\n' +
                                  /*'URL: ' + request.getUrl() + '\n' +
                                  'Headers: ' + String.join(new List<String>(request.getHeaders().keySet()), ', ') + '\n' +*/
                                  'Body: ' + request.getBody();
           }
        intLog.Request__c = requestAsString; //TODO AGREGAR FUNCION PARA REQUEST
        intLog.EndPoint__c = endpoint;
        intLog.Response__c = getResponseFromHttpResponse(response);
       // intLog.Type__c = 'ServiceError'; 
        //intLog.Status__c = 'Alert';
        intLog.code__c = String.valueOf(parsedResponse.get('code'));
        if((String)parsedResponse.get('type')!='Not Found'){
            intLog.type__c = (String)parsedResponse.get('type');
        }else{
            intLog.type__c = 'ServiceError';
        }
        intLog.Status__c = 'Warning';
        intLog.Comments__c = (String)parsedResponse.get('detail');
        intLog.message__c = message;
        insert intLog;
    }
    
    public static String getResponseFromHttpResponse(HttpResponse res){
        return 'Status Code response='+res.getStatusCode()+' / '+
            ' Body response='+res.getBody() + 
            ' / HeaderKeys' + res.getHeaderKeys() + 
            ' / Status' + res.getStatus();
    }
    
    public static void insertIntegrationDMLLog(){
        Integration_Log__c intLog = new Integration_Log__c();
        //INSERTAR UN LOG DE ERROR DE DML INSERT O UPDATE
        insert intLog;
    }
        public static void getIntegrationLogFromAccount(Map<String, Object> Logs){
        Integration_Log__c intLog = new Integration_Log__c();
        intLog.code__c = 'Map';
        if((String)logs.get('type')!=null){
             intLog.Type__c = (String)logs.get('type');    
        }else{
            intLog.Type__c = 'ServiceError'; 
        }
        intLog.Status__c = 'Warning';
        intLog.Comments__c = 'Mapping error';
        intLog.message__c = (String)logs.get('message');
        insert intLog;
        //return intLog;
    }
}