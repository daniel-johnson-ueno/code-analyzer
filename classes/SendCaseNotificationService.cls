/**
 * Created by alexis on 21/02/2025.
 */
public with sharing class SendCaseNotificationService {
    @future(callout = true)
    public static void send(String personCode, String origin, String caseNumber, String typologyType, String typologyReason, String brazeEvent){
        Web_Service_Endpoint__mdt wsEndpSetting = Web_Service_Endpoint__mdt.getInstance('caseNotification');
        Ueno_Service_Domain__c domain = Ueno_Service_Domain__c.getOrgDefaults();

        String endpoint = domain.DomainName__c + wsEndpSetting.path__c;

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('apikey', domain.ApiKey__c);
        req.setMethod('POST');

        String requestBody = '{' +
                '"personCode": "' + personCode + '", ' +
                '"origin": "' + origin + '", ' +
                '"event": "' + brazeEvent + '", ' +
                '"caseId": "' + caseNumber + '", ' +
                '"typology": {' +
                    '"type": "' + typologyType.toLowerCase() +
                    '", "reason": "' + typologyReason?.unescapeJava() +
                '"}' +
        '}';

        req.setBody(requestBody);
        req.setTimeout(60000);

        HttpHelper.HttpClientWithRetry httpClient = new HttpHelper.HttpClientWithRetry();

        if (req != null) {
            HttpResponse tResponse = httpClient.doCallout(req);
            System.debug('Respuesta: ' + tResponse.getStatusCode());
            System.debug('Message: ' + tResponse.getBody());
        }
    }
}