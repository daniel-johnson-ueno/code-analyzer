global class AccountCreationService {

    @InvocableMethod(label='Create Account' description='Create Account from the provided parameters')
    global static List<AccountWrapperResult> createAccountSF(List<AccountWrapperInput> requests){
        List<AccountWrapperResult> result = new List<AccountWrapperResult>();

        List<Account> accCheck = checkIfAccountExist(requests);
        if (!accCheck.isEmpty()) {
            return createErrorWrapper('Ya existe una cuenta con esos datos',true, accCheck);
        } else {
                try {
                List<Client_of_Company__c> clientOfCompany = new List<Client_of_Company__c>();
                List<Account> acc = persistAccount(requests);
                if(!acc.isEmpty()){
                    clientOfCompany = createClientOfCompany(acc,requests);
                }

                if(!clientOfCompany.isEmpty()){
                    return createSuccessWrapper('Cuenta creada correctamente',false, acc);
                } else {
                    return createErrorWrapper('Se ha producido un error al crear la cuenta',false, null);
                } 

            } catch(DmlException e) {
                GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'AccountCreationService', 'createAccountSF');
                return createErrorWrapper('Error al crear Cuenta: ' + e.getMessage(),true, null);
            }
        }
    }

    public static List<Account> checkIfAccountExist(List<AccountWrapperInput> requests){
        Set<String> documentNumbers = new Set<String>();
        Set<String> documentTypes = new Set<String>();
        Set<String> emails = new Set<String>();
        Set<String> phones = new Set<String>();
        List<Account> result = new List<Account>();
        Map<String, String> docTypeValues = new Map<String, String>();
        docTypeValues = getApiAndLabelValues('Lead','Document_Type__c');

        for(AccountWrapperInput request : requests){
            if(request.documentNumber != null) documentNumbers.add(request.documentNumber);
            if(request.documentType != null) documentTypes.add(request.documentType);
            if(request.email != null) emails.add(request.email);
            if(request.phone != null) phones.add(request.phone);
        }

        List<Account> accs = [SELECT Id, DocumentNumber__c, toLabel(DocumentType__c), PersonEmail, Name, Phone
            FROM Account
            WHERE (DocumentNumber__c IN :documentNumbers AND DocumentType__c IN :documentTypes) OR PersonEmail=:emails OR phone =:phones LIMIT 50000];

        for(AccountWrapperInput r : requests){
            for(Account acc : accs){
                String docTypeFieldValue;
                if(docTypeValues.containsKey(r.documentType)) docTypeFieldValue = docTypeValues.get(r.documentType);
                if((acc.DocumentNumber__c == r.documentNumber && acc.DocumentType__c == docTypeFieldValue) || acc.PersonEmail == r.email || acc.Phone == r.phone){
                    result.add(acc);
                }
            }
        }

        return result;
    }

    public static Map<String, String> getApiAndLabelValues(String objectApiName, String fieldApiName) {
        Map<String, String> picklistValues = new Map<String, String>();
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap();
        Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldApiName).getDescribe();
        system.debug(fieldDescribe.getType());
        if (fieldDescribe.getType() == Schema.DisplayType.Picklist) {
            List<Schema.PicklistEntry> picklistEntries = fieldDescribe.getPicklistValues();
            for (Schema.PicklistEntry entry : picklistEntries) {
                picklistValues.put(entry.getValue(),entry.getLabel());
            }
        }
        return picklistValues;
    }

    public static List<AccountWrapperResult> createErrorWrapper(String message, Boolean isDuplicated, List<Account> acc) {
        List<AccountWrapperResult> wrapperList = new List<AccountWrapperResult>();
        AccountWrapperResult wrapper = new AccountWrapperResult();
        wrapper.success = false;
        wrapper.message = message;
        wrapper.isDuplicated = isDuplicated;
        if(!acc.isEmpty()){
            wrapper.accountId = acc[0].Id;
            wrapper.recordAccounts = acc;
        }
        wrapperList.add(wrapper);
        return wrapperList;
	}

    public static List<AccountWrapperResult> createSuccessWrapper(String message, Boolean isDuplicated, List<Account> accs) {
        List<AccountWrapperResult> wrapperList = new List<AccountWrapperResult>();
        for(Account acc : accs){
            AccountWrapperResult wrapper = new AccountWrapperResult();
            wrapper.success = true;
            wrapper.message = 'Cuenta creada correctamente';
            wrapper.accountId = acc.Id;
            wrapperList.add(wrapper);
        }
        return wrapperList;
	}

    public static List<Account> persistAccount(List<AccountWrapperInput> request){

        List<Account> accToInsert = new List<Account>();
        Map<Account,AccountWrapperInput> mapAccountRequest = new Map<Account,AccountWrapperInput>();

        for(AccountWrapperInput accountInfo : request){
            if(accountInfo.documentType == '6'){
                accToInsert.add(mapBusinessAccount(accountInfo));
            } else {
                accToInsert.add(mapPersonAccount(accountInfo));
            }
        }
        try {
            if(!accToInsert.isEmpty()){
                Database.insert(accToInsert);
                return accToInsert;
            }
        } catch (Exception e) {
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'AccountCreationService', 'persistAccount');
        }
        return null;
    }

    public static Account mapPersonAccount(AccountWrapperInput accountInfo){
            Account acc = new Account();
            acc.RecordTypeId = accountInfo.recordType;
            acc.DocumentNumber__c = accountInfo.documentNumber;
            acc.DocumentType__c = accountInfo.documentType;
            acc.Type_and_Document_Number__c = accountInfo.documentType + '_' + accountInfo.documentNumber;
            acc.FirstName = accountInfo.firstName;
            acc.LastName = accountInfo.lastName;
            acc.PersonEmail = accountInfo.email;
            acc.Phone = accountInfo.phone;
            return acc;
    }

    public static Account mapBusinessAccount(AccountWrapperInput accountInfo){
            Account acc = new Account();
            acc.RecordTypeId = accountInfo.recordType;
            acc.DocumentNumber__c = accountInfo.documentNumber;
            acc.DocumentType__c = accountInfo.documentType;
            acc.Type_and_Document_Number__c = accountInfo.documentType + '_' + accountInfo.documentNumber;
            acc.Name = accountInfo.lastName;
            acc.CompanyName__c = accountInfo.lastName;
            acc.BusinessEmail__c = accountInfo.email;
            acc.Phone = accountInfo.phone;
            return acc;
    }

    public static List<Client_of_Company__c> createClientOfCompany(List<Account> accs, List<AccountWrapperInput> requests){
        List<Client_of_Company__c> clientsToInsert = new List<Client_of_Company__c>();
        for(Account account : accs){
            for(AccountWrapperInput request : requests){
                if(account.DocumentNumber__c == request.documentNumber && account.DocumentType__c == request.documentType){
                    Client_of_Company__c cde = new Client_of_Company__c();
                    cde.Client__c = account.Id;
                    cde.Email__c = request.email;
                    cde.Phone__c = request.phone;
                    cde.Vazquez_Group_Company__c = getCompaniesByName(request.company);
                    cde.Status__c = 'Activo';
                    cde.Origin_of_Creation__c = request.originOfCreation;
                    cde.Origin_of_Last_Modification__c = request.originOfLastModification;
                    cde.External_ID__c = (request.externalId != null) ? request.externalId : '';
                    clientsToInsert.add(cde);
                }
            }
        }

        try {
            if(!clientsToInsert.isEmpty()){
                Database.insert(clientsToInsert);
                return clientsToInsert;
            }
        } catch (Exception e) {
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'AccountCreationService', 'createClientOfCompany');
        }
        return null;
    }

    public static Id getCompaniesByName(String company) {
        List<Account> acc = [SELECT Id FROM Account WHERE GroupCompaniesUeno__c = :company  AND RecordType.DeveloperName = 'Vazquez_Group_Company'];
        if(!acc.isEmpty()){
            return acc[0].Id;
        } 
        return '';
    }

    global class AccountWrapperInput {
        @InvocableVariable(required=true label='RecordType' description='RecordType ID de la cuenta')
        global String recordType;
        @InvocableVariable(required=true label='Document ID' description='Numero de Documento de la cuenta')
        global String documentNumber;
        @InvocableVariable(required=true label='Document Type' description='Tipo de Documento de la cuenta')
        global String documentType;
        @InvocableVariable(required=true label='First Name' description='Nombre de la cuenta')
        global String firstName;
        @InvocableVariable(required=true label='Last Name' description='Apellido de la cuenta')
        global String lastName;
        @InvocableVariable(required=true label='Phone' description='Telefono de la cuenta')
        global String phone;
        @InvocableVariable(required=true label='Email' description='Email de la cuenta')
        global String email;
        @InvocableVariable(required=true label='Company' description='Empresa de la cuenta')
        global String company;
        @InvocableVariable(label='OriginOfCreation' description='Origen de la creacion de la cuenta')
        global String originOfCreation;
        @InvocableVariable(label='OriginOfLastModification' description='Origen de la modificacion de la cuenta')
        global String originOfLastModification;
        @InvocableVariable(label='externalId' description='Id Externo de la cuenta')
        global String externalId;
        public AccountWrapperInput(){}
    }
    
    global class AccountWrapperResult {
        @InvocableVariable(label='success' description='Resultado verdadero o falso')
        global Boolean success;
        @InvocableVariable(label='mensaje' description='Resultado')
        global String message;
        @InvocableVariable(label='Account Id' description='ID de la Cuenta')
        global String accountId;
        @InvocableVariable(label='Code' description='Codigo operación')
        global String code;
        @InvocableVariable(label='isDuplicated' description='Indicador de duplicado')
        global Boolean isDuplicated;
        @InvocableVariable(label='recordsAccount' description='Cuentas duplicadas')
        global List<Account> recordAccounts;

        public AccountWrapperResult(){}
    }
    
}