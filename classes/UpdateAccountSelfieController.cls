public with sharing class UpdateAccountSelfieController {
    
    @AuraEnabled(Cacheable = false)
    public static String uploadAccountSelfie(String accountId, String personCode, String selfieId){
        Upload_Customer_Photo_Properties__mdt upLoadPhotoProperties = Upload_Customer_Photo_Properties__mdt.getInstance('Upload_Customer_Photo_Feature');
        String photoUrl = '';
        if(upLoadPhotoProperties.Search_By_Selfie_Id__c == true || upLoadPhotoProperties.Search_By_Person_Code__c == true) {
            Blob imageContent = accountSelfieCallout(personCode, selfieId, upLoadPhotoProperties);

            if (imageContent != null) {
                Datetime d = Datetime.now();
                String dateOutput = d.format('yyyy-MM-dd');
                String documentName = personCode + '-Selfie-' + dateOutput + '.jpg';
                String fileId = attachFile(imageContent, documentName, accountId);

                photoUrl = updateAccount(fileId, accountId, upLoadPhotoProperties);
            } else {
                System.debug('No se encontro imagen para subir al perfil del cliente');
            }
        }
        return photoUrl;
    }

    private static String updateAccount(String fileId, String accountId, Upload_Customer_Photo_Properties__mdt properties) {
        String photoUrl = properties.Profile_Photo_Url_Base__c + fileId;
        Account accountToUpdate = new Account(
            Id = accountId,
            Profile_Photo_URL__c = photoUrl
        );
        Database.update(accountToUpdate);
        return photoUrl;
    }

    private static Blob accountSelfieCallout(String personCode, String selfieId, Upload_Customer_Photo_Properties__mdt properties) {
        try {
            HttpRequest req = createAccountSelfieRequest(personCode, selfieId, properties);
            Blob response;
            
            if(req != null) {
                HttpHelper.HttpClient httpClient = new HttpHelper.HttpClient();
                HttpResponse serviceResponse = httpClient.doCallout(req);
                response = processResponse(req, serviceResponse);
            } 

            return response;
        } catch (Exception e) {
            System.debug('Line: ' + e.getLineNumber() + ' Ex: ' + e);
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'UploadAccountSelfie', 'accountSelfieCallout');
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static String attachFile(Blob documentContent, String documentName, String accountId){
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.ContentLocation = 'S';
        contentVersion.PathOnClient = documentName;
        contentVersion.Title = documentName;
        contentVersion.VersionData = documentContent;
        DataBase.insert(contentVersion);

        ContentVersion cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =:contentVersion.Id];

        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = cv.ContentDocumentId;
        contentDocumentLink.LinkedEntityId = accountId;
        contentDocumentLink.ShareType = 'V';
        contentDocumentLink.Visibility = 'AllUsers';

        DataBase.insert(contentDocumentLink);
        return cv.ContentDocumentId;
    }

    private static HttpRequest createAccountSelfieRequest(String personCode, String selfieId, Upload_Customer_Photo_Properties__mdt properties){
        Web_Service_Endpoint__mdt wsEndpSetting = Web_Service_Endpoint__mdt.getInstance('customerSelfie');
        Ueno_Service_Domain__c service = Ueno_Service_Domain__c.getOrgDefaults();

        HttpRequest req;
        if(selfieId != null && properties.Search_By_Selfie_Id__c == true){
            req = buildRequestByEndpoint(service.DomainName__c + wsEndpSetting.path__c + '?selfieId=' + selfieId, service);
        } else if(properties.Search_By_Person_Code__c == true){
            req = buildRequestByEndpoint(service.DomainName__c + wsEndpSetting.path__c +'?personCode=' + personCode, service);
        }

        return req;
    }

    private static HttpRequest buildRequestByEndpoint(String endpoint, Ueno_Service_Domain__c service){
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader('Content-Type', 'application/octet-stream');
        req.setHeader('apikey', service.ApiKey__c);
        req.setMethod('GET');
        req.setTimeout(60000);
        return req;
    }

    
    private static Blob processResponse(HttpRequest req, HttpResponse response) {
        Blob fileContent;
        if (response != null && response.getStatusCode() == 200) {
            fileContent = response.getBodyAsBlob();
        } else {
            System.debug('Error al descargar el archivo: ' + response.getStatus());
        }
        return fileContent;
    }
}