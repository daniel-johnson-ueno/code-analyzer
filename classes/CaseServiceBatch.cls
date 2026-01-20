global class CaseServiceBatch implements Database.Batchable<sObject>,Database.Stateful,Database.AllowsCallouts{
    global Boolean result;
    global Integer executionNumber = 0;

    global Database.QueryLocator start(Database.BatchableContext BC){

        return Database.getQueryLocator([SELECT //Caso
                                            Id, RecordType.Developername, ClientProduct__c, ClientSubproduct__c, Subject, Description, Origin, CreatedDate, LastModifiedDate, ClosedDate,
                                            Account.DocumentType__c, Account.DocumentNumber__c, Account.Type_and_Document_Number__c, Account.PersonCode__c, Priority,
                                            SlaStartDate, SlaExitDate, OwnerId, Owner.Name, Account.Name, Account.PersonEmail, Account.Bank_Category__c,
                                            Social_engineering__c, Type, CaseNumber, Reason, Status, Owner.Profile.Name, TimeFirstResponse__c, TimeInStatusAsignado__c, TimeInStatusEscalado__c, 
                                            TimeInStatusDerivado__c, TimeInStatusBloqueado__c, TimeInStatuseEnValidacion__c,
                                            //Fraude
                                            Boarding_channel__c, FraudType__c, Transaction_Origin__c, Business__c, Number_of_transactions__c, CurrencyIsoCode, Duplicate_transactions_Amount__c,
                                            Duplicate_transactions_Total_Amount__c, Login_Alert__c, Device__c, Device_Version__c, Analist__c, complaint__c, Summary__c, Conclusion_Fraude__c,
                                            Associated_vulnerability__c, Observations__c, accretion_suggested__c, Account_to_Credit__c, ReferrReferral_Date_for_Accreditation__c,
                                            Was_accreditation_carried_out__c, CompromisedClient__c, 
                                            //informacion turno
                                            AppointmentId__c, DocumentType__c, DocumentNumber__c, FirstName__c, Apellido__c, Email__c, Phone__c, AppointmentPersonType__c,
                                            CustomerServiceCenter__c, RequirePriorityAttention__c
                                            FROM CASE WHERE CreatedDate = YESTERDAY OR LastModifiedDate = YESTERDAY]);
    }

    global void execute(Database.BatchableContext BC, List<Case> scope){
        if(!scope.isEmpty()){
            result = CaseServiceController.processCases(scope,executionNumber);
            executionNumber++;
        }
    }

    global void finish(Database.BatchableContext BC){
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc.getJobId()];
        System.debug('The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.');
    }
}