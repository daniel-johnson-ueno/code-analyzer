/**
 * @description       : 
 * @author            : marco.casanova@vurpix.com
 * @TKs               : 
 * @group             : 
 * @last modified on  : 05-22-2024
 * @last modified by  : marco.casanova@vurpix.com
**/
@isTest
public class ProductsMovementsCalloutsTest {
    @TestSetup static void setup() {
        Ueno_Service_Domain__c uenoDomain = (Ueno_Service_Domain__c)TestFactoryFramework.createSObject(new Ueno_Service_Domain__c(), 'TestFactoryFrameworkDefaults.UenoServiceDomainDefaults', true);
        Account account = (Account)TestFactoryFramework.createSObject(new Account(), 'TestFactoryFrameworkDefaults.PersonAccountDefaults', true);
        Case caseObject = (Case)TestFactoryFramework.createSObject(new Case(), 'TestFactoryFrameworkDefaults.ConsultaCaseDefaults', false);
        caseObject.AccountId = account.id;
        caseObject.Status = 'Escalado';
        insert caseObject;

    }
    @IsTest
    static void ProductsCalloutsServicesUtilSuccessSavings() {	
        String savingResponseJSON = '{ "offset": 0, "limit": 25, "results": [{"movementType":"Deposit","date":"2024-03-19T10:15:23.000Z","status":"Completed","concept":"Salary","balance":{"amount":5000,"currency":{"description":"United States Dollar","code":"USD"}}},{"movementType":"Withdrawal","date":"2024-03-20T14:30:45.000Z","status":"Pending","concept":"Rent","balance":{"amount":1200,"currency":{"description":"United States Dollar","code":"USD"}}},{"movementType":"Transfer","date":"2024-03-21T09:45:12.000Z","status":"Completed","concept":"Gift","balance":{"amount":300,"currency":{"description":"United States Dollar","code":"USD"}}},{"movementType":"Payment","date":"2024-03-22T08:00:00.000Z","status":"Completed","concept":"Utility bill","balance":{"amount":150,"currency":{"description":"United States Dollar","code":"USD"}}},{"movementType":"Deposit","date":"2024-03-23T16:20:30.000Z","status":"Completed","concept":"Bonus","balance":{"amount":1000,"currency":{"description":"United States Dollar","code":"USD"}}}]}';
        
        SingleRequestMock fakeResponse = new SingleRequestMock(200,'Complete', savingResponseJSON, null);
        
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Test.startTest();
        String finalResultSaving = ProductsMovementsCalloutsServicesUtil.productMovementCallout('555', 'SAVINGS', '1', '5', '', '','', '');
        Test.stopTest();
        //Assert.isNotNull(finalResultSaving);
    }
    
    @IsTest
    static void ProductsCalloutsServicesUtilSuccessCredit() {	
        String creditResponseJSON = '{ "offset": 0, "limit": 25, "results": [{"type":"CONSUMO","date":"2024-05-13T08:00:00","description":"Compra de alimentos","currency":{"code":"USD"},"amount":20},{"type":"CONSUMO","date":"2024-05-13T12:30:00","description":"Gasolina para el auto","currency":{"code":"USD"},"amount":50},{"type":"CONSUMO","date":"2024-05-12T15:45:00","description":"Compras en línea","currency":{"code":"USD"},"amount":75}]}';
        
        SingleRequestMock fakeResponse = new SingleRequestMock(200,'Complete', creditResponseJSON, null);
        
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Test.startTest();
        String finalResultSaving = ProductsMovementsCalloutsServicesUtil.productMovementCallout('555', 'CREDIT_CARDS', '1', '5', '', '','', '');
        Test.stopTest();
        //Assert.isNotNull(finalResultSaving);
    }
    
