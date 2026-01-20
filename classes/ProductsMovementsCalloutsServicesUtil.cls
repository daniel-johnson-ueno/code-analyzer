public with sharing class ProductsMovementsCalloutsServicesUtil {

    public static String permissionErrorMsg = Label.permissionErrorMsgRelatedMovements;

    @AuraEnabled(continuation=true cacheable=true)
    public static String productMovementCallout(String accountNumber, String productType, String offset, String pageLimit, String fromDate, String toDate, String movementType, String personCode){
        System.debug('test parameters - accountNumber: ' + accountNumber + ' productType: ' + productType + ' offset: ' + offset + ' pageLimit: ' + pageLimit + ' fromDate: ' + fromDate + ' toDate: ' + toDate + ' movementType: ' + movementType + ' personCode: ' + personCode + '');
        String result;

        HttpHelper.HttpClientWithRetry httpClient = new HttpHelper.HttpClientWithRetry();
        HttpResponse tResponse = httpClient.doCallout(createMovementsRequest(accountNumber, productType, offset, pageLimit, fromDate, toDate, movementType, personCode));
        String responseJSON = tResponse.getBody();
        
        System.debug('@@@@tResponse.getStatusCode(): '+ tResponse.getStatusCode());
        System.debug('@@@@responseJSON: '+ responseJSON);

        if(tResponse.getStatusCode() == 200){
            switch on productType {
                when 'SAVINGS', 'CHECKINGS' {
                    result = getSavingMovementList(responseJSON);
                }
                when 'CREDIT_CARDS' {
                    result = getCardsMovementList(responseJSON);
                }
                when else {
                    result = getInstallmentList(responseJSON);
                }
            }
        }else{       
            Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(responseJSON);
            ProductsCalloutsServicesUtil.ProductWrapper productWrap = new ProductsCalloutsServicesUtil.ProductWrapper();
            productWrap.message = (String) jsonMap.get('message');
            productWrap.isError = true;
            result = JSON.serialize(productWrap);
        }
        System.debug(result);
        return result;
    }

    private static HttpRequest createMovementsRequest(String accountNumber, String productType, String offset, String pageLimit, String fromDate, String toDate, String movementType, String personCode){
        Web_Service_Endpoint__mdt wsEndpSetting;
        Ueno_Service_Domain__c domain = Ueno_Service_Domain__c.getOrgDefaults(); 
        String append =  '/products/'+ productType + '/' + accountNumber + '/transactions';
        wsEndpSetting = Web_Service_Endpoint__mdt.getInstance('productsMovementsLWC');
        String url = domain.DomainName__c + wsEndpSetting.path__c + append;
        Map<String, String> parametersMap = new Map<String, String>{'offset' => offset,'limit' => pageLimit};

        if(String.isNotBlank(fromDate)) {
            parametersMap.put('date_from', fromDate);
        } 
        if(String.isNotBlank(toDate)) {
            parametersMap.put('date_to', toDate);
        } 
        if(String.isNotBlank(personCode)) {
            parametersMap.put('person_code', personCode);
        } 
        if(movementType !='todos' && movementType != null){
            parametersMap.put('movement_types', movementType);
        }


		String endpoint = AccountRemoteSiteConection.addParametersToEndpoint(url, parametersMap);	
        System.debug(endpoint);
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);      
        req.setHeader('Content-Type','application/json');
        req.setHeader('apikey', domain.ApiKey__c);
        req.setMethod('GET');
        req.setTimeout(60000);

        return req;
    }

    public static String getInstallmentList(String InstallmentJsonResponse){

            String result;
            Map<String, Object> ProductmovementMap = (Map<String, Object>) JSON.deserializeUntyped(InstallmentJsonResponse);
            List<Object> installs = (List<Object>) ProductmovementMap.get('results');
            List<Installments> InstallmentsList = new List<Installments>();

            Integer installmentId = 1;
            if (installs != null && !installs.isEmpty()) {

                for (Object installment : installs) {
                    Map<String, Object> installmentMap = (Map<String, Object>) installment;
                    Installments inst = new Installments();
                    inst.currencyCode = ProductsCalloutsServicesUtil.getInnerValueString(installmentMap, 'currency', 'code');
                    inst.installmentNumber = ProductsCalloutsServicesUtil.getStringValue(installmentMap, 'installmentNumber');
                    inst.expirationDate = ProductsCalloutsServicesUtil.getDateValue(installmentMap, 'expirationDate');
                    inst.status = ProductsCalloutsServicesUtil.getStringValue(installmentMap, 'status');
                    inst.amount = ProductsCalloutsServicesUtil.getStringValue(installmentMap, 'amount');
                    inst.paymentDate = ProductsCalloutsServicesUtil.getDateTimeValue(installmentMap, 'paymentDate');
                    inst.daysPastDueDesc = ProductsCalloutsServicesUtil.getStringValue(installmentMap, 'daysPastDueDesc');
                    inst.installmentId = installmentId;
                    installmentId++;

                    installmentsList.add(inst);
                }

                result = createProductInstallmentsWrapper(ProductmovementMap,(List<Object>) installmentsList, false); 
            }

        return result;
    }

    public static String getSavingMovementList(String movementJsonResponse){

        List<Movements> MovementsList = new List<Movements>();
        String result;
        String parentTransactionBeneficiary = System.Label.parentTransactionBeneficiary;
        Map<String, Object> ProductMovementMap = (Map<String, Object>) JSON.deserializeUntyped(movementJsonResponse);
        List<Object> movs = (List<Object>) ProductMovementMap.get('results');
        List<Installments> InstallmentsList = new List<Installments>();
        Map<String, String> documentValues = ProductsCalloutsServicesUtil.getPicklistValues('Account', 'DocumentType__c');

        Integer movementId = 1;
        if (movs != null && !movs.isEmpty()) {

            for (Object movement : movs) {
                Map<String, Object> movementMap = (Map<String, Object>) movement;
                Movements mov = new Movements();
                mov.receiptNumber = ProductsCalloutsServicesUtil.getStringValue(movementMap, 'documentNumber3');
                mov.currencyCode = ProductsCalloutsServicesUtil.getCurrencyCodeValue(movementMap, 'balance', 'currency', 'code');
                mov.movementType = ProductsCalloutsServicesUtil.getStringValue(movementMap, 'movementType');
                mov.movementDate = ProductsCalloutsServicesUtil.getDateTimeValue(movementMap, 'date');
                mov.status = ProductsCalloutsServicesUtil.getStringValue(movementMap, 'status');
                mov.concept = ProductsCalloutsServicesUtil.getStringValue(movementMap, 'concept');
                mov.amount = ProductsCalloutsServicesUtil.getInnerValueString(movementMap, 'balance', 'amount');
                mov.parentTransaction = ProductsCalloutsServicesUtil.getInnerValueString(movementMap, 'parentTransaction', 'transactionDescription');
                mov.childTransaction = ProductsCalloutsServicesUtil.getInnerValueString(movementMap, 'transaction', 'transactionDescription');
                mov.insertedBy = ProductsCalloutsServicesUtil.getStringValue(movementMap, 'insertedBy');
                mov.referenceNumber = ProductsCalloutsServicesUtil.getInnerValueString(movementMap, 'transfer', 'referenceNumber');
                mov.transferStatus = ProductsCalloutsServicesUtil.getInnerValueString(movementMap, 'transfer', 'status');
                mov.situation = ProductsCalloutsServicesUtil.getInnerValueString(movementMap, 'transfer', 'situation');
                mov.documentNumber = ProductsCalloutsServicesUtil.getStringValue(movementMap, 'documentNumber');
                mov.couponDate = ProductsCalloutsServicesUtil.getDateValue(movementMap, 'couponDate');
                mov.errorMessage = ProductsCalloutsServicesUtil.getInnerValueString(movementMap, 'transfer', 'errorMessage');

                if(mov.parentTransaction == parentTransactionBeneficiary){
                    mov.beneficiaryPersonCode = ProductsCalloutsServicesUtil.getInnerValueString(movementMap, 'transfer', 'beneficiaryPersonCode');
                    mov.beneficiaryAccountNumber = ProductsCalloutsServicesUtil.getInnerValueString(movementMap, 'transfer', 'beneficiaryAccountNumber');
                    mov.beneficiaryDocumentTypeCode = documentValues.get(ProductsCalloutsServicesUtil.getInnerValueString(movementMap, 'transfer', 'beneficiaryDocumentTypeCode'));
                    mov.beneficiaryDocumentNumber = ProductsCalloutsServicesUtil.getInnerValueString(movementMap, 'transfer', 'beneficiaryDocumentNumber');
                    mov.beneficiaryName = ProductsCalloutsServicesUtil.getInnerValueString(movementMap, 'transfer', 'beneficiaryName');
                }

                if (mov.parentTransaction != null && mov.parentTransaction != '') {
                    mov.rowMovementType = mov.movementType + ' - ' + mov.parentTransaction;
                } else {
                    mov.rowMovementType = mov.movementType;
                }
                mov.movementId = movementId;
                movementId++;

                MovementsList.add(mov);
            }

            result = createProductInstallmentsWrapper(ProductMovementMap, (List<Object>) MovementsList, true);
        }
        return result;
    }

    public static String getCardsMovementList(String cardJsonResponse){

        String result;
        Map<String, Object> ProductMovementMap = (Map<String, Object>) JSON.deserializeUntyped(cardJsonResponse);
        List<Object> movementsCards = (List<Object>) ProductMovementMap.get('results');
        List<Movements> movementsCardList = new List<Movements>();

        Integer movementId = 1;
        if (movementsCards != null && !movementsCards.isEmpty()) {

            for (Object movement : movementsCards) {
                Map<String, Object> movementMap = (Map<String, Object>) movement;
                Movements cardMovement = new Movements();
                cardMovement.receiptNumber = ProductsCalloutsServicesUtil.getStringValue(movementMap, 'id');
                cardMovement.currencyCode = ProductsCalloutsServicesUtil.getInnerValueString(movementMap, 'currency', 'code');
                cardMovement.movementType = ProductsCalloutsServicesUtil.getStringValue(movementMap, 'type');
                cardMovement.movementDate = ProductsCalloutsServicesUtil.getDateTimeValue(movementMap, 'date');
                cardMovement.description = ProductsCalloutsServicesUtil.getStringValue(movementMap, 'description');
                cardMovement.amount = ProductsCalloutsServicesUtil.getStringValue(movementMap, 'amount');
                cardMovement.parentTransaction = ProductsCalloutsServicesUtil.getInnerValueString(movementMap, 'parentTransaction', 'transactionDescription');
                cardMovement.childTransaction = ProductsCalloutsServicesUtil.getInnerValueString(movementMap, 'transaction', 'transactionDescription');
                cardMovement.movementId = movementId;
                movementId++;

                movementsCardList.add(cardMovement);
            }

            result = createProductInstallmentsWrapper(ProductMovementMap,(List<Object>) movementsCardList, true);
        }

        return result;
    }

    private static String createProductInstallmentsWrapper(Map<String, Object> ProductMovementMap,List<Object> movementOrInstallmentsList, Boolean isMovement){

        String result;
        ProductMovementWrapper pMw = new ProductMovementWrapper();
        pMw.pageLimit = ProductsCalloutsServicesUtil.getStringValue(ProductMovementMap, 'offset');
        pMw.offset = ProductsCalloutsServicesUtil.getStringValue(ProductMovementMap, 'limit');

        if(isMovement){
            pMw.movements.addAll((List<Movements>)movementOrInstallmentsList);
        }else{
            pMw.installments.addAll((List<Installments>) movementOrInstallmentsList);       
        }

        return result = JSON.serialize(pMw); 
    }

    @AuraEnabled
    public static String createRelatedMovementRecord(String caseId, String accountNumber, String productType, String currencyDesc, RelatedMovementsWrapper wrapper ){
        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Related_movements__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Movimientos');
        String masterRecordType = recordTypeInfo.getRecordTypeId();
        try {
            Related_movements__c rm = new Related_movements__c();
            rm.Receipt_Number__c = wrapper.receiptNumber;
            rm.Case__c = caseId;
            rm.recordtypeid = masterRecordType;
            rm.AccountNumber__c = accountNumber;
            rm.MovementType__c = wrapper.rowMovementType;
            rm.Amount__c = wrapper.amount;
            rm.Concept__c = wrapper.concept;
            rm.ParentTransaction__c = wrapper.parentTransaction;
            rm.ReferenceNumber__c = wrapper.referenceNumber;
            rm.ChildTransaction__c = wrapper.childTransaction;
            rm.TransferStatus__c = wrapper.transferStatus;
            rm.InsertedBy__c = wrapper.insertedBy;
            rm.Situation__c = wrapper.situation;
            rm.DocumentNumber__c = wrapper.documentNumber;
            rm.CouponDate__c = (wrapper.couponDate == null) ? null : date.parse(wrapper.couponDate);
            rm.MovementDate__c = wrapper.movementDate;
            rm.ErrorMessage__c = wrapper.errorMessage;
            rm.Descripcion__c = wrapper.description;
            rm.Currency__c = currencyDesc;
            if(productType == 'SAVINGS') rm.ProductType__c = 'Caja de Ahorro';
            else if (productType == 'CHECKINGS') rm.ProductType__c = 'Cuenta Corriente';
            else if (productType == 'CREDIT_CARDS') rm.ProductType__c = 'Tarjeta de Credito';
            insert rm;
            return 'Movimiento relacionado de tipo ' + wrapper.rowMovementType + ' creado correctamente.';
        } catch (Exception e) {
            System.debug(e.getMessage() + 'Line: '+ e.getLineNumber() + ' Cause: ' + e.getCause());
            if(e.getMessage().contains('INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY')){
                return permissionErrorMsg;
            }
            return 'Se ha producido un error: ' + e.getMessage();
        }
    }

    @AuraEnabled
    public static String createRelatedHistoryLevelMovementRecord(String caseId, String productType, RelatedMovementsWrapper wrapper ){
        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Related_movements__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Movimientos');
        String masterRecordType = recordTypeInfo.getRecordTypeId();
        try {
            Related_movements__c rm = new Related_movements__c();
            rm.Case__c = caseId;
            rm.recordtypeid = masterRecordType;
            rm.MovementDate__c = wrapper.recordDate;
            rm.Level__c = wrapper.level;
            rm.MinimumPoints__c = wrapper.minimumPoints;
            rm.MaximumPoints__c = wrapper.maximumPoints;
            rm.MovementType__c = 'Historial Nivel';

            insert rm;
            return 'Movimiento relacionado de tipo ' + 'Historial Nivel' + ' creado correctamente.';
        } catch (Exception e) {
            System.debug(e.getMessage() + 'Line: '+ e.getLineNumber() + ' Cause: ' + e.getCause());
            if(e.getMessage().contains('INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY')){
                return permissionErrorMsg;
            }
            return 'Se ha producido un error: ' + e.getMessage();
        }
    }

    @AuraEnabled
    public static String createRelatedhistoryPointsMovementRecord(String caseId, String productType, RelatedMovementsWrapper wrapper ){
        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Related_movements__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Movimientos');
        String masterRecordType = recordTypeInfo.getRecordTypeId();
        try {
            Related_movements__c rm = new Related_movements__c();
            rm.Case__c = caseId;
            rm.recordtypeid = masterRecordType;
            rm.MovementDate__c = wrapper.recordDate;
            rm.movementReason__c = wrapper.movementReason;
            rm.points__c = wrapper.points;
            rm.MovementType__c = 'Historial Puntos';
            insert rm;
            return 'Movimiento relacionado de tipo ' + 'Historial Puntos' + ' creado correctamente.';
        } catch (Exception e) {
            System.debug(e.getMessage() + 'Line: '+ e.getLineNumber() + ' Cause: ' + e.getCause());
            if(e.getMessage().contains('INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY')){
                return permissionErrorMsg;
            }
            return 'Se ha producido un error: ' + e.getMessage();
        }
    }

    

    @AuraEnabled
    public static String createRelatedLoanMovementRecord(String caseId, String accountNumber, String productType, Installments wrapper ){
        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Related_movements__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Prestamos');
        String prestamosRecordType = recordTypeInfo.getRecordTypeId();
        try {
            Related_movements__c rm = new Related_movements__c();
            rm.recordtypeid = prestamosRecordType;
            rm.Case__c = caseId;
            rm.MovementType__c = 'Préstamo';
            rm.MovementDate__c = wrapper.expirationDate;
            rm.AccountNumber__c = accountNumber;
            rm.Amount__c = wrapper.amount;
            rm.Currency__c = wrapper.currencyCode;
            rm.TransferStatus__c = wrapper.status;
            rm.Descripcion__c = wrapper.description;
            rm.ProductType__c = 'Préstamos';
            rm.expirationDate__c = wrapper.expirationDate;
            rm.installmentNumber__c = Integer.valueOf(wrapper.installmentNumber);
            rm.DaysPastDueDesc__c = Integer.valueOf(wrapper.daysPastDueDesc);
            rm.paymentDate__c = (wrapper.paymentDate == null) ? null : Datetime.valueOf(wrapper.paymentDate);
            insert rm;
            return 'Movimiento relacionado de tipo Préstamo creado correctamente.';
        } catch (Exception e) {
            System.debug(e.getMessage() + 'Line: '+ e.getLineNumber() + ' Cause: ' + e.getCause());
            if(e.getMessage().contains('INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY')){
                return permissionErrorMsg;
            }
            return 'Se ha producido un error: ' + e.getMessage();
        }
    }

    public class RelatedMovementsWrapper {
        @AuraEnabled public String receiptNumber {get;set;}
        @AuraEnabled public String rowMovementType {get;set;}
        @AuraEnabled public String movementDate {get;set;}
        @AuraEnabled public String movementType {get;set;}
        @AuraEnabled public String amount {get;set;}
        @AuraEnabled public String concept {get;set;}
        @AuraEnabled public String parentTransaction {get;set;}
        @AuraEnabled public String referenceNumber {get;set;}
        @AuraEnabled public String childTransaction {get;set;}
        @AuraEnabled public String transferStatus {get;set;}
        @AuraEnabled public String insertedBy {get;set;}
        @AuraEnabled public String situation {get;set;}
        @AuraEnabled public String documentNumber {get;set;}
        @AuraEnabled public String couponDate {get;set;}
        @AuraEnabled public String errorMessage {get;set;}
        @AuraEnabled public String description {get;set;}
        @AuraEnabled public String recordDate {get;set;}
        @AuraEnabled public String level {get;set;}
        @AuraEnabled public String minimumPoints {get;set;}
        @AuraEnabled public String maximumPoints {get;set;}
        @AuraEnabled public String movementReason {get;set;}
        @AuraEnabled public String pointsClass {get;set;}
        @AuraEnabled public String points {get;set;}
        
    }

    public class ProductMovementWrapper {
        @AuraEnabled public String pageLimit;
        @AuraEnabled public String offset;
        public List<Movements> movements;
        public List<Installments> installments;
        
        public ProductMovementWrapper () {
            Movements = new List<Movements>();
            installments = new List<Installments>();
        }
    }

    public class Installments {
        @AuraEnabled public String installmentNumber {get;set;}
        @AuraEnabled public String expirationDate {get;set;}
        @AuraEnabled public String status {get;set;}
        @AuraEnabled public String amount {get;set;}
        @AuraEnabled public String description {get;set;}
        @AuraEnabled public String paymentDate {get;set;}
        @AuraEnabled public String daysPastDueDesc {get;set;}
        @AuraEnabled public String currencyCode {get;set;}
        @AuraEnabled public Integer installmentId {get;set;}

        public Installments(){

        }
    }

    public class Movements {
        //savingsMovements
        @AuraEnabled public String receiptNumber;
        @AuraEnabled public String movementType;
        @AuraEnabled public String rowMovementType;
        @AuraEnabled public String movementDate;
        @AuraEnabled public String couponDate;
        @AuraEnabled public String status;
        @AuraEnabled public String concept;
        @AuraEnabled public String amount;
        @AuraEnabled public String description;
        @AuraEnabled public String currencyCode;
        @AuraEnabled public String parentTransaction;
        @AuraEnabled public String childTransaction;
        @AuraEnabled public String insertedBy;
        @AuraEnabled public String referenceNumber;
        @AuraEnabled public String transferStatus;
        @AuraEnabled public String situation;
        @AuraEnabled public String documentNumber;
        @AuraEnabled public Integer movementId;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String beneficiaryPersonCode;
        @AuraEnabled public String beneficiaryAccountNumber;
        @AuraEnabled public String beneficiaryDocumentTypeCode;
        @AuraEnabled public String beneficiaryDocumentNumber;
        @AuraEnabled public String beneficiaryName;

        public Movements(){

        }
    }
