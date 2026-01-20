public without sharing class TipificadorController {
    
    @AuraEnabled(cacheable=false)
    public static List<Account> getCompanies() {
        return [SELECT Id,GroupCompaniesUeno__c FROM Account WHERE GroupCompaniesUeno__c != NULL AND RecordType.DeveloperName = 'Vazquez_Group_Company'];
    }

    @AuraEnabled(cacheable=false)
    public static List<Case_Derivation_Rules__mdt> getTipificadores(String companyName) {
        return [SELECT Id,Type__c FROM Case_Derivation_Rules__mdt WHERE Vazquez_Group_Company__c = :companyName];
    }

    @AuraEnabled(cacheable=false)
    public static List<Case_Derivation_Rules__mdt> getTipificadoresByType(String type) {
        return [
                SELECT Id, Reason__c, Type__c, RecordType__c
                FROM Case_Derivation_Rules__mdt WHERE Type__c = :type
        ];
    }

   @AuraEnabled(cacheable=false)
    public static List<Case_Derivation_Rules__mdt> getRequiredFields(String caseOrigin, String type, String reasonAndRecordType) {
        List<Case_Derivation_Rules__mdt> firstSearch = new  List<Case_Derivation_Rules__mdt>();
        List<Case_Derivation_Rules__mdt> finalMetadata = new  List<Case_Derivation_Rules__mdt>();
        if(reasonAndRecordType != null){
        	List<String> values = reasonAndRecordType.split('\\|');
        	String reason = values[0].trim();
        	String recordType = values[1].trim();
        
        	firstSearch = [SELECT Id, RequiredFields__c, Origin__c, CaseOwnerQueue__c FROM Case_Derivation_Rules__mdt WHERE Type__c = :type AND Reason__c = :reason AND RecordType__c = :recordType];

        	if(!firstSearch.isEmpty()){
            	if(firstSearch.size() > 1){
                	if(caseOrigin == 'Turnero' || caseOrigin == 'ROT'){
                    	for(Case_Derivation_Rules__mdt metadata :firstSearch){
                        	if(metadata.Origin__c == 'Presencial'){
                            	finalMetadata.add(metadata);
                        	}
                    	}
                	}else{
                    	for(Case_Derivation_Rules__mdt metadata :firstSearch){
                        	if(metadata.Origin__c == 'Digital'){
                            	finalMetadata.add(metadata);
                        	}
                    	}
                	}
            	}
        	}
        }    
        if(!finalMetadata.isEmpty()){
            return finalMetadata;
        }else{
            return firstSearch;
        }
    }

    @AuraEnabled(cacheable=false)
    public static void updateCaseRequiredFields(Id caseId, Map<String,String> fieldValues, String recordTypeNameAndReason, String type, String company, String subject, String description){
        try{
            Id accCompany;
            String queueDN;
            if(company != null){
                accCompany = getAccountCompany(company);
            }
            List<String> values = recordTypeNameAndReason.split('\\|');
            String reason = values[0].trim();
            String recordType = values[1].trim();
            Case caseToUpdate = [SELECT Id,Reason,Type,RecordTypeId, Status, Origin,Priority, SLA_Escalado__c , SLA_Derivado__c, SLA_Total__c,Braze_Description__c, Subject, Description  FROM Case WHERE Id = :caseId];
            if(recordType == 'Reclamo Fraude'){
                recordType = 'Reclamo_Fraude';
            }
            Id recordTypeId = [SELECT Id, DeveloperName FROM RecordType WHERE DeveloperName = :recordType].Id;
            caseToUpdate.Reason = reason;
            caseToUpdate.Type = type;
            caseToUpdate.RecordTypeId = recordTypeId;
            if(subject != null){
                caseToUpdate.Subject = subject;
            }
            if(description != null){
                caseToUpdate.Description = description;
            }
            if(accCompany != null){
                caseToUpdate.Vazquez_Group_Company__c = accCompany;
            }
            if(fieldValues != null || !fieldValues.isEmpty()){
                for(String fieldName :fieldValues.keySet()){
                    if(Schema.sObjectType.Case.fields.getMap().containsKey(fieldName)){
                          if(isNumericField(fieldName)){
                              caseToUpdate.put(fieldName, Integer.valueOf(fieldValues.get(fieldName)));
                          }else if (isDoubleField(fieldName)){
                              caseToUpdate.put(fieldName, Double.valueOf(fieldValues.get(fieldName)));
                          }else if(fieldName == 'DateTime__c'){
                              List<String> partsDate = fieldValues.get(fieldName).split('-');
                              Date dateToCase = Date.newInstance(Integer.valueOf(partsDate[0]),Integer.valueOf(partsDate[1]),Integer.valueOf(partsDate[2]));
                              caseToUpdate.put(fieldName, dateToCase);
                          }else{
                              caseToUpdate.put(fieldName, fieldValues.get(fieldName));
                          }    
                    }
                }
            }
            List<Case_Derivation_Rules__mdt> metadata = [SELECT Id, DeveloperName, RecordType__c, Type__c, Reason__c, Origin__c, CaseStatus__c, CaseOwnerQueue__c, Priority__c, SLA_Escalado__c , SLA_Derivado__c, SLA_Total__c, Description__c,Vazquez_Group_Company__c 	 
                                                         FROM Case_Derivation_Rules__mdt WHERE RecordType__c = :recordType
             											 AND Type__c = :type AND Reason__c =:reason 
                                                         AND (CaseStatus__c = 'Escalado' OR CaseStatus__c = 'Cerrado')];
            if(!metadata.isEmpty()){
            	if(metadata.size() > 1){
                	if(caseToUpdate.Origin == 'Turnero' || caseToUpdate.Origin == 'ROT'){
                    	for(Case_Derivation_Rules__mdt mdt :metadata){
                        	if(mdt.Origin__c == 'Presencial'){
                            	caseToUpdate.Priority = mdt.Priority__c;
                                if(mdt.Description__c != null){
                                	caseToUpdate.Braze_Description__c = mdt.Description__c;
                                }
                                if(mdt.SLA_Escalado__c != null && mdt.SLA_Derivado__c != null){
                    				caseToUpdate.SLA_Escalado__c = mdt.SLA_Escalado__c;
                					caseToUpdate.SLA_Derivado__c = mdt.SLA_Derivado__c;
                                    caseToUpdate.SLA_Total__c = mdt.SLA_Total__c;
                                    queueDN = mdt.CaseOwnerQueue__c;
                				}
                        	}
                    	}
                	}else{
                    	for(Case_Derivation_Rules__mdt mdt :metadata){
                        	if(mdt.Origin__c == 'Digital'){
                            	caseToUpdate.Priority = mdt.Priority__c;
                                if(mdt.Description__c != null){
                                	caseToUpdate.Braze_Description__c = mdt.Description__c;
                                }
                                if(mdt.SLA_Escalado__c != null && mdt.SLA_Derivado__c != null){
                    				caseToUpdate.SLA_Escalado__c = mdt.SLA_Escalado__c;
                					caseToUpdate.SLA_Derivado__c = mdt.SLA_Derivado__c;
                                    caseToUpdate.SLA_Total__c = mdt.SLA_Total__c;
                                    queueDN = mdt.CaseOwnerQueue__c;
                				}
                        	}
                    	}
                	}
            	}else{
                    caseToUpdate.Priority = metadata[0].Priority__c;
                    if(metadata[0].Description__c != null){
                    	caseToUpdate.Braze_Description__c = metadata[0].Description__c;
                    }
                    if(metadata[0].SLA_Escalado__c != null && metadata[0].SLA_Derivado__c != null && metadata[0].SLA_Total__c != null){
                        caseToUpdate.SLA_Escalado__c = metadata[0].SLA_Escalado__c;
                		caseToUpdate.SLA_Derivado__c = metadata[0].SLA_Derivado__c;
                        caseToUpdate.SLA_Total__c = metadata[0].SLA_Total__c;
                        queueDN = metadata[0].CaseOwnerQueue__c;
                	}
                }
                if(recordType != 'Consulta'){
                    if(!itIsNewCompanyMetadata(metadata)){
                        if(caseToUpdate.Status == 'Escalado'){
                            Map<String, Group> queuesByDeveloperName = getQueues();
                            if(queuesByDeveloperName.get(queueDN).Id != null){
                                caseToUpdate.OwnerId = queuesByDeveloperName.get(queueDN).Id;
                            }
                        }else{
                            caseToUpdate.Status = 'Escalado';
                        }    
                    }
                }
        	}
            Database.SaveResult sr = Database.update(caseToUpdate);
            if(!sr.isSuccess()){
                throw new AuraHandledException('Error al guardar el caso: '+sr.getErrors());
            }else{
                System.debug('Guardado exitoso');
            }
        }catch(Exception e){
            System.debug(' e.getMessage() '+ e.getMessage());
            throw new AuraHandledException('Error al guardar el caso: '+ e.getMessage());
        }
    }

    @AuraEnabled
    public static Id createCase(Id accountId, Map<String,String> fieldValues, String recordTypeNameAndReason, String type, Contact contact, String company){
        Id caseIdResult;
        try{
            Id accCompany;
            if(company != null){
                accCompany = getAccountCompany(company);
            }
            List<String> values = recordTypeNameAndReason.split('\\|');
            String reason = values[0].trim();
            String recordType = values[1].trim();
            Id recordTypeId = [SELECT Id, DeveloperName FROM RecordType WHERE DeveloperName = :recordType].Id;
            Case newCase = new Case();
            newCase.Reason = reason;
            newCase.Type = type;
            newCase.RecordTypeId = recordTypeId;
            if(accCompany != null){
                newCase.Vazquez_Group_Company__c = accCompany;
            }
            
            if(contact != null){
                newCase.ContactId = contact.Id;
            }
             if(accountId != null){
                newCase.AccountId = accountId;
            }
            newCase.ManualCreation__c = true;

            if(fieldValues != null || !fieldValues.isEmpty()){
                for(String fieldName :fieldValues.keySet()){
                    if(Schema.sObjectType.Case.fields.getMap().containsKey(fieldName)){
                          if(isNumericField(fieldName)){
                            newCase.put(fieldName, Integer.valueOf(fieldValues.get(fieldName)));
                          }else if (isDoubleField(fieldName)){
                            newCase.put(fieldName, Double.valueOf(fieldValues.get(fieldName)));
                          }else if(fieldName == 'DateTime__c'){
                              List<String> partsDate = fieldValues.get(fieldName).split('-');
                              Date dateToCase = Date.newInstance(Integer.valueOf(partsDate[0]),Integer.valueOf(partsDate[1]),Integer.valueOf(partsDate[2]));
                              newCase.put(fieldName, dateToCase);
                          }else{
                            newCase.put(fieldName, fieldValues.get(fieldName));
                          }    
                    }
                }
            }


            List<Case_Derivation_Rules__mdt> metadata = [SELECT Id, RecordType__c, Type__c, Reason__c, Origin__c, CaseStatus__c, Priority__c, SLA_Escalado__c , SLA_Derivado__c, SLA_Total__c,Description__c 	
                                                         FROM Case_Derivation_Rules__mdt WHERE RecordType__c = :recordType
             											 AND Type__c = :type AND Reason__c =:reason  AND (CaseStatus__c = 'Escalado' OR CaseStatus__c = 'Cerrado')];

            if(!metadata.isEmpty()){
            	if(metadata.size() > 1){
                	if(newCase.Origin == 'Turnero' || newCase.Origin == 'ROT'){
                    	for(Case_Derivation_Rules__mdt mdt :metadata){
                        	if(mdt.Origin__c == 'Presencial'){
                            	newCase.Priority = mdt.Priority__c;
                                if(mdt.CaseStatus__c == 'Cerrado'){
                                    newCase.Status = mdt.CaseStatus__c;
                                }else{
                                    newCase.Status = 'Nuevo';
                                }
                                if(mdt.Description__c != null){
                                    newCase.Braze_Description__c = mdt.Description__c;
                                }
                                if(mdt.SLA_Escalado__c != null && mdt.SLA_Derivado__c != null && mdt.SLA_Total__c != null){
                    				newCase.SLA_Escalado__c = mdt.SLA_Escalado__c;
                					newCase.SLA_Derivado__c = mdt.SLA_Derivado__c;
                                    newCase.SLA_Total__c = mdt.SLA_Total__c;
                				}
                        	}
                    	}
                	}else{
                    	for(Case_Derivation_Rules__mdt mdt :metadata){
                        	if(mdt.Origin__c == 'Digital'){
                            	newCase.Priority = mdt.Priority__c;
                                if(mdt.CaseStatus__c == 'Cerrado'){
                                    newCase.Status = mdt.CaseStatus__c;
                                }else{
                                    newCase.Status = 'Nuevo';
                                }
                                if(mdt.Description__c != null){
                                    newCase.Braze_Description__c = mdt.Description__c;
                                }
                                if(mdt.SLA_Escalado__c != null && mdt.SLA_Derivado__c != null && mdt.SLA_Total__c != null){
                    				newCase.SLA_Escalado__c = mdt.SLA_Escalado__c;
                					newCase.SLA_Derivado__c = mdt.SLA_Derivado__c;
                                    newCase.SLA_Total__c = mdt.SLA_Total__c;
                				}
                        	}
                    	}
                	}
                }else{
                    newCase.Priority = metadata[0].Priority__c;
                    if(metadata[0].CaseStatus__c == 'Cerrado'){
                        newCase.Status = metadata[0].CaseStatus__c;
                    }else{
                        newCase.Status = 'Nuevo';
                    }
                    if(metadata[0].Description__c != null){
                        newCase.Braze_Description__c = metadata[0].Description__c;
                    }
                    if(metadata[0].SLA_Escalado__c != null && metadata[0].SLA_Derivado__c != null && metadata[0].SLA_Total__c != null){
                    	newCase.SLA_Escalado__c = metadata[0].SLA_Escalado__c;
                		newCase.SLA_Derivado__c = metadata[0].SLA_Derivado__c;
                        newCase.SLA_Total__c = metadata[0].SLA_Total__c;
                	}
                }
        	}
            Database.SaveResult sr = Database.insert(newCase);
            if(!sr.isSuccess()){
                System.debug('sr.getErrors() '+sr.getErrors());
                throw new AuraHandledException('Error al crear el caso: '+sr.getErrors());

            }else{
                System.debug('Guardado exitoso Id: '+ sr.Id);
                caseIdResult = sr.Id;
            }
        }catch(Exception e){
            System.debug(' e.getMessage() '+ e.getMessage());
            throw new AuraHandledException('Error al crear el caso: '+ e.getMessage());
        }
        return caseIdResult;
    }
    
    private static Boolean isNumericField(String fieldName){
        try{
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get('Case');
            Schema.DescribeSObjectResult objectDescription = sObjectType.getDescribe();
            Schema.SObjectField field =  objectDescription.fields.getMap().get(fieldName.toLowerCase());
            Schema.DisplayType fieldType = field.getDescribe().getType();

            return fieldType == Schema.DisplayType.Integer ||
            fieldType == Schema.DisplayType.Currency ||
            fieldType == Schema.DisplayType.Percent;
        }catch(Exception e){
            System.debug('Error '+ e.getMessage());
            return false;
        }
    }
    
    private static Boolean isDoubleField(String fieldName){
        try{
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get('Case');
            Schema.DescribeSObjectResult objectDescription = sObjectType.getDescribe();
            Schema.SObjectField field =  objectDescription.fields.getMap().get(fieldName.toLowerCase());
            Schema.DisplayType fieldType = field.getDescribe().getType();

            return fieldType == Schema.DisplayType.Double;
        }catch(Exception e){
            System.debug('Error '+ e.getMessage());
            return false;
        }
    }
    @AuraEnabled
    public static Boolean checkIfIsFirstAssign(Id caseId){
        Boolean isSecondAAssignment = false;
        List<CaseHistory> caseHistories = [SELECT Field, OldValue, NewValue FROM CaseHistory WHERE CaseId = :caseId AND Field = 'Status'];
        for(CaseHistory ch :caseHistories){
            if(ch.OldValue == 'Asignado'){
                isSecondAAssignment = true;
            }
        }
        return isSecondAAssignment;
    }

    @AuraEnabled(cacheable=true)
    public static String getObjectType(Id recordId){
        if(recordId == null) return null;
        return recordId.getSObjectType().getDescribe().getName();
    }

    @AuraEnabled(cacheable=false)
    public static Contact getPersonAccountContact(String accountId) {

        Account currentAccount = AccountDAO.getAccountById(accountId);
        Contact personContact;

        if(currentAccount.IsPersonAccount == true){
            personContact = [SELECT Id FROM Contact WHERE Id =: currentAccount.PersonContactId];
        }

        return personContact;
    }
    
    @AuraEnabled(cacheable=false)
    public static String getAccountCompanyKey(String idCompanyName){
        String accCompanyName;
        List<Account> companies = [SELECT Id,GroupCompaniesUeno__c FROM Account WHERE Id = :idCompanyName LIMIT 1];
        if(!companies.isEmpty()){
            accCompanyName = companies[0].GroupCompaniesUeno__c;
        }
        return accCompanyName;
    }

    private static Id getAccountCompany(String companyName){
        Id accCompanyId;
        List<Account> companies = [SELECT Id FROM Account WHERE GroupCompaniesUeno__c = :companyName LIMIT 1];
        if(!companies.isEmpty()){
            accCompanyId = companies[0].Id;
        }
        return accCompanyId;
    }
    
    private static Map<String, Group> getQueues() {
        Map<String, Group> queuesByName = new Map<String, Group> ();
        for(Group g :[SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue']){
            queuesByName.put(g.DeveloperName, g);
        }
        return queuesByName;
    }

    private static Boolean itIsNewCompanyMetadata(List<Case_Derivation_Rules__mdt> metadata){
        Integer index=0;
        while(index<metadata.size() && metadata[index].DeveloperName!='RDC_0132'){
            index++;
        }
        if(index==metadata.size()){
            return false;
        }
        return true;
    }
}