    @IsTest
    static void ProductsCalloutsServicesUtilSuccessLoans() {	
        String installmentResponseJSON = '{"offset": 0, "limit": 25, "results": [{"installmentNumber":0,"expirationDate":"2024-03-19T10:15:23.000Z","status":"pending","amount":1234.56,"currency":{"description":"United States Dollar","code":"USD"},"paymentDate":"2024-03-19T10:15:23.000Z","daysPastDueDesc":5},{"installmentNumber":1,"expirationDate":"2024-03-20T10:15:23.000Z","status":"pending","amount":2000.00,"currency":{"description":"United States Dollar","code":"USD"},"paymentDate":"2024-03-20T10:15:23.000Z","daysPastDueDesc":10},{"installmentNumber":2,"expirationDate":"2024-03-21T10:15:23.000Z","status":"pending","amount":3000.00,"currency":{"description":"United States Dollar","code":"USD"},"paymentDate":"2024-03-21T10:15:23.000Z","daysPastDueDesc":15}]}';
        
        SingleRequestMock fakeResponse = new SingleRequestMock(200,'Complete', installmentResponseJSON, null);
        
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Test.startTest();
        String finalResultSaving = ProductsMovementsCalloutsServicesUtil.productMovementCallout('555', 'LOANS', '1', '5', '', '','', '');
        Test.stopTest();
        //Assert.isNotNull(finalResultSaving);
    }
    @IsTest
    static void ProductsCalloutsServicesUtilErrorSavings() {	
        String savingResponseJSON = '{ "offset": 0, "limit": 25, "results": [{"movementType":"Deposit","date":"2024-03-19T10:15:23.000Z","status":"Completed","concept":"Salary","balance":{"amount":5000,"currency":{"description":"United States Dollar","code":"USD"}}},{"movementType":"Withdrawal","date":"2024-03-20T14:30:45.000Z","status":"Pending","concept":"Rent","balance":{"amount":1200,"currency":{"description":"United States Dollar","code":"USD"}}},{"movementType":"Transfer","date":"2024-03-21T09:45:12.000Z","status":"Completed","concept":"Gift","balance":{"amount":300,"currency":{"description":"United States Dollar","code":"USD"}}},{"movementType":"Payment","date":"2024-03-22T08:00:00.000Z","status":"Completed","concept":"Utility bill","balance":{"amount":150,"currency":{"description":"United States Dollar","code":"USD"}}},{"movementType":"Deposit","date":"2024-03-23T16:20:30.000Z","status":"Completed","concept":"Bonus","balance":{"amount":1000,"currency":{"description":"United States Dollar","code":"USD"}}}]}';
        
        SingleRequestMock fakeResponse = new SingleRequestMock(500,'Error', savingResponseJSON, null);
        
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Test.startTest();
        String finalResultSaving = ProductsMovementsCalloutsServicesUtil.productMovementCallout('555', 'SAVINGS', '1', '5', '', '','', '');
        Test.stopTest();
        //Assert.isNotNull(finalResultSaving);
    }
    
    @isTest 
    static void testGetCalloutimeout() {
        String savingResponseJSON = '{ "offset": 0, "limit": 25, "results": [{"movementType":"Deposit","date":"2024-03-19T10:15:23.000Z","status":"Completed","concept":"Salary","balance":{"amount":5000,"currency":{"description":"United States Dollar","code":"USD"}}},{"movementType":"Withdrawal","date":"2024-03-20T14:30:45.000Z","status":"Pending","concept":"Rent","balance":{"amount":1200,"currency":{"description":"United States Dollar","code":"USD"}}},{"movementType":"Transfer","date":"2024-03-21T09:45:12.000Z","status":"Completed","concept":"Gift","balance":{"amount":300,"currency":{"description":"United States Dollar","code":"USD"}}},{"movementType":"Payment","date":"2024-03-22T08:00:00.000Z","status":"Completed","concept":"Utility bill","balance":{"amount":150,"currency":{"description":"United States Dollar","code":"USD"}}},{"movementType":"Deposit","date":"2024-03-23T16:20:30.000Z","status":"Completed","concept":"Bonus","balance":{"amount":1000,"currency":{"description":"United States Dollar","code":"USD"}}}]}';
        
        SingleRequestMock fakeResponse = new SingleRequestMock(500,'timeOut',savingResponseJSON,null);
        Test.setMock(HttpCalloutMock.class, fakeResponse); 
        
        Test.startTest();
        HttpHelper.doTimeOutExceptionWhenFalse = true;
        String finalResultSaving = ProductsMovementsCalloutsServicesUtil.productMovementCallout('555', 'SAVINGS', '1', '5', '', '','', '');
        Test.stopTest();
        //Assert.isNotNull(finalResultSaving);
        
    }

    @IsTest
    static void ProductsCalloutsServicesUtilSuccessSavingsMovementType() {	
        String savingResponseJSON = '{ "offset": 0, "limit": 25, "results": [{"movementTypeCode":"D","movementType":"Debito","date":"2024-03-19T10:15:23.000Z","status":"Completed","concept":"Salary","balance":{"amount":5000,"currency":{"description":"United States Dollar","code":"USD"}}},{"movementType":"Withdrawal","date":"2024-03-20T14:30:45.000Z","status":"Pending","concept":"Rent","balance":{"amount":1200,"currency":{"description":"United States Dollar","code":"USD"}}},{"movementType":"Transfer","date":"2024-03-21T09:45:12.000Z","status":"Completed","concept":"Gift","balance":{"amount":300,"currency":{"description":"United States Dollar","code":"USD"}}},{"movementType":"Payment","date":"2024-03-22T08:00:00.000Z","status":"Completed","concept":"Utility bill","balance":{"amount":150,"currency":{"description":"United States Dollar","code":"USD"}}},{"movementType":"Deposit","date":"2024-03-23T16:20:30.000Z","status":"Completed","concept":"Bonus","balance":{"amount":1000,"currency":{"description":"United States Dollar","code":"USD"}}}]}';
        
        SingleRequestMock fakeResponse = new SingleRequestMock(200,'Complete', savingResponseJSON, null);
        
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Test.startTest();
        String finalResultSaving = ProductsMovementsCalloutsServicesUtil.productMovementCallout('555', 'SAVINGS', '1', '5', '', '','D', '');
        Test.stopTest();
        //Assert.isNotNull(finalResultSaving);
    }
    
