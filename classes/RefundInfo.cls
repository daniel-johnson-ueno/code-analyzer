public class RefundInfo {
    private static Map<String,Message_Client_Response_Refund_API__mdt> messToClientByResponse;
    public class RefundWrapper {
       	public String code;
        public String type;
        public String id;
        public String storeName;
        public String storeCode;
		public AmountWrapper amount;
		public List<OutputWrapper> outputs;
		public List<RejectionWrapper> rejections;
	}

	public class AmountWrapper {
    	public String value;
        public String currencyCode;
	}
            
	public class OutputWrapper {
		public String promotion_name;
		public PromotionWrapper promotion;
		public CashbackWrapper cashback;
		public List<StateWrapper> states;
	}
            
	public class RejectionWrapper {
		public String rejection_type;
	}
        
	public class StateWrapper {
		public String type;
		public String notDate;
	}
        
	public class CashbackWrapper {
		public Integer user_level;
		public PromotionWrapper promotion;
        public AmountWrapper amount;
	}
      
    
	public class PromotionWrapper {
		public Decimal cashback_percentage;
        public Decimal limit_accumulated_amount;
		public Decimal limit_purchase_amount;
        public Decimal accumulated_pre_cashback;
        public Decimal accumulated_post_cashback;
	}    
        
    public class FinalWrapper{
        @AuraEnabled
        public String codeError {get; set;}  
        @AuraEnabled
        public String errorType {get; set;}   
		@AuraEnabled
        public String Id {get; set;}  
        @AuraEnabled
        public String storeName {get; set;}   
        @AuraEnabled
        public String storeCode {get; set;}   
        @AuraEnabled
        public String verdict {get; set;} 
        @AuraEnabled
        public String approvalMessage {get; set;} 
        @AuraEnabled
        public String promotion {get; set;} 
        @AuraEnabled
        public String receiptAmount {get; set;} 
        @AuraEnabled
        public Decimal cashbackLimit {get; set;} 
        @AuraEnabled
        public String typeCashbackState {get; set;}
        @AuraEnabled
        public Decimal accumulatedCashback {get; set;}
        @AuraEnabled
        public Decimal totalLimitCashback {get; set;}
        @AuraEnabled
        public Integer userLevel {get; set;} 
        @AuraEnabled
        public String refundAmount {get; set;} 
        @AuraEnabled
        public Decimal cashback {get; set;} 
        @AuraEnabled
        public String cashbackDate {get; set;} 
        @AuraEnabled
        public String rejectionType {get; set;} 
        @AuraEnabled
        public String rejectionTypeCode {get; set;}
        @AuraEnabled
        public String currencyCode {get; set;}
        @AuraEnabled
        public String messageToClient {get; set;}
    }
    
    public static FinalWrapper parse(String jsonString, Map<String,String> rejectionMessageByrejectionType){
        Map<String,Message_Client_Response_Refund_API__mdt> messToClientByResponseApi;
        String jsonReplaced = jsonString.replace('"currency":', '"currencyCode":');
        jsonReplaced = jsonReplaced.replace('"date":', '"notDate":');
        RefundWrapper resp = (RefundWrapper)JSON.deserialize(jsonReplaced,RefundWrapper.class);
        FinalWrapper finalResponse = new FinalWrapper();
       	if(resp.type != null && resp.code != null ){
            finalResponse.errorType = resp.type;
            finalResponse.codeError = resp.code;
        }
        if(resp.id != null){
        	finalResponse.Id = resp.id;
        }
        if(resp.storeName != null && resp.storeCode != null){
        	finalResponse.storeName = resp.storeName;
            finalResponse.storeCode = resp.storeCode;
        }
        if(resp.amount != null){
            finalResponse.currencyCode = resp.amount.currencyCode;
        	finalResponse.receiptAmount = resp.amount.value;
        }
        if(resp.outputs != null  && !resp.outputs.isEmpty()){
            messToClientByResponseApi = getMessageToClient();
        	for(OutputWrapper output :resp.outputs){
            	if(output.promotion_name != null){
                	finalResponse.promotion = output.promotion_name;
                }
                if(output.cashback != null){
                	if(output.cashback.promotion.limit_purchase_amount != null){
                    	finalResponse.cashbackLimit = output.cashback.promotion.limit_purchase_amount;
                    }
                    if(output.cashback.promotion.accumulated_pre_cashback != null){
                    	finalResponse.accumulatedCashback = output.cashback.promotion.accumulated_pre_cashback;
                    }
                    if(output.cashback.promotion.cashback_percentage != null){
                    	finalResponse.cashback = output.cashback.promotion.cashback_percentage;
                    }
                    finalResponse.totalLimitCashback = output.cashback.promotion.accumulated_post_cashback;
                	}
                	if(output.cashback != null){
                    	if(output.cashback.user_level != null){
                        	finalResponse.userLevel = output.cashback.user_level;
                    	}
                    	if(output.cashback.amount != null){
                        	finalResponse.refundAmount = output.cashback.amount.value;
                    	}
                	}
                	if(output.states != null){
                        for(StateWrapper state :output.states){
                            if(finalResponse.cashbackDate == null || finalResponse.cashbackDate < state.notDate){
                                finalResponse.cashbackDate = state.notDate;
                                if(state.type == 'CASHBACK_ACKNOWLEDGED' || state.type == 'CASHBACK_CREATED'){
                            	finalResponse.typeCashbackState = state.type;
                                if(state.type == 'CASHBACK_CREATED'){
                                    finalResponse.approvalMessage = 'El reintegro está visible para el cliente pero aún no se ha procesado completamente.';
                                }else{
                                    finalResponse.approvalMessage = 'El reintegro ha sido reconocido y está en proceso de confirmación.';
                                }
                        	}else if(state.type == 'CASHBACK_VISIBLE'){
                            	finalResponse.typeCashbackState = state.type;
                                finalResponse.approvalMessage = 'El reintegro ha sido completado y está disponible para el cliente.';
                        	}
                            if(messToClientByResponseApi.get(finalResponse.typeCashbackState) != null){
                                finalResponse.messageToClient = messToClientByResponseApi.get(finalResponse.typeCashbackState).Response_Message__c;
                            	finalResponse.verdict = messToClientByResponseApi.get(finalResponse.typeCashbackState).Verdict__c;
                            }
                         }
                        }
                	}
            	}
        }else if(resp.rejections != null && !resp.rejections.isEmpty()){
            messToClientByResponseApi = getMessageToClient();
            for(RejectionWrapper rejection :resp.rejections){
               if(rejection.rejection_type != null){
                    finalResponse.rejectionType = rejectionMessageByrejectionType.get(rejection.rejection_type);
                    finalResponse.rejectionTypeCode = rejection.rejection_type;
                    if(messToClientByResponseApi.get(finalResponse.rejectionTypeCode) != null){
                        finalResponse.messageToClient = messToClientByResponseApi.get(finalResponse.rejectionTypeCode).Response_Message__c;
                    	finalResponse.verdict = messToClientByResponseApi.get(finalResponse.rejectionTypeCode).Verdict__c;
                    }
                }

      		}
        }else if(resp.amount != null){
            finalResponse.verdict = 'Reintegro pendiente a procesar';
        }
        return finalResponse;
    }        

    private static Map<String,Message_Client_Response_Refund_API__mdt> getMessageToClient(){
        if(messToClientByResponse == null){
            messToClientByResponse = new Map<String,Message_Client_Response_Refund_API__mdt>();
            for(Message_Client_Response_Refund_API__mdt mdt :[SELECT Response_API__c,Response_Message__c, Verdict__c  FROM Message_Client_Response_Refund_API__mdt]){
                messToClientByResponse.put(mdt.Response_API__c,mdt);
            }
        }
        return messToClientByResponse;
    }
}