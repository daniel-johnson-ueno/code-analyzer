@isTest
public class CaseRemoteSiteRefundManagerTest {
    @testSetup
    static void testSetup(){
        Ueno_Service_Domain__c testUrl= new Ueno_Service_Domain__c(ApiKey__c = '555-555-555',DomainName__c='https://kongcloud.ind-dev-sae1.ueno.com.py');
        insert testUrl;
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
    @isTest
    static void testGetAccountWithValidParameters() {
        String paymentMethod = 'TD';
        String operationNumber = '111111';
        Account account = TestFactory.createPersonAccount();
        Case caseObject = TestFactory.createCase('Escalado', 'Reclamo', account.Id);
        String responseMock = '{' +  
	'   "id": "QR4290781844",' +
	'   "transaction_code": "4290781844",' +
	'   "transaction_type": "QR",' +
	'   "date": "2025-01-20T00:00:00.000Z",' +
	'   "account_code": "4987134",' +
	'   "customer_id": "1461335",' +
	'   "store_data": ' +
    '{' +  
	'       "code": "1622",' +
	'       "composite_id": "11622",' +
	'       "branch_code": "1",' +
	'       "reference_code": "4290781844"'+
	'   },'+
	'   "amount":'+ 
	'   {' +  
	'       "currency": "GS",' +
	'       "value": "132600.00"'+
	'   },'+
	'   "rejections": '+
    '   ['+
	'       {' +  
	'           "rejection_type": "DISCARDED_BY_INPUT_RULES_OPERATION_TYPE",' +
	'           "description": "Last rules evaluated: operation.type in promotions 2qx5xJ7TKSsQWoyFV7LRX7eBR7t, 2qx5y5w5bVPcsZrHB4poeN5g0wR, 2qx60O0gGMtxOOzTvELMgjWIpcO, 2qx64WCAdCyYL58YH6GXlyyWN0Y",' +
	'           "date": "2025-01-20T23:44:10.969Z",' +
	'           "last_promotions_evaluated":'+
    '			 ['+
	'               "2qx5xJ7TKSsQWoyFV7LRX7eBR7t",' +
	'               "2qx5y5w5bVPcsZrHB4poeN5g0wR",' +
	'               "2qx60O0gGMtxOOzTvELMgjWIpcO",' +
	'               "2qx64WCAdCyYL58YH6GXlyyWN0Y"' +
	'               ]'+
	'        },'+
    '    	{' +  
	'           "rejection_type": "DISCARDED_BY_INPUT_RULES_OPERATION_TYPE",' +
	'           "description": "Last rules evaluated: operation.type in promotions 2qx5xJ7TKSsQWoyFV7LRX7eBR7t, 2qx5y5w5bVPcsZrHB4poeN5g0wR, 2qx60O0gGMtxOOzTvELMgjWIpcO, 2qx64WCAdCyYL58YH6GXlyyWN0Y",' +
	'           "date": "2025-01-20T23:44:10.969Z",' +
	'           "last_promotions_evaluated":'+
    '			 ['+
	'               "2qx5xJ7TKSsQWoyFV7LRX7eBR7t",' +
	'               "2qx5y5w5bVPcsZrHB4poeN5g0wR",' +
	'               "2qx60O0gGMtxOOzTvELMgjWIpcO",' +
	'               "2qx64WCAdCyYL58YH6GXlyyWN0Y"' +
	'               ]'+
	'        }'+
	'   ],'+
	'   "outputs":'+
    '	['+
	'       {' +  
	'           "type": "CASHBACK",' +
	'           "promotion_id": "2qz2plH5jU2Y4k55r6QfMkG7GIw",' +
	'           "promotion_name": "Petropar",' +
	'           "cashback":'+ 
	'           {' +  
	'               "conciliated": true,'+
	'               "amount":'+ 
	'                   {' +  
	'                       "currency": "GS",' +
	'                       "value": "5700.00"'+
	'                   },'+
	'               "user_level": 2,'+
	'               "promotion":'+ 
	'                   {' +  
	'                       "cashback_percentage": 20,'+
	'                       "limit_accumulated_amount": "80000.00",' +
	'                       "limit_purchase_amount": "400000.00",' +
	'                       "accumulated_pre_cashback": "74300.00",' +
	'                       "accumulated_post_cashback": "80000.00"'+
	'                   }'+
	'           },'+
	'           "states":'+
    '			 ['+
	'               {' +  
	'                   "type": "CASHBACK_ACKNOWLEDGED",' +
	'                   "date": "2025-01-28T21:09:06.218Z"'+
	'               },'+
	'               {' +  
	'                   "type": "CASHBACK_CREATED",' +
	'                   "date": "2025-01-28T21:08:51.853Z"'+
	'               }'+
	'           ]'+
	'       }'+
	'   ]'+
	'}';
        MockHttpCallOut fakeResponse = new MockHttpCallOut(200, 'Ok', responseMock);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Test.startTest();
        List<Case> casesToQuery = [SELECT Id FROM Case LIMIT 1];
        RefundInfo.FinalWrapper resp = CaseRemoteSiteRefundManager.getVoucherFromExternalService(paymentMethod, operationNumber, casesToQuery[0].Id);
        Test.stopTest();
       	Assert.areEqual(resp.Id,'QR4290781844','No se proceso correctamente la respuesta del servicio.');
    }
    @isTest
    static void testGetAccountWithInvalidParameters() {
        String paymentMethod = '';
        String operationNumber = '';
        Account account = TestFactory.createPersonAccount();
        Case caseObject = TestFactory.createCase('Escalado', 'Reclamo', account.Id);
        String responseMock = '{"code": 500, "type": "Internal error"}';
        MockHttpCallOut fakeResponse = new MockHttpCallOut(500, 'Internal server error', responseMock);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Test.startTest();
        List<Case> casesToQuery = [SELECT Id FROM Case LIMIT 1];
        RefundInfo.FinalWrapper resp = CaseRemoteSiteRefundManager.getVoucherFromExternalService(paymentMethod, operationNumber, casesToQuery[0].Id);
        Test.stopTest();
		Assert.areEqual(resp.errorType,'Internal error','No se proceso correctamente el error.');
    }
    @isTest
    static void testGetAccountWithParameters() {
        String paymentMethod = 'QR';
        String operationNumber = '99999999';
        Account account = TestFactory.createPersonAccount();
        Case caseObject = TestFactory.createCase('Escalado', 'Reclamo', account.Id);
        String responseMock = '{"code":400, "type": "Invalid paramater"}';
        MockHttpCallOut fakeResponse = new MockHttpCallOut(404, 'Not found', responseMock);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Test.startTest();
        List<Case> casesToQuery = [SELECT Id FROM Case LIMIT 1];
		RefundInfo.FinalWrapper resp = CaseRemoteSiteRefundManager.getVoucherFromExternalService(paymentMethod, operationNumber, casesToQuery[0].Id);
        Test.stopTest();
        Assert.areEqual(resp.errorType,'Invalid paramater','No se proceso correctamente el error.');
    }
}