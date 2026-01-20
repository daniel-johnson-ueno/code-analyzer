public class exportDataRestService {

    public static String getDataRecord(String objectName) {
        String result;
        String whereCondition;
        List<Object_Request_Mapping__mdt> mappingList = getMapping(objectName);
        if(mappingList.isEmpty()){
            return 'Recurso llamado ' + objectName + ' no encontrado.';
        }

        Object_Request_Mapping__mdt mapping = mappingList.get(0);
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = schemaMap.get(objectName).getDescribe().fields.getMap();
        List<String> listFields = new List<String>();
        for(String fieldName : fieldMap.keyset()){
            listFields.add(fieldName);
        }
         if(mapping.lookupFields__c != null){
            listFields.add(mapping.lookupFields__c);
        }
        String fields = String.join(listFields, ', ');
        
        if(mapping.whereCondition__c != null){
            whereCondition = mapping.whereCondition__c;
        }
        
        String soqlQuery = 'SELECT ' + fields + ' FROM ' + objectName;
        if(whereCondition != null){
            soqlQuery += ' ' + whereCondition;
        }
        System.debug(soqlQuery);
        return soqlQuery;
    }

    private static List<Object_Request_Mapping__mdt> getMapping(String resource) {
        List<Object_Request_Mapping__mdt> dataObject = [SELECT Id, dataObject__c, lookupFields__c, whereCondition__c, fileName__c, dateFormat__c FROM Object_Request_Mapping__mdt WHERE dataObject__c = :resource LIMIT 1];
        return dataObject;
    }

    public static String exportData(String resource){
        String soqlQuery = getDataRecord(resource);
        List<sObject> result = Database.query(soqlQuery);
        return JSON.serialize(result);
    }

    public static Boolean processRecords(List<SObject> records, Integer executionNumber, String objectName){
        Boolean result = false;
        String jsonData;
        try {
            jsonData = JSON.serialize(records);
            result = dataLakeCallout(jsonData,executionNumber,objectName);
        } catch (Exception e){
            System.debug('Line: ' + e.getLineNumber() + ' Message: ' + e.getMessage());
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'exportDataRestService', 'fileValidation');
            return false;
        }
        return result;
    }

    public static Boolean dataLakeCallout(String jsonData, Integer executionNumber, String objectName){
        HttpHelper.HttpClientWithRetry httpClient = new HttpHelper.HttpClientWithRetry();
        HttpRequest req = createRequest(jsonData, executionNumber, objectName);
        HttpResponse tResponse = httpClient.doCallout(req);

        String responseJSON = tResponse.getBody();
        System.debug('@@@@tResponse.getStatusCode(): '+ tResponse.getStatusCode());
        System.debug('@@@@responseJSON: '+ responseJSON);
        
        if(tResponse.getStatusCode() == 200){
            return true;
        } else {
            System.debug('Error: ' + tResponse.getStatusCode() + ' - ' + tResponse.getBody());
            return false;
        }
    }

    public static HttpRequest createRequest(String jsonData, Integer executionNumber, String objectName){

        List<Object_Request_Mapping__mdt> mappingList = getMapping(objectName);
        Object_Request_Mapping__mdt mapping = mappingList.get(0);
        String fileName = mapping.fileName__c;
        String dateFormat = mapping.dateFormat__c;

        DateTime dt = DateTime.now().adddays(-1).addSeconds(executionNumber);
        String dateTimeStr = dt.format(dateFormat);
        String fileTitle = fileName + dateTimeStr + '.json';
        System.debug(fileTitle);
        
        HttpRequest request = new HttpRequest();
        request.setMethod('PUT');
        request.setBody(jsonData);
        request.setEndpoint('callout:AWS_S3/' + 'inbound/ueno/crm/' + fileTitle);
        request.setTimeout(60000);
        return request;
    }

}