/*
    private static HttpResponse doMockup(String productType){
        HttpResponse result = new HttpResponse();
        String savingResponseJSON = '{ "offset": 0, "limit": 25, "movements": [{"movementType":"Deposit","date":"2024-03-19T10:15:23.000Z","status":"Completed","concept":"Salary","balance":{"amount":5000,"currency":{"description":"United States Dollar","code":"USD"}}},{"movementType":"Withdrawal","date":"2024-03-20T14:30:45.000Z","status":"Pending","concept":"Rent","balance":{"amount":1200,"currency":{"description":"United States Dollar","code":"USD"}}},{"movementType":"Transfer","date":"2024-03-21T09:45:12.000Z","status":"Completed","concept":"Gift","balance":{"amount":300,"currency":{"description":"United States Dollar","code":"USD"}}},{"movementType":"Payment","date":"2024-03-22T08:00:00.000Z","status":"Completed","concept":"Utility bill","balance":{"amount":150,"currency":{"description":"United States Dollar","code":"USD"}}},{"movementType":"Deposit","date":"2024-03-23T16:20:30.000Z","status":"Completed","concept":"Bonus","balance":{"amount":1000,"currency":{"description":"United States Dollar","code":"USD"}}}]}';
        String creditResponseJSON = '{ "offset": 0, "limit": 25, "movements": [{"type":"CONSUMO","date":"2024-05-13T08:00:00","description":"Compra de alimentos","currency":{"code":"USD"},"amount":20},{"type":"CONSUMO","date":"2024-05-13T12:30:00","description":"Gasolina para el auto","currency":{"code":"USD"},"amount":50},{"type":"CONSUMO","date":"2024-05-12T15:45:00","description":"Compras en línea","currency":{"code":"USD"},"amount":75}]}';
        String isntallmentResponseJSON = '{"offset": 0, "limit": 25, "installments": [{"installmentNumber":0,"expirationDate":"2024-03-19T10:15:23.000Z","status":"pending","amount":1234.56,"currency":{"description":"United States Dollar","code":"USD"},"paymentDate":"2024-03-19T10:15:23.000Z","daysPastDueDesc":5},{"installmentNumber":1,"expirationDate":"2024-03-20T10:15:23.000Z","status":"pending","amount":2000.00,"currency":{"description":"United States Dollar","code":"USD"},"paymentDate":"2024-03-20T10:15:23.000Z","daysPastDueDesc":10},{"installmentNumber":2,"expirationDate":"2024-03-21T10:15:23.000Z","status":"pending","amount":3000.00,"currency":{"description":"United States Dollar","code":"USD"},"paymentDate":"2024-03-21T10:15:23.000Z","daysPastDueDesc":15}]}';
       //
        result.setStatusCode(200);
        switch on productType {
            when 'SAVINGS', 'CHECKINGS' {
                result.setBody(savingResponseJSON);
            }
            when 'CREDIT_CARDS' {
                result.setBody(creditResponseJSON);
            }
            when else {
                result.setBody(isntallmentResponseJSON);
            }
        }
        return result;
    }
*/
}