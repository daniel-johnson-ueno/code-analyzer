global class BatchHandleCampaignsOverOpportunities implements Database.Batchable<sObject>, Database.Stateful {
    
    global List<String> csvRowValues = new List<String>();

    global static Database.QueryLocator start(Database.BatchableContext BC) {
        
        String query = System.label.QueryCampaignsOverOpportunities;
        if(Test.isRunningTest()){
            query = 'SELECT Id, Name, CloseDate, StageName, RecordTypeId, CampaignId, OwnerId, AccountId, CreatedDate, TypeAndDocumentNumber__c, OfficeNumber__c, ExecutiveEmail__c, Preference_Experience_Center__c FROM Opportunity WHERE CreatedDate = TODAY LIMIT 10';
        }
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Opportunity> scope){
        if (!scope.isEmpty()) {
            Set<String> typeAndDocumentNumberSet = new Set<String>();
            Set<String> officeNumberSet = new Set<String>();
            Set<String> emailsSet = new Set<String>();
            for (Opportunity opp : scope) {
                if (opp.TypeAndDocumentNumber__c != null) {
                    typeAndDocumentNumberSet.add(opp.TypeAndDocumentNumber__c);
                }
                if (opp.ExecutiveEmail__c != null) {
                    emailsSet.add(opp.ExecutiveEmail__c);
                }
                if (opp.OfficeNumber__c != null) {
                    officeNumberSet.add(opp.OfficeNumber__c);
                }
            }
            // Convertir officeNumberSet a Decimal
            Set<Decimal> officeNumberDecimalSet = new Set<Decimal>();
            for (String officeNumber : officeNumberSet) {
                try {
                    officeNumberDecimalSet.add(Decimal.valueOf(officeNumber));
                } catch (Exception e) {
                    System.debug('Error al convertir el número de oficina: ' + officeNumber);
                }
            }
            Map<String, Account> typeAndDocumentToAccountMap = new Map<String, Account>();
            for (Account acc : [
                SELECT Id, Type_and_Document_Number__c
                FROM Account
                WHERE Type_and_Document_Number__c IN :typeAndDocumentNumberSet
            ]) {
                typeAndDocumentToAccountMap.put(acc.Type_and_Document_Number__c, acc);
            }
            Map<String, Account> officeNumberMap = new Map<String, Account>();
            for (Account acc : [
                SELECT Id, Numero_Oficina__c, RecordTypeId
                FROM Account
                WHERE RecordType.DeveloperName='Internal_Company'
                AND Numero_Oficina__c IN :officeNumberDecimalSet
            ]) {
                officeNumberMap.put(String.valueOf(acc.Numero_Oficina__c), acc);
            }
            Map<String, User> emailToUserMap = new Map<String, User>();
            for (User user : [
                SELECT Id, Email, Username, IsActive
                FROM User
                WHERE Email IN :emailsSet
            ]) {
                emailToUserMap.put(user.Email, user);
            }
            Map<String, String> officeToManagerMap = new Map<String, String>();
            for (Account acc : [
                SELECT Id, Numero_Oficina__c, RecordTypeId, Manager_UenoX__r.UserId__c
                FROM Account
                WHERE RecordType.DeveloperName='Internal_Company'
                AND Numero_Oficina__c IN :officeNumberDecimalSet
            ]) {
                officeToManagerMap.put(String.valueOf(acc.Numero_Oficina__c), String.valueOf(acc.Manager_UenoX__r.UserId__c));
            }
            Boolean someFieldEmpty = false;
            List<sObject> csvRowList = new List<sObject>();
            
            for (Opportunity opp : scope) {
                // Account
                if (opp.AccountId == null && opp.TypeAndDocumentNumber__c != null && typeAndDocumentToAccountMap.containsKey(opp.TypeAndDocumentNumber__c)) {
                    opp.AccountId = typeAndDocumentToAccountMap.get(opp.TypeAndDocumentNumber__c).Id;
                } else {
                    if (opp.AccountId==null) {
                        someFieldEmpty = true;
                    }
                    System.debug('No se encontró el typeAndDocumentNumber para la Oportunidad con Id: ' + opp.Id);
                }
                // Experience Center
                if (opp.Preference_Experience_Center__c == null && opp.OfficeNumber__c != null && officeNumberMap.containsKey(String.valueOf(opp.OfficeNumber__c))) {
                    opp.Preference_Experience_Center__c = officeNumberMap.get(String.valueOf(opp.OfficeNumber__c)).Id;
                } else {
                    if (opp.Preference_Experience_Center__c==null) {
                        someFieldEmpty=true;
                    }
                    System.debug('No se encontró el número de oficina para la Oportunidad con Id: ' + opp.Id);
                }
                // Owner
                if (opp.ExecutiveEmail__c != null && emailToUserMap.containsKey(opp.ExecutiveEmail__c)) {
                    User user = emailToUserMap.get(opp.ExecutiveEmail__c);
                    if (user.IsActive) {
                        opp.OwnerId = user.Id;
                    }
                } else {
                    if (opp.OfficeNumber__c != null && officeNumberMap.containsKey(String.valueOf(opp.OfficeNumber__c)) && officeToManagerMap.containsKey(String.valueOf(opp.OfficeNumber__c))) {
                        String owner = officeToManagerMap.get(opp.OfficeNumber__c);
                        if (String.isNotBlank(owner) || String.isNotEmpty(owner)) {
                            opp.OwnerId = owner;
                        }else {
                            someFieldEmpty=true;
                        }
                    }
                    System.debug('No se encontró el OwnerId (Usuario) para la Oportunidad con Id: ' + opp.Id + ' usando el Email: ' + opp.ExecutiveEmail__c);
                }
                if (someFieldEmpty) {
                    // create CSV
                    String idOpp = opp.Id != null ? String.valueOf(opp.Id) : '';
                    String accountId = opp.AccountId != null ? String.valueOf(opp.AccountId) : '';
                    String typeDocNum = opp.TypeAndDocumentNumber__c != null ? String.valueOf(opp.TypeAndDocumentNumber__c) : '';
                    String expCenter = opp.Preference_Experience_Center__c != null ? String.valueOf(opp.Preference_Experience_Center__c) : '';
                    String offcNum = opp.OfficeNumber__c != null ? String.valueOf(opp.OfficeNumber__c) : '';
                    String ownerId = opp.OwnerId != null ? String.valueOf(opp.OwnerId) : '';
                    String execEamil = opp.ExecutiveEmail__c != null ? String.valueOf(opp.ExecutiveEmail__c) : '';
                    String rowStr = idOpp + ',' + accountId + ',' + typeDocNum + ',' + expCenter + ','+ offcNum + ','+ ownerId + ','+ execEamil;
                    csvRowValues.add(rowStr);
                }
                someFieldEmpty=false;
            }
            try {
                update scope;
                System.debug('Oportunidades actualizadas con éxito.');
            } catch (DmlException e) {
                System.debug('Error al actualizar las oportunidades: ' + e.getMessage());
            }
        } else {
            System.debug('No se encontraron oportunidades que cumplieran con las condiciones.');
        }
    }
    
    global void finish(Database.BatchableContext bc){
        String emailAddresses;
        List<String> lstEmailAddresses = new List<String>();
        String documentName = 'csvFile-'+ Datetime.now().format('MMM') + Datetime.now().year();
        String csvColumnHeader = 'Id, AccountId, TypeAndDocumentNumber__c, Preference_Experience_Center__c, OfficeNumber__c, OwnerId, ExecutiveEmail__c\n';
        String csvFile = csvColumnHeader + String.join(csvRowValues,'\n');
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
        blob csvBlob = Blob.valueOf(csvFile);
        attach.setFileName('Batch_Result_Campaigns_Over_Opportunities.csv');
        attach.setBody(csvBlob);
        semail.setSubject('Batch_Result_Campaigns_Over_Opportunities');
        if(!Test.isRunningTest()){
            emailAddresses = System.label.EmailAddressCampaignsOverOpportunities;
            lstEmailAddresses = emailAddresses.split(',');
        } else {
            lstEmailAddresses.add(UserInfo.getUserEmail());
        }
        semail.setToAddresses(lstEmailAddresses);
        semail.setPlainTextBody('Batch_Result_Campaigns_Over_Opportunities');
        semail.setFileAttachments(new Messaging.EmailFileAttachment[]{attach});
        emails.add(semail);
        Messaging.sendEmail(emails);

    }
}