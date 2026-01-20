@isTest
public class CaseGetVoucherDataTest {
    @isTest
    static void executeTest(){
        Account account = TestFactory.createPersonAccount();
        Case caseObject = TestFactory.createCase('Asignado', 'Reclamo', account.Id);
        List<CaseGetVoucherData.Request> requestList = new List<CaseGetVoucherData.Request>();
        CaseGetVoucherData.Request request = new CaseGetVoucherData.Request();
        request.Id= caseObject.Id;
        request.OperationNumber = '111111';
        request.PaymentMethod = 'TD';
        requestList.add(request);
        CaseGetVoucherData.execute(requestList);
    }
}