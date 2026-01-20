@isTest
public class ClusterInformationControllerTest {

    @TestSetup static void setup() {
        Ueno_Service_Domain__c uenoDomain = TestFactory.createDomain();
        Account account = TestFactory.createPersonAccount();
    }

    @isTest
    static void testClusterCallout() {
        String clusterResponseJSON = '{"clusterName":"SIN MOVIMIENTOS EN CAH"}';
        SingleRequestMock fakeResponse = new SingleRequestMock(200,'Complete', clusterResponseJSON, null);
        Account acct = [SELECT Id, UniqueId__c FROM Account LIMIT 1];
        acct.UniqueId__c = '12345678-0000-0000-0000-000000000000';
        update acct;
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Test.startTest();
            ClusterInformationController.ClusterInfoWrapper result = ClusterInformationController.clusterCallout(acct.Id);        
        Test.stopTest();
        System.assertEquals('SIN MOVIMIENTOS EN CAH', result.cluster, 'Cluster should match the mock response');
        System.assertEquals(false, result.hasError, 'Result should not have an error');
    }

    @isTest
    static void testClusterCalloutEmptyUniqueId() {
        String clusterResponseJSON = '{"clusterName":"SIN MOVIMIENTOS EN CAH"}';
        SingleRequestMock fakeResponse = new SingleRequestMock(200,'Complete', clusterResponseJSON, null);
        Account acct = [SELECT Id, UniqueId__c FROM Account LIMIT 1];
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Test.startTest();
            ClusterInformationController.ClusterInfoWrapper result = ClusterInformationController.clusterCallout(acct.Id);        
        Test.stopTest();
        System.assertEquals(true, result.hasError, 'Result should have an error');
    }

    @isTest
    static void testClusterCalloutError400() {
        String clusterResponseJSON = '{"Error":"Service Error."}';
        SingleRequestMock fakeResponse = new SingleRequestMock(400,'Error', clusterResponseJSON, null);
        Account acct = [SELECT Id, UniqueId__c FROM Account LIMIT 1];
        acct.UniqueId__c = '12345678-0000-0000-0000-000000000000';
        update acct;
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Test.startTest();
            ClusterInformationController.ClusterInfoWrapper result = ClusterInformationController.clusterCallout(acct.Id);        
        Test.stopTest();
        System.assertEquals(true, result.hasError, 'Result should have an error');
    }
}