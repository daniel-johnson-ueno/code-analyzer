public class CaseGetVoucherData {
    @InvocableMethod(label='CaseGetVoucherData')
    public static void execute (List<Request> requestList) {
        for (Request req : requestList) {
            String OperationNumber = String.valueOf(req.OperationNumber);
            String OperationNumberParsed = OperationNumber.replace('.', '');
            CaseRemoteSiteManager.getVoucherFromExternalService(String.valueOf(req.PaymentMethod), OperationNumberParsed, req.Id);
        }
    }
    public class Request {
        @InvocableVariable(label='Metodo de Pago' required=true)
        public String PaymentMethod;
        @InvocableVariable(label='Numero de comprobante' required=true)
        public String OperationNumber;
        @InvocableVariable(label='CaseId' required=true)
        public Id Id;
    }
}