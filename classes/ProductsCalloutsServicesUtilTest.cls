@isTest
public class ProductsCalloutsServicesUtilTest {
    @TestSetup static void setup() {
        Ueno_Service_Domain__c uenoDomain = new Ueno_Service_Domain__c();
        uenoDomain.ApiKey__c = '09-746e-4e1d';
        uenoDomain.DomainName__c = 'https://platform-kong-public-d.com';
        insert uenoDomain;  
    }
    @IsTest
    static void ProductsCalloutsServicesUtilSuccessSavings() {	
        String savingJsonResponse = '{ "savings": [ { "accountNumber": "619541564", "denomination": "NAME", "officeCode": "61", "status": "N", "statusChangeDate": "2024-03-08T03:00:00.000Z", "balance": { "amount": 18512, "avgAmount": 18512, "currency": { "code": "GS", "description": "GUARANIES" } }, "openingDate": "2024-03-08T03:00:00.000Z", "dueDate": null, "cancellationCodeCause": null, "rateCode": "92", "rateValue": null, "movements": [ { "accountNumber": "619541564", "personCode": null, "denomination": "NAME", "movementTypeCode": "D", "movementType": "Debito", "date": "2024-03-14T03:00:00.000Z", "userCode": "INFONET_2", "balance": { "amount": 35000, "currency": { "code": "GS", "description": "GUARANIES" } }, "officeCode": "61", "errorCode": null, "status": "N", "causeCode": null, "causeDescription": null, "bankDescription": "BANCO CONTINENTAL S.A.E.C.A.", "originOfficeDescription": "CASA MATRIZ", "concept": "PIZZA HUT-PLG", "rateCode": null, "rateValue": null, "categoryCode": null, "categoryDescription": null, "isReversed": "N", "reversionUserCode": null, "reversionTime": null, "hasIssuedNotice": "N", "parentTransaction": { "transactionDescription": "COMPRA EN NEGOCIOS (POS)" }, "transaction": { "transactionDescription": "EXTRACCIONES VIA TED" }, "documentNumber": 3739861403, "documentNumber2": null, "documentNumber3": 3739861403, "documentNumber4": 4, "isProtected": "S" } ] } ] }';
        
        SingleRequestMock fakeResponse = new SingleRequestMock(200,'Complete', savingJsonResponse, null);
        
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        test.startTest();
        string finalResultSaving = ProductsCalloutsServicesUtil.productJsonSavingsCallout('555', 'SAVINGS');
        test.stopTest();	
        Assert.isNotNull(finalResultSaving);
    }
    @IsTest
    static void ProductsCalloutsServicesUtilSuccessCheckings() {	
        String checkingJsonResponse = '{"checkings":[{"accountNumber":"123123","officeCode":"61","currency":{"code":"GS","description":"GUARANIES"},"denomination":"ASDASD","requiredSignaturesQty":1,"registeredSignaturesQty":1,"openingDate":"2023-12-14T03:00:00.000Z","hasPendingAuthorization":"N","isCombinedAccount":"N","promoterUserCode":null,"status":"N","lastExtractDate":null,"lastExtractBalance":0,"statusChangeDate":"2023-12-14T03:00:00.000Z","lastMovementDate":"2024-02-08T03:00:00.000Z","salary":{"retainedBatch":0,"retained":0,"blockedBatch":0,"blocked":0,"totalBatch":33888,"total":33888},"checkbookName":"ASDASD","openingAmount":0,"channelCode":null,"campaignCode":null,"batchStatus":"N","pendingCreditsAmount":0,"pendingConfirmationCreditsAmount":0,"pendingDebitsAmount":0,"entityCode":null,"signatureRegistered":"ASDASD","isOnTrial":"N","trialDate":null,"trialEntityCode":null}]}';
        
        SingleRequestMock fakeResponse = new SingleRequestMock(200,'Complete', checkingJsonResponse, null);
        
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        test.startTest();
        string finalResultSaving = ProductsCalloutsServicesUtil.productJsonSavingsCallout('555', 'CHECKINGS');
        test.stopTest();	
        Assert.isNotNull(finalResultSaving);
    } 
    @IsTest
    static void ProductsCalloutsServicesUtilSuccessCards() {	
        String cardsJsonResponse = '{"cards":{"debit":[{"accountNumber":"619541564","personCode":"1147386","name":"NAME","globalAccountNumber":"34709523","productId":"20","isActive":"S","userCode":"DEBCARDS","adherent":"00","emissionNumber":"02","dueDate":"2029-10-31T03:00:00.000Z","cancellationDate":null,"activationDate":"2024-03-25T03:00:00.000Z","lastATMMovementDate":null,"originOfficeCode":"1","cardType":"MF","cardNumber":"1391","binNumber":"558549","renewal":null}],"credit":[{"availableCreditLine":7968714,"creditLineUsed":-168714,"creditLine":7800000,"extractExpirationDate":"2023-12-07 00:00:00","statementClosingDate":null,"minimumPay":0,"lastPayment":null,"lastPaymentDate":"2023-10-24 00:00:00","cashBack":0,"cardType":"CRÉDITO","cardNumber":"4030999291750219","holder":"XXXX XXXX XXXX XXXX","affinity":"Visa Clasica PDA","state":"Cancelada","interestRate":"17.53%","freeTransactionATM":0,"transactionCostATM":0,"transactionCostOthersATM":0,"accountNumber":"101150021","currencyCode":"GS","status":"Cancelada","monthPaymentAmount":0,"processDate":null,"financingRate":17.53,"cardColor":null,"closingDebt":"-168714","totalDebt":"-168714","expirationDate":"2025-01-31 00:00:00","hasAutomaticDebit":"N","paymentTypeAutomaticDebit":null}]}}';
        
        SingleRequestMock fakeResponse = new SingleRequestMock(200,'Complete', cardsJsonResponse, null);
        
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        test.startTest();
        string finalResultSaving = ProductsCalloutsServicesUtil.productJsonSavingsCallout('555', 'CREDIT_CARDS,DEBIT_CARDS');
        test.stopTest();	
        Assert.isNotNull(finalResultSaving);
    } 
    @IsTest
    static void ProductsCalloutsServicesUtilSuccessLoans() {	
        String loansJsonResponse = '{"loans":[{"accountNumber":"612466800002","modality":"PRESTAMO CHE ROGA PORA AFD% 7,90%","status":"VIGENTE","totalAmount":291849050,"pendingDebt":565301473,"pendingFees":360,"capitalBalance":291849050,"feeAmount":1568375,"feesPaid":0,"feesDue":null,"totalFees":360,"tas":"5","daysPastDue":0,"startDate":"2024-04-04","lastPaymentDate":null,"lastTotalAmountPaid":0,"currency":{"code":"GS","description":"GUARANIES"},"alias":"Vivienda","administrativeCommission":"0","debtCancellationInsurance":"0","unemploymentInsurance":"0","burialInsurance":"0","type":"Pequeños Deudores","loanType":"PRESTAMO CHE ROGA PORA AFD% 7,90%","loanEffectiveDate":"2024-04-08T11:01:30","loanInterestEarned":"273452423","earlyCancellationCharges":"19544050","payoffAmount":"291849050","expiredAmount":0,"requestNumber":932634,"outlayAmount":272305000,"installments":[{"installmentNumber":1,"expirationDate":"2024-05-20T00:00:00","status":"VIGENTE","amount":1568375,"description":"Cuota 1","paymentDate":null,"currency":{"code":"GS","description":"GUARANIES"},"daysPastDue":0,"principalAmount":327350,"interestAmount":1241025,"chargesAmount":0,"amountPaid":0,"operationTypeDescription":"Cuota Pendiente","transactionNumber":null,"paymentTime":null,"debitAccountAlias":null,"debitAccountNumber":null,"pendingDebt":565301473,"fromAccountName":"CESAR LUIS AGUERO BENITEZ","fromAccountNumber":"612466800002","pendingAmountFee":1630426,"interestArrearsAmount":0,"punitiveAmount":0,"ivaCharge":0,"checkNumber":0,"checkBusinessName":null,"checkInstallmentsCount":360,"checkDrawerBank":null,"checkIssueDate":null,"debitAccountHolder":null,"daysPastDueDesc":0,"statusDesc":"Pendiente","show":"NO","paidAmount":0}]}]}';
        
        SingleRequestMock fakeResponse = new SingleRequestMock(200,'Complete', loansJsonResponse, null);
        
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        test.startTest();
        string finalResultSaving = ProductsCalloutsServicesUtil.productJsonSavingsCallout('555', 'LOANS');
        test.stopTest();	
        Assert.isNotNull(finalResultSaving);
    } 
    
