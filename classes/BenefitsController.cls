public with sharing class BenefitsController {

    public class PointsWrapper {
        @AuraEnabled
        public String memberId;
        @AuraEnabled
        public String eventId;
        @AuraEnabled
        public String businessUnitId;
        @AuraEnabled
        public String recordDate;
        @AuraEnabled
        public Integer movementType;
        @AuraEnabled
        public String movementReason;
        @AuraEnabled
        public String points;
        @AuraEnabled
        public String pointsClass;
    }

    public class LevelResponse {
        @AuraEnabled
        public String recordDate;
        @AuraEnabled
        public TierResponse tier;
    }

    public class TierResponse {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String businessUnitId;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public Integer level;
        @AuraEnabled
        public Integer minimumPoints;
        @AuraEnabled
        public Integer maximumPoints;
    }

    public class LevelWrapper {
        @AuraEnabled
        public String recordDate;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public Integer level;
        @AuraEnabled
        public Integer minimumPoints;
        @AuraEnabled
        public Integer maximumPoints;
        @AuraEnabled
        public Integer movementId;
    }

    //Upys
    public class UpysSummaryResponse {
        public List<UpysSummaryWrapper> results;
    }
    //Upys
    public class UpysSummaryWrapper {
        @AuraEnabled
        public String eventId;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String points;
        @AuraEnabled
        public String lastEventDate;
        @AuraEnabled
        public String lastEventId;
        @AuraEnabled
        public String pointsToLimit;
        @AuraEnabled
        public String pointsToLimitEvent;
        @AuraEnabled
        public String recordDate;
    }

    @AuraEnabled(Cacheable=false)
    public static List<Object> benefitsCalloutFromCase(String caseId, String selectedProduct, String fromDate, String untilDate) {
        Case acc = [SELECT AccountId FROM Case WHERE Id =:caseId LIMIT 1];
        return (benefitsCallout(acc.AccountId,selectedProduct,fromDate,untilDate));
    }

    @AuraEnabled(Cacheable=false)
    public static List<Object> benefitsCallout(String accountId, String selectedProduct, String fromDate, String untilDate) {
        try {
            String uniqueId = AccountDAO.getAccountById(accountId)?.UniqueId__c;
            if (String.isBlank(uniqueId)) {
                return new List<Object>();
            }
            HttpRequest req = createHistoryPointsRequest(uniqueId, selectedProduct, fromDate, untilDate);
            HttpHelper.HttpClientWithRetry httpClient = new HttpHelper.HttpClientWithRetry();
            HttpResponse tResponse = httpClient.doCallout(req);
            return processResponse(req, tResponse, selectedProduct);

        } catch (Exception e) {
            System.debug('Error: ' + e + ' Line: ' + e.getLineNumber());
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'BenefitsController', 'benefitsCallout');
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static List<Object> processResponse(HttpRequest req, HttpResponse tResponse, String selectedProduct) {
        List<PointsWrapper> historyPoints = new List<PointsWrapper>();
        List<LevelResponse> historyLevelResponse = new List<LevelResponse>();
        List<LevelWrapper> historyLevel = new List<LevelWrapper>();
        List<UpysSummaryWrapper> upysList = new List<UpysSummaryWrapper>();


        if (tResponse != null && tResponse.getStatusCode() == 200) {
            String responseJSON = tResponse.getBody();
            System.debug(responseJSON);
            
            if (selectedProduct.equalsIgnoreCase('historyLevel')) {
                historyLevelResponse = (List<LevelResponse>) System.JSON.deserialize(responseJSON, List<LevelResponse>.class);

                for(LevelResponse level : historyLevelResponse){
                    LevelWrapper levelWrapper = new LevelWrapper();
                    levelWrapper.recordDate = getDateTimeValue(level.recordDate);
                    levelWrapper.name = level.tier.name;
                    levelWrapper.level = level.tier.level;
                    levelWrapper.minimumPoints = level.tier.minimumPoints;
                    levelWrapper.maximumPoints = level.tier.maximumPoints;
                    historyLevel.add(levelWrapper);
                }

            } else if (selectedProduct.equalsIgnoreCase('historyPoints')) {
                historyPoints = (List<PointsWrapper>) System.JSON.deserialize(responseJSON, List<PointsWrapper>.class);
                for(PointsWrapper point : historyPoints){
                    point.movementReason = point.movementType == 1 ? point.movementReason : point.movementReason.substringBefore(',');
                    point.recordDate = getDateTimeValue(point.recordDate);
                    point.pointsClass = point.movementType == 1 ? 'slds-text-color_success' : 'slds-text-color_error';
                    point.points = point.movementType == 1 ? '+ ' + point.points : '- ' + point.points;
                }
            } else if (selectedProduct.equalsIgnoreCase('upysSummary')) {                               
                UpysSummaryResponse upysResponse = (UpysSummaryResponse) System.JSON.deserialize(tResponse.getBody(), UpysSummaryResponse.class);
                upysList = new List<UpysSummaryWrapper>();
                for (UpysSummaryWrapper upys : upysResponse.results) {
                    upys.lastEventDate = getDateTimeValue(upys.lastEventDate);
                    upys.recordDate = upys.lastEventDate;
                    if(upys.points != null && upys.pointsToLimit != null) {
                        upys.pointsToLimitEvent = String.valueOf(Integer.valueOf(upys.points) + Integer.valueOf(upys.pointsToLimit));
                    }
                    upys.eventId = upys.lastEventId;
                    upysList.add(upys);
                }
            }
        } else {
            GenerateLogEvent.generateIntegrationLogEvent(req, tResponse);
            return new List<Object>();
        }

        if (!historyPoints.isEmpty()) {
            return (List<Object>) historyPoints;
        } else if (!historyLevel.isEmpty()) {
            return (List<Object>) historyLevel;
        } else if (!historyLevelResponse.isEmpty()) {
            return (List<Object>) historyLevelResponse;
        } else if (!upysList.isEmpty()) {
            return (List<Object>) upysList;
        }
        return new List<Object>();
    }

    public static HttpRequest createHistoryPointsRequest(String uniqueId, String selectedProduct, String fromDate, String toDate) {
        Ueno_Service_Domain__c domain = Ueno_Service_Domain__c.getOrgDefaults();
        Web_Service_Endpoint__mdt wsEndpSetting = Web_Service_Endpoint__mdt.getInstance('loyaltyLWC');
        String endpoint = domain.DomainName__c + wsEndpSetting.path__c + '/member/' + uniqueId;

        switch on selectedProduct {
            when 'historyPoints' {
                endpoint += '/history-points';
            }
            when 'historyLevel' {
                endpoint += '/history-tiers';
            }
            when 'upysSummary' {
                endpoint += '/event-types';
            }
        }
        System.debug(fromDate + ' ' + toDate);
        if (String.isNotBlank(fromDate)) {
            endpoint += '?from=' + fromDate;
        }
        if (String.isNotBlank(toDate)) {
            endpoint += '&to=' + toDate;
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('apikey', domain.ApiKey__c);
        req.setMethod('GET');
        req.setTimeout(60000);

        return req;
    }

    public static String getDateTimeValue(String dateTimeValue){
        String result;
        Datetime dt;
        String tz = String.valueOf(UserInfo.getTimeZone());

        if(String.isNotBlank(dateTimeValue)){
            String formatedDateTimeValue = dateTimeValue.replace(' ', 'T');
            //system.debug('@@@@dateTimeValue '+ dateTimeValue);
            dt = (Datetime)JSON.deserialize('"' + formatedDateTimeValue + '"', Datetime.class);
            result = dt.format('dd/MM/yyyy h:mm a', tz);
        }
        return result;
    }


//    public static String levels ='[{"recordDate":"2024-01-15 10:15:30.000Z","tier":{"id":11,"businessUnitId":1,"name":"Tier 1","level":1,"minimumPoints":0,"maximumPoints":2999}},{"recordDate":"2024-02-10 14:22:40.000Z","tier":{"id":12,"businessUnitId":1,"name":"Tier 2","level":2,"minimumPoints":3000,"maximumPoints":5999}},{"recordDate":"2024-02-28 09:33:10.000Z","tier":{"id":13,"businessUnitId":1,"name":"Tier 3","level":3,"minimumPoints":6000,"maximumPoints":7999}},{"recordDate":"2024-03-12 18:45:15.000Z","tier":{"id":11,"businessUnitId":1,"name":"Tier 1","level":1,"minimumPoints":0,"maximumPoints":2999}},{"recordDate":"2024-04-07 13:50:25.000Z","tier":{"id":12,"businessUnitId":1,"name":"Tier 2","level":2,"minimumPoints":3000,"maximumPoints":5999}},{"recordDate":"2024-05-05 11:15:20.000Z","tier":{"id":13,"businessUnitId":1,"name":"Tier 3","level":3,"minimumPoints":6000,"maximumPoints":7999}},{"recordDate":"2024-06-19 16:42:50.000Z","tier":{"id":11,"businessUnitId":1,"name":"Tier 1","level":1,"minimumPoints":0,"maximumPoints":2999}},{"recordDate":"2024-07-05 09:25:30.000Z","tier":{"id":12,"businessUnitId":1,"name":"Tier 2","level":2,"minimumPoints":3000,"maximumPoints":5999}},{"recordDate":"2024-07-23 13:04:35.076Z","tier":{"id":13,"businessUnitId":1,"name":"Tier 3","level":3,"minimumPoints":6000,"maximumPoints":7999}},{"recordDate":"2024-08-17 18:09:58.956Z","tier":{"id":11,"businessUnitId":1,"name":"Tier 1","level":1,"minimumPoints":0,"maximumPoints":2999}},{"recordDate":"2024-09-05 17:49:47.257Z","tier":{"id":12,"businessUnitId":1,"name":"Tier 2","level":2,"minimumPoints":3000,"maximumPoints":5999}},{"recordDate":"2024-09-05 19:51:21.917Z","tier":{"id":13,"businessUnitId":1,"name":"Tier 3","level":3,"minimumPoints":6000,"maximumPoints":7999}},{"recordDate":"2024-09-23 10:15:00.000Z","tier":{"id":11,"businessUnitId":1,"name":"Tier 1","level":1,"minimumPoints":0,"maximumPoints":2999}},{"recordDate":"2024-09-25 14:30:20.000Z","tier":{"id":12,"businessUnitId":1,"name":"Tier 2","level":2,"minimumPoints":3000,"maximumPoints":5999}}]';
//    public static String upys = '{"results":[{"id":25,"name":"Upys por Gs","points":8,"lastEventDate":"2025-06-02 16:34:32Z","lastEventId":"1","pointsToLimit":9992},{"id":25,"name":"Upys por Gs 2","points":16,"lastEventDate":"2025-06-02 16:34:32Z","lastEventId":"2","pointsToLimit":9984}]}';  
//    public static String points ='[{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-06-30 00:00:00Z","eventId":"event1","points":100,"movementType":1,"movementReason":"Registro inicial","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-06-29 00:00:00Z","eventId":"event2","points":200,"movementType":1,"movementReason":"Ajuste de puntos","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-06-28 00:00:00Z","eventId":"event3","points":150,"movementType":1,"movementReason":"Promoción","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-06-27 00:00:00Z","eventId":"event4","points":50,"movementType":1,"movementReason":"Bonificación","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-06-26 00:00:00Z","eventId":"event5","points":75,"movementType":-1,"movementReason":"Redención de puntos","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-06-25 00:00:00Z","eventId":"event6","points":120,"movementType":1,"movementReason":"Registro adicional","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-06-24 00:00:00Z","eventId":"event7","points":80,"movementType":1,"movementReason":"Ajuste de puntos","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-06-23 00:00:00Z","eventId":"event8","points":60,"movementType":-1,"movementReason":"Bonificación","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-06-22 00:00:00Z","eventId":"event9","points":200,"movementType":1,"movementReason":"Promoción especial","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-06-21 00:00:00Z","eventId":"event10","points":90,"movementType":1,"movementReason":"Registro inicial","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-06-20 00:00:00Z","eventId":"event11","points":110,"movementType":1,"movementReason":"Ajuste de puntos","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-06-19 00:00:00Z","eventId":"event12","points":170,"movementType":1,"movementReason":"Promoción","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-06-18 00:00:00Z","eventId":"event13","points":130,"movementType":-1,"movementReason":"Redención de puntos","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-06-17 00:00:00Z","eventId":"event14","points":40,"movementType":1,"movementReason":"Bonificación","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-06-16 00:00:00Z","eventId":"event15","points":160,"movementType":1,"movementReason":"Registro adicional","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-05-31 00:00:00Z","eventId":"event16","points":90,"movementType":1,"movementReason":"Registro inicial","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-05-30 00:00:00Z","eventId":"event17","points":50,"movementType":-1,"movementReason":"Ajuste de puntos","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-07-02 00:00:00Z","eventId":"event1","points":150,"movementType":1,"movementReason":"Registro inicial","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-07-07 00:00:00Z","eventId":"event2","points":100,"movementType":1,"movementReason":"Bonus de bienvenida","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-07-12 00:00:00Z","eventId":"event3","points":75,"movementType":1,"movementReason":"Recompensa por actividad","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-07-17 00:00:00Z","eventId":"event4","points":100,"movementType":-1,"movementReason":"Consumo de puntos","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-07-22 00:00:00Z","eventId":"event5","points":300,"movementType":1,"movementReason":"Participación en evento","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-07-27 00:00:00Z","eventId":"event6","points":200,"movementType":-1,"movementReason":"Vencimiento de puntos por expiración, tipo evento: 10","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-08-02 00:00:00Z","eventId":"event7","points":400,"movementType":1,"movementReason":"Cumpleaños","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-08-07 00:00:00Z","eventId":"event8","points":200,"movementType":1,"movementReason":"Recompensa por fidelidad","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-08-12 00:00:00Z","eventId":"event9","points":100,"movementType":-1,"movementReason":"Reembolso parcial","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-08-17 00:00:00Z","eventId":"event10","points":150,"movementType":1,"movementReason":"Invitación a evento exclusivo","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-08-22 00:00:00Z","eventId":"event11","points":350,"movementType":-1,"movementReason":"Vencimiento de puntos por expiración, tipo evento: 10","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-09-01 00:00:00Z","eventId":"event12","points":200,"movementType":1,"movementReason":"Aumento de nivel","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-09-06 00:00:00Z","eventId":"event13","points":100,"movementType":-1,"movementReason":"Vencimiento de puntos por expiración, tipo evento: 10","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-09-15 00:00:00Z","eventId":"event1","points":100,"movementType":1,"movementReason":"Registro inicial","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-09-19 00:00:00Z","eventId":"event2","points":200,"movementType":-1,"movementReason":"Consumo de puntos","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-09-19 00:00:00Z","eventId":"event3","points":150,"movementType":1,"movementReason":"Aumento de nivel","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-09-20 00:00:00Z","eventId":"event4","points":300,"movementType":1,"movementReason":"Participación en evento","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-09-23 00:00:00Z","eventId":"event5","points":200,"movementType":-1,"movementReason":"Reembolso parcial","expirationBatch":false},{"memberId":"32fbd69b-5c3d-4e66-85cb-9f1de5ae90e4","businessUnitId":1,"recordDate":"2024-09-23 00:00:00Z","eventId":"event6","points":250,"movementType":1,"movementReason":"Acción promocional","expirationBatch":false},{"memberId":"22bbe0e6-0870-4c2f-9b71-47a9b5d7a6ca","businessUnitId":1,"recordDate":"2024-09-25 00:00:00Z","eventId":"event19","points":300,"movementType":-1,"movementReason":"Consumo de puntos","expirationBatch":false}]';
}