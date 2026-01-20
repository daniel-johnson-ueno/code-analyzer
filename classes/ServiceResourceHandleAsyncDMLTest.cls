@isTest
public with sharing class ServiceResourceHandleAsyncDMLTest {
    @isTest
    private static void executeInsertTest() {
        ServiceResource objServiceResources = new ServiceResource(
            Name = 'test_Insert', 
            RelatedRecordId = UserInfo.getUserId()
        );
        ServiceResourceHandleAsyncDML.Requests request = new ServiceResourceHandleAsyncDML.Requests();
        request.objServiceResources = objServiceResources;
        request.strDMLOpperation = 'insert';
        List<ServiceResourceHandleAsyncDML.Requests> lstRequest = new List<ServiceResourceHandleAsyncDML.Requests>{ request };
        Test.startTest();
        List<ServiceResourceHandleAsyncDML.Results> lstResults = ServiceResourceHandleAsyncDML.execute(lstRequest);
        Test.stopTest();
    }
    @isTest
    private static void executeUpdateTest() {
        ServiceResource objServiceResources = new ServiceResource(
            Name = 'test_Update',
            RelatedRecordId = UserInfo.getUserId()
        );
        insert objServiceResources;
        objServiceResources.CI__c= '1234879';
        ServiceResourceHandleAsyncDML.Requests request = new ServiceResourceHandleAsyncDML.Requests();
        request.objServiceResources = objServiceResources;
        request.strDMLOpperation = 'update';
        List<ServiceResourceHandleAsyncDML.Requests> lstRequest = new List<ServiceResourceHandleAsyncDML.Requests>{ request };
        Test.startTest();
        List<ServiceResourceHandleAsyncDML.Results> lstResults = ServiceResourceHandleAsyncDML.execute(lstRequest);
        Test.stopTest();
    }
}