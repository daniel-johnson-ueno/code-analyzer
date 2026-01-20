public with sharing class OffersAvailableController {

    public class OffersAvailableResponse {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String currencyType;
        @AuraEnabled
        public String description;
        @AuraEnabled
        public Decimal creditAmount;
        @AuraEnabled
        public Decimal availableAmount;
        @AuraEnabled
        public Decimal monthlyAmount;
        @AuraEnabled
        public Decimal installmentsQuantity;
        @AuraEnabled
        public Decimal availableMonthlyAmount;
        @AuraEnabled
        public Boolean isLoan;

    }

    public class OffersAvailableWrapper {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String personCode;
        @AuraEnabled
        public String expirationDate;
        @AuraEnabled
        public Decimal maxAssumableRisk;
        @AuraEnabled
        public Decimal installmentIncomeRelation;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public AvailableProductsWrapper availableProducts;
    }

    public class AvailableProductsWrapper {
        @AuraEnabled
        public List<LoansWrapper> loans;
        @AuraEnabled
        public List<CardsWrapper> cards;
    }

    public class LoansWrapper {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String currencyType;
        @AuraEnabled
        public LimitsWrapper limits;

    }

    public class CardsWrapper {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String currencyType;
        @AuraEnabled
        public LimitsWrapper limits;
    }


    public class LimitsWrapper {
        @AuraEnabled
        public Decimal creditAmount;
        @AuraEnabled
        public Decimal availableAmount;
        @AuraEnabled
        public Decimal monthlyAmount;
        @AuraEnabled
        public Decimal installmentsQuantity;
        @AuraEnabled
        public Decimal availableMonthlyAmount;
    }

    @AuraEnabled(Cacheable=false)
    public static List<OffersAvailableResponse> offersAvailableCallout(String accountId) {

        try {
            String personCode = String.valueOf(AccountDAO.getAccountById(accountId)?.PersonCode__c);

            if (String.isBlank(personCode)) {
                return new List<OffersAvailableResponse>();
            }

            HttpRequest req = offersAvailableRequest(personCode);
            HttpHelper.HttpClientWithRetry httpClient = new HttpHelper.HttpClientWithRetry();
            HttpResponse tResponse = httpClient.doCallout(req);
            return processResponse(req, tResponse);

        } catch (Exception e) {
            System.debug('catch ' + e);
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'OffersAvailableController', 'offersAvailableCallout');
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static List<OffersAvailableResponse> processResponse(HttpRequest req, HttpResponse tResponse) {
        OffersAvailableWrapper offersAvailable = new OffersAvailableWrapper();
        List<OffersAvailableResponse> offersAvailableList = new List<OffersAvailableResponse>();

        if (tResponse != null && tResponse.getStatusCode() == 200 && tResponse.getBody() != null && tResponse.getBody() != '') {
            String responseJSON = tResponse.getBody();
            String jsonResponse = responseJSON.replace('currency', 'currencyType');

            offersAvailable = (OffersAvailableWrapper) System.JSON.deserialize(jsonResponse, OffersAvailableWrapper.class);
            if (offersAvailable != null) {
                offersAvailableList = createOffersProductList(offersAvailable);
            }

        } else {
            GenerateLogEvent.generateIntegrationLogEvent(req, tResponse);
            return new List<OffersAvailableResponse>();
        }



        return offersAvailableList;
    }

    private static HttpRequest offersAvailableRequest(String personCode){

        Ueno_Service_Domain__c domain = Ueno_Service_Domain__c.getOrgDefaults();
        Web_Service_Endpoint__mdt wsEndpSetting = Web_Service_Endpoint__mdt.getInstance('offersAvailable');

        String endpoint = domain.DomainName__c + wsEndpSetting.path__c + personCode;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader('Content-Type','application/json');
        req.setHeader('apikey', domain.ApiKey__c);
        req.setMethod('GET');
        req.setTimeout(60000);

        return req;
    }

    private static List<OffersAvailableResponse> createOffersProductList (OffersAvailableWrapper offersList) {
        List<OffersAvailableResponse> offersAvailableList = new List<OffersAvailableResponse>();
        System.debug(offersList);
        if(offersList.availableProducts.loans.size() > 0){
            for(LoansWrapper loan : offersList.availableProducts.loans){
                OffersAvailableResponse offer = new OffersAvailableResponse();
                offer.id = loan.id;
                offer.currencyType = loan.currencyType;
                offer.creditAmount = loan.limits.creditAmount;
                offer.availableAmount = loan.limits.availableAmount;
                offer.monthlyAmount = loan.limits.monthlyAmount;
                offer.installmentsQuantity = loan.limits.installmentsQuantity;
                offer.availableMonthlyAmount = loan.limits.availableMonthlyAmount;
                offer.description = 'Crédito';
                offer.isLoan = true;
                offersAvailableList.add(offer);
            }
        }

        if(offersList.availableProducts.cards.size() > 0){
            for(CardsWrapper card : offersList.availableProducts.cards){
                OffersAvailableResponse offer = new OffersAvailableResponse();
                offer.id = card.id;
                offer.currencyType = card.currencyType;
                offer.creditAmount = card.limits.creditAmount;
                offer.availableAmount = card.limits.availableAmount;
                offer.monthlyAmount = card.limits.monthlyAmount;
                offer.installmentsQuantity = card.limits.installmentsQuantity;
                offer.description = 'Tarjeta';
                offer.isLoan = false;
                offersAvailableList.add(offer);
            }
        }

        return offersAvailableList;
    }

//    public static String getDateValue(String dateValue) {
//        String result;
//        if (String.isNotBlank(dateValue)) {
//            List<String> dateParts = dateValue.split('-');
//            result = dateParts.size() == 3 ? dateParts[2].trim() + '/' + dateParts[1].trim() + '/' + dateParts[0].trim() : null;
//        } else {
//            result = null;
//        }
//        return result;
//    }



//    public static String mock = '{"id":"string","personCode":"string","expirationDate":"2024-05-21","maxAssumableRisk":5000000.00,"installmentIncomeRelation":3000000.00,"status":"string","availableProducts":{"loans":[{"id":"LOAN","currencyType":"GS","limits":{"creditAmount":10000000.00,"availableAmount":8000000.00,"monthlyAmount":1000000.00,"installmentsQuantity":24,"availableMonthlyAmount":800000.00}},{"id":"LOAN","currencyType":"GS","limits":{"creditAmount":20000000.00,"availableAmount":15000000.00,"monthlyAmount":2000000.00,"installmentsQuantity":36,"availableMonthlyAmount":1500000.00}}],"cards":[{"id":"CARD","currencyType":"GS","limits":{"creditAmount":5000000.00,"availableAmount":4500000.00,"monthlyAmount":500000.00,"installmentsQuantity":12,"availableMonthlyAmount":450000.00}},{"id":"CARD","currencyType":"GS","limits":{"creditAmount":10000000.00,"availableAmount":9000000.00,"monthlyAmount":800000.00,"installmentsQuantity":18,"availableMonthlyAmount":750000.00}},{"id":"CARD","currencyType":"GS","limits":{"creditAmount":15000000.00,"availableAmount":12000000.00,"monthlyAmount":1200000.00,"installmentsQuantity":24,"availableMonthlyAmount":1000000.00}}]}}';
}