    @IsTest
    static void ProductsCalloutsServicesUtilSuccessSavingsErrorMessage() {	
        String savingResponseJSON = '{ "offset": 0, "limit": 100, "results": [ { "accountNumber": "611107638", "denomination": "XXXX XXXX XXXX XXXX", "movementTypeCode": "D", "movementType": "Debito", "date": "2023-12-06 07:59:27-03:00", "userCode": "SIPAPD", "balance": { "amount": 836.0, "currency": { "code": "USD" } }, "officeCode": "61", "status": "N", "originOfficeDescription": "CASA MATRIZ", "concept": "HB-Trx. via BCP Nro231206245559", "isReversed": false, "hasIssuedNotice": true, "parentTransaction": { "transactionDescription": "TRANSFERENCIA INTERBANCARIA" }, "transaction": { "transactionDescription": "DEBITO EN CAJA DE AHORRO" }, "documentNumber": "231206245559", "documentNumber2": "103001002", "documentNumber4": "178", "isProtected": true, "insertedBy": "XXXX XXXX XXXX XXXX", "transfer": { "referenceNumber": 231206245559, "status": "Cancelado", "situation": "Pendiente de Envío al BCP", "errorMessage": "Cuenta con Saldo Insuficiente p/ el debito de USD 836-31 Ref.: 231206245559", "rejectionType": "003" }, "couponDate": "2023-12-06" }]}';
        SingleRequestMock fakeResponse = new SingleRequestMock(200,'Complete', savingResponseJSON, null);
        
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Test.startTest();
        String finalResultSaving = ProductsMovementsCalloutsServicesUtil.productMovementCallout('555', 'SAVINGS', '1', '5', '', '','D', '');
        Test.stopTest();
        //Assert.isNotNull(finalResultSaving);
    }

    @IsTest
    static void ProductsCalloutsServicesUtilSuccessSavingBeneficiary() {	
        String savingResponseJSON = '{ "offset": 0, "limit": 100, "results": [ { "accountNumber": "611107638", "denomination": "XXXX XXXX XXXX XXXX", "movementTypeCode": "D", "movementType": "Debito", "date": "2023-12-06 07:59:27-03:00", "userCode": "SIPAPD", "balance": { "amount": 836.0, "currency": { "code": "USD" } }, "officeCode": "61", "status": "N", "originOfficeDescription": "CASA MATRIZ", "concept": "HB-Trx. via BCP Nro231206245559", "isReversed": false, "hasIssuedNotice": true, "parentTransaction": { "transactionDescription": "TRANSFERENCIA INTERBANCARIA" }, "transaction": { "transactionDescription": "DEBITO EN CAJA DE AHORRO" }, "documentNumber": "231206245559", "documentNumber2": "103001002", "documentNumber4": "178", "isProtected": true, "insertedBy": "XXXX XXXX XXXX XXXX", "transfer": { "referenceNumber": 231206245559, "status": "Cancelado", "situation": "Pendiente de Envío al BCP", "errorMessage": "Cuenta con Saldo Insuficiente p/ el debito de USD 836-31 Ref.: 231206245559", "rejectionType": "003", "beneficiaryPersonCode": "968041","beneficiaryAccountNumber": "619345478","beneficiaryDocumentTypeCode": "1", "beneficiaryDocumentNumber": "3835435","beneficiaryName": "Andrea ruiz" }, "couponDate": "2023-12-06" }]}';
        SingleRequestMock fakeResponse = new SingleRequestMock(200,'Complete', savingResponseJSON, null);
        
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Test.startTest();
        String finalResultSaving = ProductsMovementsCalloutsServicesUtil.productMovementCallout('555', 'SAVINGS', '1', '5', '', '','D', '');
        Test.stopTest();
        //Assert.isNotNull(finalResultSaving);
    }

