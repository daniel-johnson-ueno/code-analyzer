public class CaseRemoteSiteRefundManager {
    public static Map<String,String> rejectionMessageByrejectionType = new Map<String,String>();
    
    public static RefundInfo.FinalWrapper getVoucherFromExternalService(String PaymentMethod, String OperationNumber, String idCase) {
        rejectionMessageByrejectionType.put('TRANSACTION_STORE_NOT_FOUND','No existe el store cargado en el motor');
        rejectionMessageByrejectionType.put('TRANSACTION_CUSTOMER_WITHOUT_LOYALTY','Usuario no tiene Loyalty');
        rejectionMessageByrejectionType.put('EMPTY_PROMOTIONS_LIST','No hay promoción vigente en el motor de beneficios');
        rejectionMessageByrejectionType.put('DISCARDED_BY_INPUT_RULES_OPERATION_TYPE','Tipo de pago de la operación no válida');
        rejectionMessageByrejectionType.put('DISCARDED_BY_INPUT_RULES_OPERATION_AMOUNT','Monto de la operación no válida');
        rejectionMessageByrejectionType.put('DISCARDED_BY_INPUT_RULES_OPERATION_STORE','Comercio no está adherido a la promoción');
        rejectionMessageByrejectionType.put('DISCARDED_BY_INPUT_RULES_OPERATION_STORE_BRAND','Comercio no está adherido a la promoción');
        rejectionMessageByrejectionType.put('DISCARDED_BY_OUTPUT_RULES_PERSON_LOYALTY','Usuario no tiene Loyalty');
        rejectionMessageByrejectionType.put('DISCARDED_BY_OUTPUT_RULES_OPERATION_TYPE','Tipo de pago de la operación no válida');
        rejectionMessageByrejectionType.put('DISCARDED_BY_OUTPUT_RULES_CUSTOMER_ACCUMULATED_CASHBACK_AMOUNT','Llegó al tope del acumulado de la promoción');
        rejectionMessageByrejectionType.put('DISCARDED_BY_OUTPUT_RULES_CUSTOMER_ACCUMULATED_TOTAL_AMOUNT','Llegó al tope acumulado de la compra');
        RefundInfo.FinalWrapper finalWrapper = new RefundInfo.FinalWrapper();
        try{
            HttpResponse res = CaseRemoteSiteConection.getVoucher(PaymentMethod, OperationNumber, idCase);
            if(res!=null){
                String jsonString = res.getBody();
                finalWrapper =  RefundInfo.parse(jsonString,rejectionMessageByrejectionType);
            }
        } catch (Exception e){
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'CaseRemoteSiteManager', 'getVoucherFromExternalService');
        } 
        return finalWrapper; 
    }
}