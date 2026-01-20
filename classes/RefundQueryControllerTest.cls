@isTest
private class RefundQueryControllerTest{
    
    @testSetup 
    static void setup() {
        Account accountObject = (Account)TestFactoryFramework.createSObject(new Account(), 'TestFactoryFrameworkDefaults.InternalCompanyAccountDefaults', false);
        accountObject.Name = 'Test Account';
        insert accountObject;
        
        Case caseObject = (Case)TestFactoryFramework.createSObject(new Case(), 'TestFactoryFrameworkDefaults.ConsultaCaseDefaults', false);
        caseObject.AccountId = accountObject.id;
        caseObject.Origin = 'Turnero';
        caseObject.Status = 'Nuevo';
        caseObject.Subject = '';
        caseObject.Description = 'Test Case';
        insert caseObject;
    }
    
    /**
     * Description: Prueba para el metodo checkRefundStatus con respuesta exitosa.
     */
    @isTest
    public static void checkRefundStatusSuccessTest() {
        String paymentMethod = 'TD';
        String operationNumber = '111111';
        String responseMock = '{' +  
        '   "id": "QR4290781844",' +
        '   "transaction_code": "4290781844",' +
        '   "transaction_type": "QR",' +
        '   "date": "2025-01-20T00:00:00.000Z",' +
        '   "account_code": "4987134",' +
        '   "customer_id": "1461335"' +
        '}';
        MockHttpCallOut fakeResponse = new MockHttpCallOut(200, 'Ok', responseMock);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Test.startTest();
        List<Case> casesToQuery = [SELECT Id FROM Case LIMIT 1];
        RefundInfo.FinalWrapper resp = RefundQueryController.checkRefundStatus(paymentMethod,operationNumber,casesToQuery[0].Id);
        Test.stopTest();
        List<Case> updatedCase = [SELECT Id, Refund_inquiry_made__c FROM Case WHERE Id = :casesToQuery[0].Id];
        Assert.areEqual(true,updatedCase[0].Refund_inquiry_made__c,'No se actualizo correctamente el caso.');
    }    

    /**
     * Description: Test para el metodo relateReceipts
     */
   	@isTest
    public static void relateReceiptsTest(){
        List<RefundInfo.FinalWrapper > wrappers = new List<RefundInfo.FinalWrapper >();
        RefundInfo.FinalWrapper finalWrapper = new RefundInfo.FinalWrapper();
        finalWrapper.Id = 'QR32545121';
        finalWrapper.verdict = 'Reintegro realizado';
        finalWrapper.promotion = 'Petropar';
        finalWrapper.receiptAmount = 'GS 132600.00';
        finalWrapper.cashbackLimit = 132600;
        finalWrapper.userLevel = 2;
        finalWrapper.refundAmount = '5700';
        finalWrapper.cashback = 20;
        finalWrapper.cashbackDate = String.valueOf(Datetime.now());
        finalWrapper.typeCashbackState = 'CASHBACK_VISIBLE';
        RefundInfo.FinalWrapper finalWrapperRejection = new RefundInfo.FinalWrapper();
        finalWrapperRejection.Id = 'QR32545122';
        finalWrapperRejection.verdict = 'Reintegro rechazado';
        finalWrapperRejection.rejectionType = 'Tipo de pago de la operación no válida';
        finalWrapperRejection.rejectionTypeCode = 'DISCARDED_BY_INPUT_RULES_OPERATION_TYPE';
        wrappers.add(finalWrapper);
        wrappers.add(finalWrapperRejection);
        Test.startTest();
        List<Case> casesToQuery = [SELECT Id FROM Case LIMIT 1];
        RefundQueryController.relateReceipts(wrappers,casesToQuery[0].id);
        Test.stopTest();
        List<Related_movements__c> movements = [SELECT Id, Case__c FROM Related_movements__c WHERE Case__c = :casesToQuery[0].id];
        List<Case> cases = [SELECT Id, Has_related_movements__c FROM Case WHERE Id = :casesToQuery[0].id];
        Assert.areEqual(2,movements.size(),'No se crearon correctamente los registros de movimientos relacionados.');
        Assert.areEqual(true,cases[0].Has_related_movements__c,'No se actualizo correctamente el caso.');
    }
}