    @IsTest
    static void ProductsCalloutsServicesUtilCreateRelatedMovementRecord() {	
        String caseId = [SELECT Id from Case LIMIT 1].Id;
        ProductsMovementsCalloutsServicesUtil.RelatedMovementsWrapper wrapper = new ProductsMovementsCalloutsServicesUtil.RelatedMovementsWrapper();
        wrapper.rowMovementType = 'SAVINGS';
        wrapper.movementDate = '12/12/24';
        wrapper.movementType = 'Debito';
        wrapper.amount = '123';
        wrapper.concept = 'Test';
        wrapper.parentTransaction = 'Test';
        wrapper.referenceNumber = '123';
        wrapper.childTransaction = 'Child Test';
        wrapper.transferStatus = 'Aprobado';
        wrapper.insertedBy = 'Test';
        wrapper.situation = 'Test';
        wrapper.documentNumber = '2342212';
        wrapper.couponDate = null;
        wrapper.errorMessage = 'Error Test';
        wrapper.description = 'description';

        Test.startTest();
            String result = ProductsMovementsCalloutsServicesUtil.createRelatedMovementRecord(caseId,'55555','SAVINGS', 'GS', wrapper);
        Test.stopTest();
        System.assertNotEquals('', result, 'No se esta creando la movimiento relacionado.');
    }

    @IsTest
    static void ProductsCalloutsServicesUtilCreateRelatedMovementRecordHasPermissionError() {	
        String caseId = [SELECT Id from Case LIMIT 1].Id;
        ProductsMovementsCalloutsServicesUtil.RelatedMovementsWrapper wrapper = new ProductsMovementsCalloutsServicesUtil.RelatedMovementsWrapper();
        wrapper.rowMovementType = 'SAVINGS';
        wrapper.movementDate = '12/12/24';
        wrapper.movementType = 'Debito';
        String result = '';
        Test.startTest();
            User userTest = [SELECT Id FROM User WHERE Profile.Name <> 'System Administrator' AND Profile.Name <> null AND IsActive = true LIMIT 1];
            System.runAs(userTest){
                result = ProductsMovementsCalloutsServicesUtil.createRelatedMovementRecord(caseId,'55555','SAVINGS', 'GS', wrapper);
            }
        Test.stopTest();
        Assert.areEqual(Label.permissionErrorMsgRelatedMovements, result, 'No se esta creando la movimiento relacionado.');
    }

    @IsTest
    static void ProductsCalloutsServicesUtilLoanMovementRecord() {	
        String caseId = [SELECT Id from Case LIMIT 1].Id;
        ProductsMovementsCalloutsServicesUtil.Installments wrapper = new ProductsMovementsCalloutsServicesUtil.Installments();
        wrapper.amount = '123';
        wrapper.currencyCode = 'GS';
        wrapper.status = 'Valido';
        wrapper.description = 'Description';
        wrapper.expirationDate = '12/12/24';
        wrapper.installmentNumber = '3';
        wrapper.daysPastDueDesc = '3';
        wrapper.paymentDate = null;
        wrapper.installmentId = 1;

        Test.startTest();
            String result = ProductsMovementsCalloutsServicesUtil.createRelatedLoanMovementRecord(caseId,'55555', 'GS', wrapper);
        Test.stopTest();
        System.assertNotEquals('', result, 'No se esta creando la movimiento relacionado.');
    }

    @IsTest
    static void ProductsCalloutsServicesUtilCreateRelatedMovementRecordHL() {	
        String caseId = [SELECT Id from Case LIMIT 1].Id;
        ProductsMovementsCalloutsServicesUtil.RelatedMovementsWrapper wrapper = new ProductsMovementsCalloutsServicesUtil.RelatedMovementsWrapper();
        wrapper.recordDate = '2/12/24';
        wrapper.level = '1';
        wrapper.minimumPoints = '10';
        wrapper.maximumPoints = '100';

        Test.startTest();
            String result = ProductsMovementsCalloutsServicesUtil.createRelatedHistoryLevelMovementRecord(caseId,'History Level', wrapper);
        Test.stopTest();
        System.assertNotEquals('', result, 'No se esta creando la movimiento relacionado.');
    }

    @IsTest
    static void ProductsCalloutsServicesUtilCreateRelatedMovementRecordHP() {	
        String caseId = [SELECT Id from Case LIMIT 1].Id;
        ProductsMovementsCalloutsServicesUtil.RelatedMovementsWrapper wrapper = new ProductsMovementsCalloutsServicesUtil.RelatedMovementsWrapper();
        wrapper.recordDate = '2/12/24';
        wrapper.movementReason = 'Aplica TC';
        wrapper.points = '150';

        Test.startTest();
            String result = ProductsMovementsCalloutsServicesUtil.createRelatedhistoryPointsMovementRecord(caseId,'History Points', wrapper);
        Test.stopTest();
        System.assertNotEquals('', result, 'No se esta creando la movimiento relacionado.');
    }
    
}