public without sharing class RefundQueryController{
    
    @AuraEnabled
    public static RefundInfo.FinalWrapper checkRefundStatus(String PaymentMethod, String OperationNumber, String idCase){
        RefundInfo.FinalWrapper resultRefund;
        Case caseToUpdate;
        try {
            resultRefund = CaseRemoteSiteRefundManager.getVoucherFromExternalService(PaymentMethod, OperationNumber, idCase);
            if(resultRefund != null && idCase != null){
                caseToUpdate = searchCaseById(idCase);
                if(caseToUpdate != null && caseToUpdate.Refund_inquiry_made__c == false){
                    caseToUpdate.Refund_inquiry_made__c = true;
                    updateCase(caseToUpdate);
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return resultRefund;
    }
    
    @AuraEnabled
    public static void relateReceipts(List<RefundInfo.FinalWrapper> receipts, Id caseId){
        List<Related_movements__c> relatedMovements = new List<Related_movements__c>();
        Boolean hasRelatedMovement = false;
        Case caseToRelated;
        String infoRelatedRefunds;
        try {
            if(!receipts.isEmpty() && caseId != null){
                for(RefundInfo.FinalWrapper receipt :receipts){
                    relatedMovements.add(createRecord(receipt,caseId));
                    if(receipt.Id != null && (receipt.typeCashbackState != null || receipt.rejectionTypeCode != null)){
                        String infoRefund = receipt.typeCashbackState != null ? receipt.typeCashbackState : receipt.rejectionTypeCode;
                        if(infoRelatedRefunds != null){
                            infoRelatedRefunds = infoRelatedRefunds + receipt.Id + ':'+ infoRefund + ';';
                        }else{
                            infoRelatedRefunds = receipt.Id + ':'+ infoRefund + ';';
                        }                       
                    }
                }
                if(!relatedMovements.isEmpty()){
                    List<Database.SaveResult> dbResults = Database.insert(relatedMovements,false);
                    for (Database.SaveResult result : dbResults) {
                        if (result.isSuccess() && hasRelatedMovement == false) {
                            hasRelatedMovement = true;
                        }
                    }        
                    if(hasRelatedMovement == true){
                        caseToRelated = searchCaseById(caseId);
                        if(caseToRelated.Has_related_movements__c == false){
                            caseToRelated.Has_related_movements__c  = true;	
                        }
                        if(infoRelatedRefunds != null){
                        	if(caseToRelated.InformationRelatedRefunds__c != null ){
                            	caseToRelated.InformationRelatedRefunds__c = caseToRelated.InformationRelatedRefunds__c + infoRelatedRefunds;
                        	}else{
                            	caseToRelated.InformationRelatedRefunds__c = infoRelatedRefunds;
                        	}
                        }    
                        updateCase(caseToRelated);
                    }  
                   
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    private static Related_movements__c createRecord(RefundInfo.FinalWrapper receipt, Id caseId){
        Related_movements__c movement;
        String refundLimit = String.valueOf(receipt.cashbackLimit);
        String level = String.valueOf(receipt.userLevel);
        Map<String, Object> fieldMap = new Map<String, Object>{
            'TransferStatus__c' => receipt.verdict,
                'Promotion__c' => receipt.promotion,
                'Amount__c' => receipt.receiptAmount,
                'Receipt_Number__c' => receipt.Id,
                'Refund_limit__c' => refundLimit,
                'AccumulatedAmount__c' => receipt.accumulatedCashback,
                'TotalRefundLimit__c' => receipt.totalLimitCashback,
                'Refund_date__c' => receipt.cashbackDate,
                'ErrorMessage__c' => receipt.rejectionType,
                'Level__c' => level,
                'Cashback_percentage__c' => receipt.cashback
                }; 
                    if(receipt != null){
                        movement = new Related_movements__c();
                        for(String fieldName :fieldMap.keySet()){
                            if(fieldMap.get(fieldName) != null){
                                movement.put(fieldName, fieldMap.get(fieldName));
                            }
                        }
                        if(movement.TransferStatus__c != null){
                            String recordTypeId = Schema.SObjectType.Related_movements__c.getRecordTypeInfosByName().get('Reintegros').getRecordTypeId();
                            movement.RecordTypeId = recordTypeId;
                            movement.MovementType__c = 'Reintegro';
                        }
                        if(caseId != null){
                            movement.Case__c = caseId;
                        }    
                    }
        return movement;
    }    
    
    private static Case searchCaseById(String caseId){
        Case caseToUpdate;
        List<Case> cases = [SELECT Id,Refund_inquiry_made__c, Has_related_movements__c, InformationRelatedRefunds__c FROM Case WHERE Id = :Id.valueOf(caseId)];
        if(!cases.isEmpty()){
            caseToUpdate = cases[0];
        }
        return caseToUpdate;
    }
    
    private static void updateCase(Case caseToUpdate){
        Database.SaveResult resultDB;
        if(caseToUpdate != null){
            resultDB = Database.update(caseToUpdate, false);
        }
    }
}