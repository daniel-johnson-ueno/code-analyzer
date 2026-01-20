public without sharing class OnboardingController {
    @AuraEnabled
    public static Id createLeadAndCloseCase(String caseId, String preferenceExperienceCenter, String companyName, String ruc, String documentNumber, String documentType, String email){
        if (String.isBlank(caseId)) {
            throw new AuraHandledException('El ID del caso está vacío');
        }
        if (String.isBlank(preferenceExperienceCenter)) {
            throw new AuraHandledException('El campo Preference_Experience_Center__c está vacío');
        }
        
        try {
            // Actualizar el estado del Case a 'Cerrado'
            String rucNumber = ruc.trim(); 
            String docNumber = documentNumber.trim();
            String companyN  = companyName.trim(); 
            Case caseToUpdate = [SELECT Id, Status FROM Case WHERE Id = :caseId LIMIT 1 FOR UPDATE];
            if (caseToUpdate == null) {  throw new AuraHandledException('El caso con ID ' + caseId + ' no existe.'); }
            updateCaseEmail(caseToUpdate, email);
            updateCase(caseToUpdate, preferenceExperienceCenter, rucNumber);
            checkAccOnBankitti(rucNumber, documentType, companyN, docNumber, preferenceExperienceCenter, caseId, email); 
            
            return caseToUpdate.Id; 
        } catch (Exception e) { throw new AuraHandledException('Se ha producido un error inesperado: ' + e.getMessage()); }
    }
    @future(callout=true)
    public static void checkAccOnBankitti(String ruc, String documentType, string companyName, String documentNumber, String preferenceExperienceCenter,String caseId, String mail){
        Id accountId;
        Boolean existAccount;
        Boolean existAccountOnBankitti;
        String contactId;
        String opportunityId;
        String leadId;
    
        
        //llamada a bankitti
        if (!Test.isRunningTest()) {  
            List<AccountMappingService.AccountMappingRequest> requests = new List<AccountMappingService.AccountMappingRequest>();
            AccountMappingService.AccountMappingRequest request = new AccountMappingService.AccountMappingRequest();
            request.documentId = documentNumber; request.documentType = '1';
            requests.add(request);
            List<AccountMappingService.AccountMappingResult> results = AccountMappingService.mapAccountData(requests);
            List<String> resultAccountIds = new List<String>();
            for (AccountMappingService.AccountMappingResult result : results) { if (result.success) { resultAccountIds.add(result.accountId); } }
            
            existAccountOnBankitti = (resultAccountIds.size() > 0) ? true : false;
        } 
        
        String productValue = getProductId('Caja de Ahorro');
        leadId = checkIfLeadExist(ruc);
        String docType = '6'; 
         
        if (String.isNotBlank(leadId) && String.isNotEmpty(leadId) ) {
            accountId = checkIfAccountExist(ruc, docType); convertLead(leadId, accountId, documentNumber, documentType, caseId, ruc, companyName, mail, productValue); 
        } else{
            accountId = checkIfAccountExist(ruc,docType);
            if(accountId != null){
                String companyEmail = getCompanyEmail(accountId);
                updateAccountName(accountId, companyName); 
                opportunityId = checkIfOpportunityExist(accountId);
                if(opportunityId == null){ 
                    createOpportunity(ruc, companyName, accountId, preferenceExperienceCenter, '6', caseId, mail, companyEmail);
                    opportunityId = checkIfOpportunityExist(accountId);
                    system.debug('GET opportunityId ' + opportunityId);
                } else {
                    updateOpportunity(OpportunityId, caseId, mail, companyEmail); 
                }
                String contactByCI;
                String personAccId = checkIfAccountExist(documentNumber, '1');
                if (String.isNotBlank(personAccId)) {
                    contactByCI = checkIfContactExist(personAccId);
                }
                contactId = checkIfContactExist(accountId); 
                
                if (String.isNotBlank(contactByCI) && String.isNotBlank(contactId)) {
                    Boolean isPrimaryC = (contactByCI == contactId);
                    updateContact(contactByCI, accountId, isPrimaryC); 
                }
            } else {
                createAccount(preferenceExperienceCenter, companyName, ruc);
                accountId = checkIfAccountExist(ruc, docType); 
                String companyEmail = getCompanyEmail(accountId);
                createOpportunity(ruc, companyName, accountId, preferenceExperienceCenter, '6', caseId, mail, companyEmail);
                opportunityId = checkIfOpportunityExist(accountId);
                String contactByCI;
                String personAccId = checkIfAccountExist(documentNumber, '1');
                if (String.isNotBlank(personAccId)) {
                    contactByCI = checkIfContactExist(personAccId);
                }
                if(String.isNotBlank(contactByCI)){ updateContact(contactByCI, accountId, true); } 
            }
        }
        
    }

    public static void updateAccountName(String accountId, String companyName){
        List<Account> accounts = new List<Account>();
        accounts = [SELECT Id, name FROM Account where Id=: accountId ]; 
        List<Account> accToUpdate = new List<Account>();
        if(accounts.size()>0){
            for(Account acc: accounts){
                acc.name = companyName; 
                accToUpdate.add(acc); 
            }
            update accToUpdate; 
        }
    }

    public static void updateContact(String contactByCI, String accountId, Boolean isPrimary){
        List<AccountContactRelation> accContactRelation = [SELECT Id from AccountContactRelation WHERE AccountId =: accountId and ContactId =: contactByCI LIMIT 1 ]; 
        if(accContactRelation.size()>0) {  accContactRelation[0].PrimaryContact__c = isPrimary; update accContactRelation;
        } else {
            AccountContactRelation accContactRelationToInsert = new AccountContactRelation();
            accContactRelationToInsert.AccountId = accountId;
            accContactRelationToInsert.contactId = contactByCI;
            accContactRelationToInsert.PrimaryContact__c = isPrimary;
            Insert accContactRelationToInsert;
        }
    }
    
    public static void updateCaseEmail(Case caseToUpdate, String emailVal){  
            caseToUpdate.Email__c = emailVal;   
            update caseToUpdate;
    }

    public static void updateCase(Case caseToUpdate, String preferenceExperienceCenter, String ruc){
        caseToUpdate.Preference_experience_center__c = preferenceExperienceCenter;
        caseToUpdate.ruc__c = ruc;
        caseToUpdate.Status = 'Cerrado'; 
        caseToUpdate.Resolution__c = 'Migrado a Ventas';  
        update caseToUpdate;
    }

    public static id getRecordtypeId(String objName, String rtName){
        Id rtId = [SELECT Id FROM RecordType WHERE SObjectType =: objName AND Name =: rtName LIMIT 1].id;
        return rtId; 
    }

    public static string getOwnerId(String preferenceExperienceCenter){
        list<Contact> contacto = [SELECT Email FROM contact WHERE id IN (select Manager_UenoX__c from account where id = : preferenceExperienceCenter)  LIMIT 1];
        if(contacto.size()>0) {
            String contactEmail = contacto[0].Email; String ownerId = getUserId(contactEmail);
            if(ownerId != null){ return ownerId; } else{
                contacto = [SELECT Email FROM contact WHERE id IN (select Regional_Commercial_Manager__c from account where id = : preferenceExperienceCenter) LIMIT 1];
                if(contacto.size()>0) {   String contactMail = contacto[0].Email; ownerId = getUserId(contactMail); return ownerId;}
            }
        } 
        return null; 
    }
    public static string getUserId(String contactEmail){
       List<User> owner = [SELECT id, IsActive FROM User WHERE Email =: contactEmail AND IsActive = true LIMIT 1];
       if(owner.size() > 0){ return owner[0].id; } return null; 
    }

    public static void createAccount(String preferenceExperienceCenter, String companyName, string ruc){
        String recordTypeName = 'Business';  
        String objName = 'Account';
        String userId = getOwnerId(preferenceExperienceCenter); 
        
        Id accRtId = getRecordTypeId(objName, recordTypeName);
        Account newAcc = new Account(); 
        
        newAcc.Preference_Experience_Center__c = preferenceExperienceCenter;
        newAcc.Name = companyName;
        newAcc.CompanyName__c = companyName;
        newAcc.DocumentNumber__c = ruc;
        newAcc.DocumentType__c = '6';
        newAcc.RecordTypeId = accRtId; 
        if(userId != null){ newAcc.OwnerId = userId; } 
        Insert newAcc; 
    }

    public static void createOpportunity(String ruc, String companyName, String accountId, String preferenceExperienceCenter, String documentType, String caseId, String clientEmail, String companyEmail){
        String recordTypeName = 'Onboarding'; 
        String objName = 'Opportunity';
        String userId = getOwnerId(preferenceExperienceCenter); 
        
        Id oppRtId = getRecordTypeId(objName, recordTypeName);
        Date fechaActual = Date.today();
        String oppName = 'Onboarding - ' + ruc + ' - ' + companyName;
        Opportunity newOpp = new Opportunity(); 
        newOpp.Name = oppName.length() > 120 ? oppName.substring(0, 120) : oppName;
        newOpp.StageName = 'Asignación';
        newOpp.RecordTypeId = oppRtId;
        newOpp.AccountId = accountId;
        newOpp.Document_Number__c = ruc;
        newOpp.Document_Type__c = documentType;
        newOpp.Preference_Experience_Center__c = preferenceExperienceCenter;
        newOpp.CaseId__c = caseId; 
        newOpp.CurrencyIsoCode = 'PYG'; 
        newOpp.Company_Email__c = companyEmail;
        newOpp.ClientEmail__c = clientEmail;
        if(userId != null){ newOpp.OwnerId = userId; } 
        newOpp.CloseDate =  fechaActual.addDays(7);
        Insert newOpp; 
    }

    public static String getProductId(String productName){
        String productValue; 
        List<Product2> products = [SELECT Id FROM Product2 WHERE name =: productName ];
        for(Product2 prod : products){
            productValue = prod.Id; 
        }
        system.debug('Getproduct productValue ' + productValue);
        return productValue; 
    }

    public static String checkIfOppLineItemExist(String oppId, String productValue){
        
        String oppLineItemId;
        List<OpportunityLineItem> lstOppsLineItem = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId =: oppId AND Product2Id =: productValue];
        if (lstOppsLineItem.size()>0) {
            oppLineItemId = lstOppsLineItem[0].Id;
        } 
        system.debug('checkIfOppLineItemExist ' + oppLineItemId);
        return oppLineItemId;
    }
    
    public static void updateOpportunity(String OpportunityId, String caseId, String clientEmail, String companyEmail){
        list<Opportunity> objOpportunity = [SELECT Id FROM Opportunity WHERE Id=:OpportunityId];
        if (objOpportunity.size()>0) {
            Opportunity opp = objOpportunity[0];
            opp.Product__c = 'Caja de Ahorros (Gs y USD)'; 
            opp.CaseId__c = caseId; 
            opp.Company_Email__c = companyEmail;
            opp.ClientEmail__c = clientEmail;
            update opp; 
        }
    }

    public static void convertLead(String leadId, String accountId, String documentNumber, String documentType, String caseId, String ruc, String companyName, String clientEmail, String productValue){
        Lead updateLead = [SELECT Id, createdByOnbProcess__c, ownerId from Lead where Id =: leadId LIMIT 1];
        if(updateLead != null){
            updateLead.createdByOnbProcess__c = true; update updateLead;String leadOwner = updateLead.ownerId;
            //Inicio proceso de conversión
            Database.LeadConvert lc = new Database.LeadConvert(); lc.setLeadId(leadId);
            
            LeadStatus convertStatus = [SELECT Id, ApiName FROM LeadStatus WHERE IsConverted=true AND ApiName = 'Cerrado ganado' LIMIT 1];
            lc.setConvertedStatus(convertStatus.ApiName);
            
            if (String.isNotBlank(accountId)) { lc.setAccountId(accountId); }
            Database.LeadConvertResult lcr;
            try { lcr = Database.convertLead(lc); } catch (Exception e) { throw new AuraHandledException('Error inesperado al convertir el Lead: ' + e.getMessage()); }
            
            // Verificar si la conversión fue exitosa
            if (lcr.isSuccess()) {
                Account updateAccount = [SELECT Id FROM Account WHERE Id = :lcr.getAccountId() LIMIT 1];
                Opportunity updateOpp = [SELECT Id FROM Opportunity WHERE Id = :lcr.getOpportunityId() LIMIT 1];
                if (updateAccount != null) { updateAccount.OwnerId = leadOwner; update updateAccount;   }
                if (updateOpp != null) {                    
                    Id oppRtId = getRecordTypeId('Opportunity', 'Onboarding');
                    updateOpp.Name = 'Onboarding - ' + ruc + ' - ' + companyName;
                    updateOpp.CaseId__c = CaseId;
                    updateOpp.RecordTypeId = oppRtId; 
                    updateOpp.AccountId = lcr.getAccountId(); 
                    updateOpp.StageName = 'Asignación'; 
                    updateOpp.Product__c = 'Caja de Ahorros (Gs y USD)'; 
                    updateOpp.ClientEmail__c = clientEmail;
                    update updateOpp; 
                }
                
                String personAccId = checkIfAccountExist(documentNumber, '1'); 
                if (String.isNotBlank(personAccId)) {
                    String contactByCI = checkIfContactExist(personAccId);
                    if (String.isNotBlank(contactByCI)) {updateContact(contactByCI, lcr.getAccountId(), true);}deleteDuplicateContact(lcr.getContactId());
                }
            } else {
                System.debug('Error en la conversión del Lead: ' + lcr.getErrors());
            }
        }
       
    }
    public static string getCompanyEmail(String accountId){
        String companyEmail;
        List<Account> lstAccounts = [SELECT Id, BusinessEmail__c FROM Account WHERE Id =: accountId];
        if (lstAccounts.size()>0) {
            companyEmail = lstAccounts[0].BusinessEmail__c;
        } 
        return companyEmail;

    }

    public static String checkIfAccountExist(String docNum, String documentType){
        String accountId;
        List<Account> lstAccounts = [SELECT Id FROM Account WHERE DocumentNumber__c=:docNum AND DocumentType__c =: documentType];
        if (lstAccounts.size()>0) {
            accountId = lstAccounts[0].Id;
        } 
        return accountId;
    }
    
    public static String checkIfLeadExist(String ruc){
        String leadId;
        List<Lead> objLead = [SELECT Id FROM Lead WHERE Document_Number__c =: ruc AND Document_Type__c = '6' AND status != 'Cerrado ganado' AND status != 'Cerrado perdido'];
        if (objLead.size()>0) { leadId = objLead[0].Id; } 
        return leadId; 
            
    }
    public static void deleteDuplicateContact(String contactId){
        Contact objContact = [SELECT Id FROM Contact WHERE Id =:contactId]??null;
        if (objContact != null) {  delete objContact; }
    }

    public static String checkIfContactExist(String accId){
        String contactId; 
        list<Contact> objContact = [SELECT Id FROM Contact WHERE accountId =:accId];
        if (objContact.size()>0) {  contactId = objContact[0].Id; }
        return contactId; 
    }

    public static String checkIfContactExistByEmail(String documentNumber, String documentType, String mail){
        String contactId; 
        list<Contact> objContact = [SELECT Id, PersonDocumentNumber__c FROM Contact WHERE Email =:mail 
                                    AND PersonDocumentNumber__c =: documentNumber AND PersonDocumentType__c =: documentType ];
        if (objContact.size()>0) {  contactId = objContact[0].Id; }
        return contactId; 
    }

    public static String checkIfOpportunityExist(String accId){
        String oppId; 
        list<Opportunity> objOpportunity = [SELECT Id FROM Opportunity WHERE accountId=:accId AND StageName != 'Exitoso' AND StageName != 'Rechazado' AND StageName != 'No exitoso' AND  RecordType.name = 'Onboarding'];
        if (objOpportunity.size()>0) {
            oppId = objOpportunity[0].Id;
        }
        return oppId; 
    }
}