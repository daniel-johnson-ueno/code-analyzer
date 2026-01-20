public class CaseServiceController {

    public static Boolean processCases(List<Case> cases, Integer executionNumber){
        Boolean result = false;
        try {
            Boolean resp = dataLakeCallout(createJSON(cases),executionNumber);
        } catch (Exception e){
            System.debug('Line: ' + e.getLineNumber() + ' Message: ' + e.getMessage());
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'CaseServiceController', 'fileValidation');
            return false;
        }
        return result;
    }

    public static String createJSON(List<Case> cases){
        List<CaseRecord> resultList = new List<CaseRecord>();
        for(Case c : cases){
            CaseRecord caseObj = new CaseRecord();
            caseObj.recordId = c.Id;
            caseObj.recordType = c.RecordType.Developername;
            caseObj.clientProduct = c.ClientProduct__c;
            caseObj.clientSubproduct = c.ClientSubproduct__c;
            caseObj.subject = c.Subject;
            caseObj.description = c.Description;
            caseObj.origin = c.Origin;
            caseObj.createdDate = c.CreatedDate != null ? String.valueOf(c.CreatedDate) : '';
            caseObj.lastModifiedDate = c.LastModifiedDate != null ? String.valueOf(c.LastModifiedDate) : '';
            caseObj.closedDate = c.ClosedDate != null ? String.valueOf(c.ClosedDate) : '';
            caseObj.accountDocumentType = c.Account.DocumentType__c;
            caseObj.accountDocumentNumber = c.Account.DocumentNumber__c;
            caseObj.typeDocumentNumber = c.Account.Type_and_Document_Number__c;
            caseObj.personCode = String.valueOf(c.Account.PersonCode__c);
            caseObj.priority = c.Priority;
            caseObj.slaStartDate = c.SlaStartDate != null ? String.valueOf(c.SlaStartDate) : '';
            caseObj.slaExitDate = c.SlaExitDate != null ? String.valueOf(c.SlaExitDate) : '';
            caseObj.ownerId = c.OwnerId;
            caseObj.owner = c.Owner.Name;
            caseObj.accountName = c.Account.Name;
            caseObj.accountEmail = c.Account.PersonEmail;
            caseObj.bankCategory = c.Account.Bank_Category__c;
            caseObj.socialengineering = c.Social_engineering__c;
            caseObj.type = c.Type;
            caseObj.status = c.Status;
            caseObj.ownerProfileName = c.Owner.Profile.Name;
            caseObj.timeFirstResponse = c.TimeFirstResponse__c;
            caseObj.timeInStatusAsignado = c.TimeInStatusAsignado__c;
            caseObj.timeInStatusEscalado = c.TimeInStatusEscalado__c;
            caseObj.timeInStatusDerivado = c.TimeInStatusDerivado__c;
            caseObj.timeInStatusBloqueado = c.TimeInStatusBloqueado__c;
            caseObj.timeInStatuseEnValidacion = c.TimeInStatuseEnValidacion__c;         
            //Fraude
            caseObj.caseNumber = c.CaseNumber;
            caseObj.reason = c.Reason;
            caseObj.compromisedClient = c.CompromisedClient__c;
            caseObj.boardingChannel = c.Boarding_channel__c;
            caseObj.fraudType = c.FraudType__c;
            caseObj.transactionOrigin = c.Transaction_Origin__c;
            caseObj.business = c.Business__c;
            caseObj.numberofTransactions = String.valueOf(c.Number_of_transactions__c);
            caseObj.currencyIsoCode = c.CurrencyIsoCode;
            caseObj.duplicateTransactionsAmount = String.valueOf(c.Duplicate_transactions_Amount__c);
            caseObj.duplicateTransactionsTotalAmount = String.valueOf(c.Duplicate_transactions_Total_Amount__c);
            caseObj.loginAlert = c.Login_Alert__c;
            caseObj.device = c.Device__c;
            caseObj.deviceVersion = c.Device_Version__c;
            caseObj.analist = c.Analist__c;
            caseObj.complaint = c.complaint__c;
            caseObj.summary = c.Summary__c;
            caseObj.conclusionFraude = c.Conclusion_Fraude__c;
            caseObj.associatedVulnerability = c.Associated_vulnerability__c;
            caseObj.observations = c.Observations__c;
            caseObj.accretionSuggested = c.accretion_suggested__c;
            caseObj.accountToCredit = c.Account_to_Credit__c;
            caseObj.referrerReferralDateForAccreditation = c.ReferrReferral_Date_for_Accreditation__c != null ? c.ReferrReferral_Date_for_Accreditation__c.toString() : '';
            caseObj.wasAccreditationCarriedOut = c.Was_accreditation_carried_out__c;
            
            //informacion de turno
            caseObj.appointmentId = c.AppointmentId__c;
            caseObj.documentType = c.DocumentType__c;
            caseObj.documentNumber = c.DocumentNumber__c;
            caseObj.firstName = c.FirstName__c;
            caseObj.lastName = c.Apellido__c;
            caseObj.email = c.Email__c;
            caseObj.phone = c.Phone__c;
            caseObj.appointmentPersonType = c.AppointmentPersonType__c;
            caseObj.customerServiceCenter = c.CustomerServiceCenter__c;
            caseObj.requirePriorityAttention = String.valueOf(c.RequirePriorityAttention__c);
            resultList.add(caseObj);
        }

        return JSON.serialize(resultList);

    }

    public static Boolean dataLakeCallout(String jsonData, Integer executionNumber){
        HttpHelper.HttpClientWithRetry httpClient = new HttpHelper.HttpClientWithRetry();
        HttpResponse tResponse = httpClient.doCallout(createRequest(jsonData, executionNumber));

        String responseJSON = tResponse.getBody();
        System.debug('@@@@tResponse.getStatusCode(): '+ tResponse.getStatusCode());
        System.debug('@@@@responseJSON: '+ responseJSON);
        
        if(tResponse.getStatusCode() == 200){
            return true;
        } else {
            System.debug('Error: ' + tResponse.getStatusCode() + ' - ' + tResponse.getBody());
            return false;
        }
    }


    public static HttpRequest createRequest(String jsonData, Integer executionNumber){
        String fileName = System.label.fileCaseServiceName;
        String dateFormat = System.label.dateFormatCaseService;
        DateTime dt = DateTime.now().adddays(-1).addSeconds(executionNumber);
        String dateTimeStr = dt.format(dateFormat);

        String fileTitle = fileName + dateTimeStr + '.json';
        System.debug(fileTitle);
        HttpRequest request = new HttpRequest();
        request.setMethod('PUT');
        request.setBody(jsonData);
        request.setEndpoint('callout:AWS_S3/inbound/ueno/crm/' + fileTitle);
        request.setTimeout(60000);
        return request;
    }

    public class CaseRecord{
        //InformacionCaso/Cuenta
        public String recordId {get; set;}
        public String recordType {get; set;}
        public String clientProduct {get; set;}
        public String clientSubproduct {get; set;}
        public String subject {get; set;}
        public String description {get; set;}
        public String origin {get; set;}
        public String createdDate {get; set;}
        public String lastModifiedDate {get; set;}
        public String closedDate {get; set;}
        public String accountDocumentType {get; set;}
        public String accountDocumentNumber {get; set;}
        public String typeDocumentNumber {get; set;}
        public String personCode {get; set;}
        public String priority {get; set;}
        public String slaStartDate {get; set;}
        public String slaExitDate {get; set;}
        public String ownerId {get; set;}
        public String owner {get; set;}
        public String accountName {get; set;}
        public String accountEmail {get; set;}
        public String bankCategory {get; set;}
        public String socialengineering {get; set;}
        public String type {get; set;}
        public String numberofTransactions {get; set;}
        public String currencyIsoCode {get; set;}
        public String accountToCredit {get; set;}
        public String status {get; set;}
        public String ownerProfileName {get; set;}
        public String timeFirstResponse {get; set;}
        public String timeInStatusAsignado {get; set;}
        public String timeInStatusEscalado {get; set;}
        public String timeInStatusDerivado {get; set;}
        public String timeInStatusBloqueado {get; set;}
        public String timeInStatuseEnValidacion {get; set;}
        //InformacionFraude
        public String caseNumber {get;set;}
        public String reason {get;set;}
        public String compromisedClient {get;set;}
        public String boardingChannel {get;set;}
        public String fraudType {get; set;}
        public String transactionOrigin {get;set;}
        public String business {get;set;}
        public String duplicateTransactionsAmount {get;set;}
        public String duplicateTransactionsTotalAmount {get;set;}
        public String loginAlert {get;set;}
        public String device {get;set;}
        public String deviceVersion {get;set;}
        public String analist {get;set;}
        public String complaint {get;set;}
        public String summary {get;set;}
        public String conclusionFraude {get;set;}
        public String associatedVulnerability {get;set;}
        public String observations {get;set;}
        public String accretionSuggested {get;set;}
        public String referrerReferralDateForAccreditation {get;set;}
        public String wasAccreditationCarriedOut {get;set;}
        //InformacionTurnos
        public String appointmentId {get;set;}
        public String documentType {get;set;}
        public String documentNumber {get;set;}
        public String firstName {get;set;}
        public String lastName {get;set;}
        public String email {get;set;}
        public String phone {get;set;}
        public String appointmentPersonType {get;set;}
        public String customerServiceCenter {get;set;}
        public String requirePriorityAttention {get;set;}

    }

}