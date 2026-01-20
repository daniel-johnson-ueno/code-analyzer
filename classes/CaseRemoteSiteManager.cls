public class CaseRemoteSiteManager {
    @future (callout=true)
    public static void getVoucherFromExternalService(String PaymentMethod, String OperationNumber, Id idCase) {
        Map<String, Object> parsedResponse = new Map<String, Object>();
        try{
            HttpResponse res = CaseRemoteSiteConection.getVoucher(PaymentMethod, OperationNumber,idCase);
            System.debug(res);
            if(res!=null){
                String jsonString = res.getBody();
                System.debug('/////JSON DEBUG////');
                System.debug(jsonString);
                System.debug(res.getStatusCode());
                parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
                CaseRemoteSiteManager.updateCase(parsedResponse, idCase);
            }
        } catch (Exception e){
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'CaseRemoteSiteManager', 'getVoucherFromExternalService');
        }
    }
    private static void updateCase(Map<String, Object> parsedResponse, Id idCase){
        Case objCaseToUpdate = [SELECT Id, Voucher_amount__c, Store_Name__c FROM Case WHERE Id =: idCase];
        objCaseToUpdate.Store_Name__c= String.valueOf(parsedResponse.get('storeName'));
        objCaseToUpdate.Store_Code__c= String.valueOf(parsedResponse.get('storeCode'));
        objCaseToUpdate.Voucher_amount__c = Integer.valueOf(parsedResponse.get('amount'));
        
        List<Case> lstCasesToUpdate = new List<Case>{objCaseToUpdate};
        AsyncDMLOperationsUtility asyncDML = new AsyncDMLOperationsUtility(lstCasesToUpdate, 'update');
        System.enqueueJob(asyncDML);
        
    }
}