    @IsTest
    static void ProductsCalloutsServicesUtilError() {	
        String savingJsonResponse = '{ "savings": [ { "accountNumber": "619541564", "denomination": "NAME", "officeCode": "61", "status": "N", "statusChangeDate": "2024-03-08T03:00:00.000Z", "balance": { "amount": 18512, "avgAmount": 18512, "currency": { "code": "GS", "description": "GUARANIES" } }, "openingDate": "2024-03-08T03:00:00.000Z", "dueDate": null, "cancellationCodeCause": null, "rateCode": "92", "rateValue": null, "movements": [ { "accountNumber": "619541564", "personCode": null, "denomination": "NAME", "movementTypeCode": "D", "movementType": "Debito", "date": "2024-03-14T03:00:00.000Z", "userCode": "INFONET_2", "balance": { "amount": 35000, "currency": { "code": "GS", "description": "GUARANIES" } }, "officeCode": "61", "errorCode": null, "status": "N", "causeCode": null, "causeDescription": null, "bankDescription": "BANCO CONTINENTAL S.A.E.C.A.", "originOfficeDescription": "CASA MATRIZ", "concept": "PIZZA HUT-PLG", "rateCode": null, "rateValue": null, "categoryCode": null, "categoryDescription": null, "isReversed": "N", "reversionUserCode": null, "reversionTime": null, "hasIssuedNotice": "N", "parentTransaction": { "transactionDescription": "COMPRA EN NEGOCIOS (POS)" }, "transaction": { "transactionDescription": "EXTRACCIONES VIA TED" }, "documentNumber": 3739861403, "documentNumber2": null, "documentNumber3": 3739861403, "documentNumber4": 4, "isProtected": "S" } ] } ] }';
        
        SingleRequestMock fakeResponse = new SingleRequestMock(500,'Complete', savingJsonResponse, null);
        
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        test.startTest();
        string finalResultSaving = ProductsCalloutsServicesUtil.productJsonSavingsCallout('555', 'SAVINGS');
        test.stopTest();	
        Assert.isNotNull(finalResultSaving);
    }
    
    @isTest 
    static void testGetCalloutimeout() {
        String savingJsonResponse = '{ "savings": [ { "accountNumber": "619541564", "denomination": "NAME", "officeCode": "61", "status": "N", "statusChangeDate": "2024-03-08T03:00:00.000Z", "balance": { "amount": 18512, "avgAmount": 18512, "currency": { "code": "GS", "description": "GUARANIES" } }, "openingDate": "2024-03-08T03:00:00.000Z", "dueDate": null, "cancellationCodeCause": null, "rateCode": "92", "rateValue": null, "movements": [ { "accountNumber": "619541564", "personCode": null, "denomination": "NAME", "movementTypeCode": "D", "movementType": "Debito", "date": "2024-03-14T03:00:00.000Z", "userCode": "INFONET_2", "balance": { "amount": 35000, "currency": { "code": "GS", "description": "GUARANIES" } }, "officeCode": "61", "errorCode": null, "status": "N", "causeCode": null, "causeDescription": null, "bankDescription": "BANCO CONTINENTAL S.A.E.C.A.", "originOfficeDescription": "CASA MATRIZ", "concept": "PIZZA HUT-PLG", "rateCode": null, "rateValue": null, "categoryCode": null, "categoryDescription": null, "isReversed": "N", "reversionUserCode": null, "reversionTime": null, "hasIssuedNotice": "N", "parentTransaction": { "transactionDescription": "COMPRA EN NEGOCIOS (POS)" }, "transaction": { "transactionDescription": "EXTRACCIONES VIA TED" }, "documentNumber": 3739861403, "documentNumber2": null, "documentNumber3": 3739861403, "documentNumber4": 4, "isProtected": "S" } ] } ] }';
        
        SingleRequestMock fakeResponse = new SingleRequestMock(500,'timeOut',savingJsonResponse,null);
        Test.setMock(HttpCalloutMock.class, fakeResponse); 
        
        test.startTest();
        HttpHelper.doTimeOutExceptionWhenFalse = true;
        string finalResultSaving = ProductsCalloutsServicesUtil.productJsonSavingsCallout('555', 'SAVINGS');
        test.stopTest();	
        //Assert.isNotNull(finalResultSaving);
        
    }

    @isTest 
    static void testGetPicklistValues() {        
        test.startTest();
        Map<String,String> result = ProductsCalloutsServicesUtil.getPicklistValues('Account','DocumentType__c');
        test.stopTest();	
        //Assert.isNotNull(result);
        
    }
}