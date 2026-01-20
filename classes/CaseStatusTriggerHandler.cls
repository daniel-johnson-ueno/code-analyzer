public class CaseStatusTriggerHandler {
    
    //Custom labels con los estados del caso
    public static String STATUS_NUEVO = Label.CaseStatus_New;
    public static String STATUS_ASIGNADO = Label.CaseStatus_FirstStatus;
    public static String ESCALAMIENTO_1 = Label.CaseStatus_SecondStatus;
    public static String ESCALAMIENTO_2 = Label.CaseStatus_ThirdStatus;
    public static String BLOQUEADO = Label.CaseStatus_FourthStatus;
    public static String DICTAMEN_FINAL = Label.CaseStatus_FifthStatus;
    public static String STATUS_VALIDAR = Label.CaseStatus_Validate;
    public static String STATUS_CERRADO = Label.CaseStatus_Close;
    //public static String KI_ENDPOINT = Label.KonnectInsightsEndPoint;
    public static Map<Id, RecordType> recordTypes = getRecordTypes();
    public static Map<String, Group> queuesByDeveloperName = getQueues();
    public static Map<Id, String> caseErrors = new Map<Id, String>(); 
    public static List<Case_Derivation_Rules__mdt> metadatas = Case_Derivation_Rules__mdt.getAll().values();
    public static List<General_Setting__mdt> generalSettings = General_Setting__mdt.getAll().values();
    
    /*public static void handleCaseStatus(List<Case> newCases, Map<Id, Case> oldCaseMap) {
        
        //Mapa de la metadata ordenada por la key   .
        Map<String, List<Case_Derivation_Rules__mdt>> metadataIndex = indexMetadata(metadatas);

        String profileName = '';
        Case caseToUpdateExecutive;

        List<PermissionSetAssignment> lstPSAssign = [SELECT PermissionSet.Name, AssigneeId FROM PermissionSetAssignment WHERE Assignee.Id =:UserInfo.getUserId() AND PermissionSet.Name='ByPass_Validation_Rules'];
        
        for (Case c : newCases) {
            Case oldCase = oldCaseMap.get(c.Id);
            if (oldCase.Status == STATUS_CERRADO &&  UserInfo.getProfileId() != Label.ProfileSystemAdminId){
                caseErrors.put(c.Id, String.format('No se puede cambiar de estado una vez cerrado el caso.',new List<String>()));
                continue;

            }
			//Verifica si cambia de estado de nuevo a asignado o de en validacion a cerrado
            if (setExecutiveOnPresencialCase(oldCase, c) ){
                if(c.Executive__c == null){
                    caseToUpdateExecutive = c;
                }
            } 
			//Si el estado actual antes del cambio es nuevo o asignado, no deja avanzar si no tiene los valores basicos completos
            if (isInitialStatus(oldCase.Status) && !areInitialFieldsComplete(c) && lstPSAssign.size()<=0 ) {
                caseErrors.put(c.Id, String.format(Label.CaseStatus_Error_InitialFields, new List<String>()));
                continue;
            }

			//Verifica si el nuevo estado requiere buscar la metadata
            if (requiresMetadataValidation(c.Status) && c.Status != STATUS_CERRADO && c.Status != STATUS_VALIDAR && (c.SendToROT__c == true || c.ROTDerivation__c == false)) {
                
                if(oldCase.Status == STATUS_ASIGNADO && (c.Description == null || c.Subject  == null) && lstPSAssign.size()<=0 ){
                    System.debug('error 1');
                    System.debug(lstPSAssign);
                    caseErrors.put(c.Id, String.format('Se deben completar los campos Asunto y Descripción para avanzar al siguiente estado.', new List<String>()));
                }else{
      				//Busca la metadata 
                	Case_Derivation_Rules__mdt selectedMeta = findRelevantMetadata(metadataIndex, recordTypes, c, oldCase.Status, c.Status, c.Origin);
                    if(selectedMeta != null){
                		if(selectedMeta.CaseStatus__c != c.Status && c.Status != BLOQUEADO){
                    		caseErrors.put(c.Id, String.format('No se encontro un area para el estado seleccionado se debera pasar a un estado anterior validar o cerrar el caso.', new List<String>()));
                		}else if(selectedMeta.CaseStatus__c == c.Status){
                    		updateCaseFromMetadata(c, selectedMeta);
                		}
                	}
                } 
            }else if(c.SendToROT__c == false && c.ROTDerivation__c == true && c.Status == ESCALAMIENTO_1){
                c.Status = 'Nuevo';
            	c.SendToROT__c = true;
            	if(queuesByDeveloperName.get('Nomina_ROT') != null){
                	c.OwnerId = queuesByDeveloperName.get('Nomina_ROT').Id;
            	}    
            }else if(c.Status == STATUS_CERRADO){
                if((c.Description == null || c.Subject  == null)&& lstPSAssign.size()<=0){
                    System.debug('error 2');
                    caseErrors.put(c.Id, String.format('Se deben completar los campos Asunto y Descripción para avanzar al siguiente estado.', new List<String>()));
             	}*//*else if(c.OwnerId != null && c.Subject != 'Cierre Automático'){
                    	if(String.valueOf(c.OwnerId).startsWith('005')){
                    		searchOwnerContact(c,c.OwnerId);
                    	} 
                 } *//*
            }   
            if (isRestrictedClosing(oldCase.Status, c.Status) && !isClosingAllowed(oldCase, metadataIndex, recordTypes)){
                caseErrors.put(c.Id, Label.CaseStatus_Error_Closing);
            }

            if(c.Status == STATUS_VALIDAR){
                if(recordTypes.get(c.RecordTypeId) != null) {
                    if(recordTypes.get(c.RecordTypeId).DeveloperName == 'Reclamo_Fraude'){
                        if(queuesByDeveloperName.get(Label.QueueReclamoFraude_DN) != null){
                        	c.OwnerId = queuesByDeveloperName.get(Label.QueueReclamoFraude_DN).Id;
                    	}
                     }else if(c.Origin != null){
                    	if(c.Origin == 'Turnero' || c.Origin == 'ROT'){
                        	if(queuesByDeveloperName.get(Label.QueuePresencial_DN) != null){
                        		c.OwnerId = queuesByDeveloperName.get(Label.QueuePresencial_DN).Id;
                    		}
                    	}else if(c.Origin == 'Teléfono'){
                        	if(queuesByDeveloperName.get(Label.QueueTelefono_DN) != null){
                        		c.OwnerId = queuesByDeveloperName.get(Label.QueueTelefono_DN).Id;
                    		}
                    	}else if(c.Origin == 'BOT'){
                        	if(queuesByDeveloperName.get(Label.QueueBOT_DN) != null){
                        		c.OwnerId = queuesByDeveloperName.get(Label.QueueBOT_DN).Id;
                    		}
                    	}else if(c.Origin.startsWith('Konnect Insights')){
                        	if(queuesByDeveloperName.get(Label.QueueRRSS_DN) != null){
                        		c.OwnerId = queuesByDeveloperName.get(Label.QueueRRSS_DN).Id;
                    		}
                        //A la fecha solo tenemos e2c de empresas    
                    	} else if(c.Origin == 'Email'){
                        	if(queuesByDeveloperName.get(Label.QueueEmailEmpresas_DN) != null){
                        		c.OwnerId = queuesByDeveloperName.get(Label.QueueEmailEmpresas_DN).Id;
                    		}
                    	} else if(c.Origin == 'Instabug'){
                            if(queuesByDeveloperName.get(Label.QueueInstabug_DN) != null){
                                c.OwnerId = queuesByDeveloperName.get(Label.QueueInstabug_DN).Id;
                            }
                        }
                	} 
                }
            }
        }

        if(caseToUpdateExecutive != null){
            searchOwnerContact(caseToUpdateExecutive, caseToUpdateExecutive.OwnerId);
        }

        if(caseErrors != null || !caseErrors.isEmpty()){
            applyErrorsToCases(caseErrors, newCases);
        }
    }*/

    public static void handleCaseStatus(Case newCase, Case oldCase) {

        //Mapa de la metadata ordenada por la key   .
        Map<String, List<Case_Derivation_Rules__mdt>> metadataIndex = indexMetadata(metadatas);

        String profileName = '';
        Case caseToUpdateExecutive;

        List<PermissionSetAssignment> lstPSAssign = [SELECT PermissionSet.Name, AssigneeId FROM PermissionSetAssignment WHERE Assignee.Id =:UserInfo.getUserId() AND PermissionSet.Name='ByPass_Validation_Rules'];


        if (oldCase.Status == STATUS_CERRADO &&  UserInfo.getProfileId() != Label.ProfileSystemAdminId){
            caseErrors.put(newCase.Id, String.format('No se puede cambiar de estado una vez cerrado el caso.',new List<String>()));

        }

        //Verifica si cambia de estado de nuevo a asignado o de en validacion a cerrado
        if (setExecutiveOnPresencialCase(oldCase, newCase) ){
            if(newCase.Executive__c == null){
                caseToUpdateExecutive = newCase;
            }
        }

        //Si el estado actual antes del cambio es nuevo o asignado, no deja avanzar si no tiene los valores basicos completos
        if (isInitialStatus(oldCase.Status) && !areInitialFieldsComplete(newCase) && lstPSAssign.size()<=0 ) {
            caseErrors.put(newCase.Id, String.format(Label.CaseStatus_Error_InitialFields, new List<String>()));
//            continue;
        }

        //Verifica si el nuevo estado requiere buscar la metadata
        if (requiresMetadataValidation(newCase.Status) && newCase.Status != STATUS_CERRADO && newCase.Status != STATUS_VALIDAR && (newCase.SendToROT__c == true || newCase.ROTDerivation__c == false)) {

            if(oldCase.Status == STATUS_ASIGNADO && (newCase.Description == null || newCase.Subject  == null) && lstPSAssign.size()<=0 ){
                System.debug('error 1');
                System.debug(lstPSAssign);
                caseErrors.put(newCase.Id, String.format('Se deben completar los campos Asunto y Descripción para avanzar al siguiente estado.', new List<String>()));
            }else{
                //Busca la metadata
                Case_Derivation_Rules__mdt selectedMeta = findRelevantMetadata(metadataIndex, recordTypes, newCase, oldCase.Status);/*, newCase.Status, newCase.Origin*/
                if(selectedMeta != null){
                    if(selectedMeta.CaseStatus__c != newCase.Status && newCase.Status != BLOQUEADO){
                        caseErrors.put(newCase.Id, String.format('No se encontro un area para el estado seleccionado se debera pasar a un estado anterior validar o cerrar el caso.', new List<String>()));
                    }else if(selectedMeta.CaseStatus__c == newCase.Status){
                        updateCaseFromMetadata(newCase, selectedMeta);
                    }
                }
            }

        }else if(newCase.SendToROT__c == false && newCase.ROTDerivation__c == true && newCase.Status == ESCALAMIENTO_1){
            newCase.Status = 'Nuevo';
            newCase.SendToROT__c = true;
            if(queuesByDeveloperName.get('Nomina_ROT') != null){
                newCase.OwnerId = queuesByDeveloperName.get('Nomina_ROT').Id;
            }
        }else if(newCase.Status == STATUS_CERRADO){
            if((newCase.Description == null || newCase.Subject  == null)&& lstPSAssign.size()<=0){
                System.debug('error 2');
                caseErrors.put(newCase.Id, String.format('Se deben completar los campos Asunto y Descripción para avanzar al siguiente estado.', new List<String>()));
            }
            if(newCase.Resolution__c == null && lstPSAssign.size()<=0 && !itIsAppointmentBatchClosingTipology(newCase.Type, newCase.Reason)){
                caseErrors.put(newCase.Id, String.format('Se deben completar el campo Resolución para cerrar el caso.', new List<String>()));
            }
        }

        if((oldCase.Status == STATUS_ASIGNADO && newCase.Status == ESCALAMIENTO_1) || (oldCase.Status == STATUS_ASIGNADO && newCase.Status == STATUS_CERRADO) || (oldCase.Status == STATUS_ASIGNADO && newCase.Status == 'Nuevo' && newCase.ROTDerivation__c == true) && newCase.Origin == 'Turnero'){
            closeRelatedAppointment(newCase);
        }

        if (isRestrictedClosing(oldCase.Status, newCase.Status) && !isClosingAllowed(oldCase, metadataIndex, recordTypes) && lstPSAssign.size() <= 0){
            caseErrors.put(newCase.Id, Label.CaseStatus_Error_Closing);
        }

        if(newCase.Status == STATUS_VALIDAR){
            if(recordTypes.get(newCase.RecordTypeId) != null) {
                if(recordTypes.get(newCase.RecordTypeId).DeveloperName == 'Reclamo_Fraude'){
                    if(queuesByDeveloperName.get(Label.QueueReclamoFraude_DN) != null){
                        newCase.OwnerId = queuesByDeveloperName.get(Label.QueueReclamoFraude_DN).Id;
                    }
                }else if(newCase.Origin != null){
                    if(newCase.Origin == 'Turnero' || newCase.Origin == 'ROT'){
                        if(queuesByDeveloperName.get(Label.QueuePresencial_DN) != null){
                            newCase.OwnerId = queuesByDeveloperName.get(Label.QueuePresencial_DN).Id;
                        }
                    }else if(newCase.Origin == 'Teléfono'){
                        if(queuesByDeveloperName.get(Label.QueueTelefono_DN) != null){
                            newCase.OwnerId = queuesByDeveloperName.get(Label.QueueTelefono_DN).Id;
                        }
                    }else if(newCase.Origin == 'BOT'){
                        if(queuesByDeveloperName.get(Label.QueueBOT_DN) != null){
                            newCase.OwnerId = queuesByDeveloperName.get(Label.QueueBOT_DN).Id;
                        }
                    }else if(newCase.Origin.startsWith('Konnect Insights')){
                        if(queuesByDeveloperName.get(Label.QueueRRSS_DN) != null){
                            newCase.OwnerId = queuesByDeveloperName.get(Label.QueueRRSS_DN).Id;
                        }
                        //A la fecha solo tenemos e2c de empresas
                    } else if(newCase.Origin == 'Email'){
                        if(queuesByDeveloperName.get(Label.QueueEmailEmpresas_DN) != null){
                            if(newCase.Vazquez_Group_Company__c != null){
                                if(itIsTutiCase(newCase.Vazquez_Group_Company__c)){
                                    newCase.OwnerId = queuesByDeveloperName.get(Label.QueueEmailTuti_DN).Id;
                                }
                            }
                            else{
                                newCase.OwnerId = queuesByDeveloperName.get(Label.QueueEmailEmpresas_DN).Id;
                            }
                        }
                    } else if(newCase.Origin == 'Instabug'){
                        if(queuesByDeveloperName.get(Label.QueueInstabug_DN) != null){
                            newCase.OwnerId = queuesByDeveloperName.get(Label.QueueInstabug_DN).Id;
                        }
                    }
                    else if(newCase.Origin == 'Whatsapp'){
                        if(newCase.Vazquez_Group_Company__c != null){
                            if(itIsTutiCase(newCase.Vazquez_Group_Company__c)){
                                newCase.OwnerId = queuesByDeveloperName.get(Label.QueueEmailTuti_DN).Id;
                            }
                        }
                    }
                }
            }
        }


        if(caseToUpdateExecutive != null){
            searchOwnerContact(caseToUpdateExecutive, caseToUpdateExecutive.OwnerId);
        }

        if(caseErrors != null || !caseErrors.isEmpty()){
            applyErrorsToCases(caseErrors, new List<Case> {newCase});
        }
    }

    public static void handleCaseClienteDeEmpresa(Case newCase, Case oldCase) {
        if (newCase.AccountId != null){
            if(!itIsNoClienteId(newCase.AccountId) && newCase.Vazquez_Group_Company__c != null){
                persistClientOfCompany(newCase);
                if(itIsTutiCase(newCase.Vazquez_Group_Company__c)){
                    completeCaseEmail(newCase);
                }
            } else {
                return;
            }
        }
        return;
    }

    public static void completeCaseEmail(Case newCase){
        List<Client_of_Company__c> clients = getClientOfCompany(newCase.Vazquez_Group_Company__c,newCase.AccountId);
        if(!clients.isEmpty()){
            if(clients[0].Email__c != null && clients[0].Email__c != ''){
                newCase.Email__c = clients[0].Email__c;
            }
        }
    }

    public static void persistClientOfCompany(Case newCase){
        String caseCompanyId = newCase.Vazquez_Group_Company__c;
        String accountCaseId = newCase.AccountId;
        String companyName = '';
        List<Client_of_Company__c> clients = getClientOfCompany(caseCompanyId,accountCaseId);
        if(clients.isEmpty()){
            List<AccountCreationService.AccountWrapperInput> requests = new List<AccountCreationService.AccountWrapperInput>();
            AccountCreationService.AccountWrapperInput request = new AccountCreationService.AccountWrapperInput();
            Account acc = AccountDAO.getAccountById(accountCaseId);
            companyName = getCompanyName(newCase.Vazquez_Group_Company__c);
            if(companyName == 'UENO_BANK') request.externalId = (acc.PersonCode__c != null) ? String.valueOf(acc.PersonCode__c) : '';
            request.documentNumber = acc.DocumentNumber__c;
            request.documentType = acc.DocumentType__c;
            request.email = acc.PersonEmail;
            request.phone = acc.Phone;
            request.company = companyName;
            request.originOfCreation = 'SF - Caso';
            request.originOfLastModification = 'SF - Caso';
            requests.add(request);
            AccountCreationService.createClientOfCompany(new List<Account>{AccountDAO.getAccountById(accountCaseId)},requests);
        }
    }

    public static Boolean itIsNoClienteId(String accountId){
        Boolean result = false;
        String orgId = UserInfo.getOrganizationId().substring(0, 15);
        for(General_Setting__mdt g :generalSettings){
            if(g.Id__c == orgId){
                if(accountId == g.No_Cliente_Id__c){
                    result = true;
                    break;
                }
            }
        }
        return result;
    }

    public static List<Client_of_Company__c> getClientOfCompany(String caseCompanyId, String accountCaseId){
        return [SELECT id, Client__c, Vazquez_Group_Company__c, Email__c FROM Client_of_Company__c WHERE Vazquez_Group_Company__c = :caseCompanyId AND Client__c = :accountCaseId];
    }

    public static String getCompanyName(String accountId){
        return [SELECT GroupCompaniesUeno__c FROM Account WHERE id = :accountId LIMIT 1].GroupCompaniesUeno__c;
    }

    public static Boolean isFunctionActive(String functionName) {
        if(functionName == 'ClientOfCompanyCreation'){
            enableCreationClientOfCompany__c setting = enableCreationClientOfCompany__c.getOrgDefaults();
            return setting != null && setting.isActive__c;
        }
        return false;
    }

    /*public static void handleCaseTipificacion(List<Case> newCases, Map<Id, Case> oldCaseMap){
        String recordType, type, reason, origin, description, subject;
        Case_Derivation_Rules__mdt metadata, priorityMetada;
        Case caseToUpdate;
        Boolean hasError = false;
        Boolean directClosure = false;
        Id ownerId;
        for (Case c : newCases) {
            Case oldCase = oldCaseMap.get(c.Id);
            if (c.Type != oldCase.Type){
                recordType = recordTypes.get(c.RecordTypeId).DeveloperName;
                type = c.Type;
                reason = c.Reason;
                caseToUpdate = c;
                origin = c.Origin;
                ownerId = c.OwnerId;
                description = c.Description;
                subject = c.Subject;
                } else if(c.Client_left__c != oldCase.Client_left__c && c.Client_left__c){
                    directClosure = true;
                    c.Status = STATUS_CERRADO;
                }
            }  
        if(recordType != '' && type != '' && reason != '' && !directClosure){
            metadata = getMetadataToClose(recordType,type,reason);
        }
        
        if(metadata != null){
            if(description == null || subject == null){
                caseErrors.put(caseToUpdate.Id, String.format('La tipificación seleccionada cierra el caso: se debe completar el Asunto y Descripción.',new List<String>()));
            	 hasError = true;
            }else{
              //  if(caseToUpdate.OwnerId != null){
                    	//if(String.valueOf(caseToUpdate.OwnerId).startsWith('005')){
                    	//	searchOwnerContact(caseToUpdate,caseToUpdate.OwnerId);
                    	//} 
                // } 
                caseToUpdate.Status = STATUS_CERRADO;
            }
        }else if(recordType != '' && type != '' && reason != '' && origin != '' && !directClosure){
            priorityMetada = getMetadataToUpdatePriority(recordType,type,reason,origin);
        }

        if(priorityMetada != null){
            caseToUpdate.Priority = priorityMetada.Priority__c;
        }
        
        if(hasError && (caseErrors != null || !caseErrors.isEmpty())){
            applyErrorsToCases(caseErrors, newCases);
        }
    }*/


    public static void handleCaseTipificacion(Case newCase, Case oldCase){
        String recordType, type, reason, origin, description, subject;
        Case_Derivation_Rules__mdt metadata, priorityMetada;
        Case caseToUpdate;
        Boolean hasError = false;
        Boolean directClosure = false;
        Id ownerId;

            if (newCase.Type != oldCase.Type){
                recordType = recordTypes.get(newCase.RecordTypeId).DeveloperName;
                type = newCase.Type;
                reason = newCase.Reason;
                caseToUpdate = newCase;
                origin = newCase.Origin;
                ownerId = newCase.OwnerId;
                description = newCase.Description;
                subject = newCase.Subject;
            } else if(newCase.Client_left__c != oldCase.Client_left__c && newCase.Client_left__c){
                directClosure = true;
                newCase.Status = STATUS_CERRADO;
                newCase.Close_Reason_Manual__c = Label.CaseClientLeftReasonManual;

                if( String.isEmpty(newCase.Type) && String.isEmpty(newCase.Reason) ) {
                    newCase.Type = Label.CaseClientLeftType;
                    newCase.Reason = Label.CaseClientLeftReason;
                    newCase.recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Consulta').getRecordTypeId();

                    newCase.Subject = Label.CaseClientLeftSubjectDescription;
                    newCase.Description = Label.CaseClientLeftSubjectDescription;
                    newCase.Resolution__c = Label.CaseClientLeftResolution;  
                } 

            }

        if(recordType != '' && type != '' && reason != '' && !directClosure){
            metadata = getMetadataToClose(recordType,type,reason);
        }

        if(metadata != null){
            if(description == null || subject == null){
                caseErrors.put(caseToUpdate.Id, String.format('La tipificación seleccionada cierra el caso: se debe completar el Asunto y Descripción.',new List<String>()));
                hasError = true;
            }else{
                //  if(caseToUpdate.OwnerId != null){
                //if(String.valueOf(caseToUpdate.OwnerId).startsWith('005')){
                //	searchOwnerContact(caseToUpdate,caseToUpdate.OwnerId);
                //}
                // }
                caseToUpdate.Status = STATUS_CERRADO;
            }
        }else if(recordType != '' && type != '' && reason != '' && origin != '' && !directClosure){
            priorityMetada = getMetadataToUpdatePriority(recordType,type,reason,origin);
        }

        if(priorityMetada != null){
            caseToUpdate.Priority = priorityMetada.Priority__c;
        }

        if(hasError && (caseErrors != null || !caseErrors.isEmpty())){
            applyErrorsToCases(caseErrors, new List<Case> {newCase});
        }
    }
    
    private static Case_Derivation_Rules__mdt getMetadataToClose(String recordType, String type, String reason){

        Case_Derivation_Rules__mdt tipMetadata;
        List<Case_Derivation_Rules__mdt> tipMetadatas = new List<Case_Derivation_Rules__mdt>();
        for(Case_Derivation_Rules__mdt meta :metadatas){
            if(meta.RecordType__c == recordType && meta.Type__c == type 
               && meta.Reason__c == reason && meta.CaseStatus__c == STATUS_CERRADO){
                tipMetadatas.add(meta);
            }
        }
        
        if(tipMetadatas.size() > 0){
            tipMetadata = tipMetadatas[0];
        }else{
            tipMetadata = null;
        }
        return tipMetadata;
    }

    private static Case_Derivation_Rules__mdt getMetadataToUpdatePriority(String recordType, String type, String reason, String origin){
        Case_Derivation_Rules__mdt tipMetadata;
        String originMetadata;
        if(origin == 'Turnero' || origin == 'ROT' ){
            originMetadata = 'Presencial';
        }else{
            originMetadata = 'Digital';
        }
        List<Case_Derivation_Rules__mdt> tipMetadatas = new List<Case_Derivation_Rules__mdt>();
        for(Case_Derivation_Rules__mdt meta :metadatas){
            if(meta.RecordType__c == recordType && meta.Type__c == type 
               && meta.Reason__c == reason && meta.CaseStatus__c == ESCALAMIENTO_1){
                tipMetadatas.add(meta);
            }
        }    
        
        if(tipMetadatas.size() > 1){
            for(Case_Derivation_Rules__mdt meta :tipMetadatas){
                if(meta.Origin__c == originMetadata){
                    tipMetadata = meta;
                }
            }
        }else if(tipMetadatas.size() > 0){    
            tipMetadata = tipMetadatas[0];
        }else{
            tipMetadata = null;
        }
        return tipMetadata;
    }

    private static Map<Id, RecordType> getRecordTypes() {
        return new Map<Id, RecordType>(
            [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Case']
        );
    }

    private static Map<String, Group> getQueues() {
        Map<String, Group> queuesByName = new Map<String, Group> ();
        for(Group g :[SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue']){
            queuesByName.put(g.DeveloperName, g);
        }
        return queuesByName;
    }

    private static Map<String, List<Case_Derivation_Rules__mdt>> indexMetadata(List<Case_Derivation_Rules__mdt> metadatas) {
        Map<String, List<Case_Derivation_Rules__mdt>> metadataIndex = new Map<String, List<Case_Derivation_Rules__mdt>>();
        for (Case_Derivation_Rules__mdt meta : metadatas) {
            String key = meta.RecordType__c + ':' + meta.Type__c + ':' + meta.Reason__c;
            if (!metadataIndex.containsKey(key)) {
                metadataIndex.put(key, new List<Case_Derivation_Rules__mdt>());
            }
            metadataIndex.get(key).add(meta);
        }
        return metadataIndex;
    }

    private static boolean setExecutiveOnPresencialCase (Case oldCase, Case newCase) {
        if (newCase.Tipo_de_Canal__c == 'Presencial'){
            if ((newCase.ManualCreation__c != TRUE  && oldCase.Status != newCase.Status && newCase.Status == STATUS_ASIGNADO) || (newCase.ManualCreation__c == TRUE && newCase.Status == STATUS_NUEVO)) {
                return true;
            }
        }
        return false;
    }

    private static Boolean isIrrelevantStatusChange(String oldStatus, String newStatus) {
        return (oldStatus == STATUS_NUEVO && newStatus == STATUS_ASIGNADO);
    }

    private static Boolean isInitialStatus(String status) {
        return status == STATUS_ASIGNADO;
    }

    private static Boolean areInitialFieldsComplete(Case c) {
        return !String.isBlank(c.RecordTypeId) && !String.isBlank(c.Type) && !String.isBlank(c.Reason);
    }

    private static Boolean requiresMetadataValidation(String status) {
         Boolean result = status != STATUS_ASIGNADO && status != STATUS_VALIDAR;
        return result;
    }

    private static Case_Derivation_Rules__mdt findRelevantMetadata(Map<String, List<Case_Derivation_Rules__mdt>> metadataIndex, Map<Id, RecordType> recordTypes, Case currentCase, String oldStatus) {/*, String currentStatus, String origin*/


        String key = recordTypes.get(currentCase.RecordTypeId).DeveloperName + ':' + currentCase.Type + ':' + currentCase.Reason;
        List<Case_Derivation_Rules__mdt> relevantMetas = metadataIndex.get(key);
        if (relevantMetas == null || relevantMetas.isEmpty()) return null;
        if(relevantMetas.size() > 1){
           
            return findMetadataForStatus(relevantMetas, oldStatus, currentCase.Status, currentCase.Origin);
        }else{
            return relevantMetas[0];
        }
    }

  	private static Case_Derivation_Rules__mdt findMetadataForStatus(List<Case_Derivation_Rules__mdt> metadatas, String oldStatus, String currentStatus, String origin) {
		List<Case_Derivation_Rules__mdt> tipToReturn = new List<Case_Derivation_Rules__mdt> ();
      	Case_Derivation_Rules__mdt metadataToReturn;
        for (Case_Derivation_Rules__mdt meta : metadatas) {
            if(oldStatus == STATUS_NUEVO || oldStatus == STATUS_ASIGNADO){
                if(meta.CaseStatus__c == ESCALAMIENTO_1){
                    tipToReturn.add(meta);
                }
            }else if(oldStatus == ESCALAMIENTO_1 ){
                if(meta.CaseStatus__c == ESCALAMIENTO_2){
                    tipToReturn.add(meta);
                }
            }else if(oldStatus == ESCALAMIENTO_2 ){
                if(meta.CaseStatus__c == BLOQUEADO){
                    tipToReturn.add(meta);
                }
            }else if(oldStatus == BLOQUEADO ){
                if(meta.CaseStatus__c == DICTAMEN_FINAL){
                    tipToReturn.add(meta);
                }
            }
        }
      if(!tipToReturn.isEmpty()){
      	if(tipToReturn.size() > 1){
          for(Case_Derivation_Rules__mdt meta :tipToReturn){
              if (meta.Origin__c == 'Presencial' && (origin == 'Turnero' || origin == 'ROT')) {
                  metadataToReturn = meta;
              } else if (meta.Origin__c == 'Digital' && origin != 'Turnero'  && origin != 'ROT') {
                  metadataToReturn = meta;
              }
          }
          
      }else{
          metadataToReturn =  tipToReturn[0];
      }
	} 
      return metadataToReturn;
    }
               
    private static Boolean areRequiredFieldsComplete(Case c, Case_Derivation_Rules__mdt meta) {

        if(meta.RequiredFields__c != null) {
            String[] fields = meta.RequiredFields__c.split(';');
            if(!fields.isEmpty()){
                for (String field : fields) {
                    if (String.isBlank(String.valueOf(c.get(field.trim()))) ){
                        return false;
                    }
                }
            }
        }
        return true;
    }
	//Modificacion por UEN-1271 Vero Zarza
    private static void updateCaseFromMetadata(Case c, Case_Derivation_Rules__mdt meta) {
        List<TipificacionesJira__mdt> metadatasJira = TipificacionesJira__mdt.getAll().values();
        Boolean blockByJira = false;
        Boolean manageROT = meta.Gestiona_ROT_Operaciones__c && c.ROTDerivation__c && c.SendToROT__c && meta.CaseStatus__c == 'Escalado' && c.Input_channel__c == 'Turnero';
        for(TipificacionesJira__mdt jira :metadatasJira){
            if(jira.Reason__c == meta.Reason__c && jira.Type__c == meta.Type__c && 
                jira.RecordType__c == meta.RecordType__c && (c.Status == ESCALAMIENTO_1||c.Status == ESCALAMIENTO_2) && c.Status==meta.CaseStatus__c &&
                meta.CaseOwnerQueue__c=='Producto'){
                    blockByJira = true;
            }
        }

        if(blockByJira){
            c.Status = BLOQUEADO;
        }else{
            if(manageROT && queuesByDeveloperName.get(Label.QueueROT_OperacionesDN) != null){
            	c.OwnerId = queuesByDeveloperName.get(Label.QueueROT_OperacionesDN).Id;
            }
            c.Status = meta.CaseStatus__c;
            if(meta.EmailTemplateCode__c != null && c.Status == ESCALAMIENTO_1){
                invokeFlowSendEmail(meta.EmailTemplateCode__c, c);
            }
        }

        if(queuesByDeveloperName.get(meta.CaseOwnerQueue__c) != null && !manageROT){
            c.OwnerId = queuesByDeveloperName.get(meta.CaseOwnerQueue__c).Id;
        }
    }

    private static void invokeFlowSendEmail(String templateCode, Case c){
        try{
            Map<String,Object> flowInputs = new Map<String,Object>();
            flowInputs.put('varTemplateCode', templateCode);
            flowInputs.put('varCase', c);
            Flow.Interview flow = Flow.Interview.createInterview('Case_Send_escalation_email',flowInputs);
            flow.start();
        }catch(Exception e){
            System.debug('Error al invocar el flow: '+e.getMessage());
        }
    }

    private static Boolean isRestrictedClosing(String oldStatus, String newStatus) {
        return newStatus == STATUS_CERRADO && (oldStatus == ESCALAMIENTO_1 || 
                                               oldStatus == ESCALAMIENTO_2 || oldStatus == BLOQUEADO );
    }

    private static Boolean isClosingAllowed(Case oldCase, Map<String, List<Case_Derivation_Rules__mdt>> metadataIndex, Map<Id, RecordType> recordTypes) {
        String key = recordTypes.get(oldCase.RecordTypeId).DeveloperName + ':' + oldCase.Type + ':' + oldCase.Reason;
        List<Case_Derivation_Rules__mdt> relevantMetas = metadataIndex.get(key);
        if (relevantMetas == null || relevantMetas.isEmpty()) return true;

        if(!relevantMetas.isEmpty()){
        	if (!areRequiredFieldsComplete(oldCase, relevantMetas[0])) {
                return false;
        	}
        }
        return true;
    }

    private static void applyErrorsToCases(Map<Id, String> errors, List<Case> cases) {
        for (Case c : cases) {
            if (errors.containsKey(c.Id)) {
                c.addError(errors.get(c.Id));
            }
        }
    }
    
    public static void searchOwnerContact(Case c,Id userId){
        List<User> usersOwner = [SELECT Id, Email , FirstName, LastName, Profile.Name FROM User WHERE Id =:userId LIMIT 1];
        Boolean createContact = Boolean.valueOf(Label.Enable_Contact_Create);
      
        List<Contact> contactsToCreate = new List<Contact>();
        List<Contact> contactsOwner = new List<Contact> ();
        List<Error_Log__c> logs = new List<Error_Log__c>();
        if(usersOwner.size() > 0){
            contactsOwner = [SELECT Id, Email FROM Contact WHERE  Email = :usersOwner[0].Email LIMIT 1];
        
        	if(contactsOwner.size() > 0){
            	c.Executive__c = contactsOwner[0].Id;
        	}else{
                if(createContact){
                   List<RecordType> rtContact = [SELECT Id, Name  from RecordType WHERE SObjectType = 'Contact' AND Name = 'Contacto Interno'];
					Contact userContact = new Contact();
					userContact.Email = usersOwner[0].Email;
					userContact.FirstName = usersOwner[0].FirstName;
					userContact.LastName = usersOwner[0].LastName;
					userContact.Title = usersOwner[0].Profile.Name;
					userContact.UserId__c = usersOwner[0].Id;
					if(rtContact.size() > 0){
						userContact.RecordTypeId = rtContact[0].Id;
					}
					userContact.ExecutiveStatus__c = 'Activo';
					contactsToCreate.add(userContact);
                }else{
                    Error_Log__c log = new Error_Log__c();
                    log.Class_Name__c = 'CaseStatusTriggerHandler';
                    log.Error_Message__c = 'No se encontro un contacto para el usuario '+usersOwner[0].Id+' relacionado con el caso '+c.Id+'.';
                    log.Method_Name__c = 'searchOwnerContact';
                    logs.add(log);
                }
        	}
      	} 
        List<Database.SaveResult> resultsDB = new List<Database.SaveResult>();
        if(contactsToCreate.size() > 0){
            resultsDB = Database.insert(contactsToCreate, false);
        	for(Database.SaveResult sr :resultsDB){
            	if(!sr.isSuccess()){
                    Error_Log__c log = new Error_Log__c();
                    log.Class_Name__c = 'CaseStatusTriggerHandler';
                    log.Error_Message__c = 'Error al insertar el contacto.';
                    log.Execution_Date__c = Datetime.now();
                    logs.add(log);
                }else{
                    c.Executive__c = sr.getId();
                }
            }
        }
         if(!logs.isEmpty()){
            Database.insert(logs, false);
        }
    }

    public static void closeRelatedAppointment (Case newCase) {

        String test = '';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';
        test +='a';


        Boolean appointmentUpdated = false;
        List<Appointment__c> relatedAppointments = [SELECT Id, Status__c FROM Appointment__c WHERE Case__c = :newCase.Id];
        if(relatedAppointments.size() > 0){
            for (Appointment__c currentAppointment : relatedAppointments) {
                if(currentAppointment.Status__c == 'Llamada'){
                    appointmentUpdated = true;
                    currentAppointment.Status__c = 'Finalizado';
                    currentAppointment.EndDateTime__c = Datetime.now();
                }
            }

            if(appointmentUpdated){
                update relatedAppointments;
            }
        }
    }

    public static Boolean itIsTutiCase(String vazquezGroupCompanyId){
        if(getCompanyName(vazquezGroupCompanyId)=='TUTI') return true;
        return false;
    }

    public static Boolean itIsAppointmentBatchClosingTipology(String type, String reason){
        if(type=='Atencion digital' && reason=='No requiere gestion') return true;
        return false;
    }

   /* public static Boolean checkIfItGoesToRot(List<Case> newCases){
        Boolean isSecondEscalation = false;
        List<CaseHistory> caseHistories = [SELECT Field, OldValue, NewValue FROM CaseHistory WHERE CaseId IN :newCases AND Field = 'Status'];
        for(CaseHistory ch :caseHistories){
            if(ch.OldValue == ESCALAMIENTO_1){
                isSecondEscalation = true;
                
            }
        }
        return isSecondEscalation;
    }*/

      /* public static void assignFirstGroupOwnerId(Map<Id, Case> oldCaseMap,List<Case> newCases) {

        List<Id> caseIds = new List<Id>();

        for(Case c :newCases){
            caseIds.add(c.Id);
        }
        List<CaseHistory> caseHistories = [SELECT Field, OldValue, NewValue, CaseId FROM CaseHistory WHERE CaseId IN :caseIds AND Field = 'Owner'];
        Map<Id, Id> caseIdToGroupOwnerId = new Map<Id, Id>();
        for (CaseHistory history : caseHistories) {
            if (history.OldValue != null && String.valueOf(history.OldValue).startsWith('00G') && !caseIdToGroupOwnerId.containsKey(history.CaseId)) {
                caseIdToGroupOwnerId.put(history.CaseId, (Id) history.OldValue);
            }
        }
        for (Case c : newCases) {
            if (caseIdToGroupOwnerId.containsKey(c.Id)) {
                c.OwnerId = caseIdToGroupOwnerId.get(c.Id);
            }
        }
    }*/

    /*public static void assignFirstUserOwnerId(List<Case> newCases) {

        List<Id> caseIds = new List<Id>();
        CaseHistory firstOwner = null;
        String firstOwnerUser;
        for(Case c :newCases){
            caseIds.add(c.Id);
        }
        List<CaseHistory> caseHistories = [SELECT Field, OldValue, NewValue, CreatedDate FROM CaseHistory WHERE CaseId IN :caseIds AND Field = 'Status' 
                                            ORDER BY CreatedDate ASC];

        for (CaseHistory history : caseHistories) {
            if (history.OldValue != null && history.NewValue == 'Asignado' && firstOwner == null) {
                firstOwner = history;
            }
        }
        if(firstOwner != null) {
        	List<CaseHistory> caseHistoriesOwner = [SELECT Field, OldValue, NewValue FROM CaseHistory WHERE CaseId IN :caseIds AND Field = 'Owner' AND CreatedDate = :firstOwner.CreatedDate
                                            ORDER BY CreatedDate ASC];


        	if (!caseHistoriesOwner.isEmpty()) {
                firstOwnerUser = String.valueOf(caseHistoriesOwner[0].NewValue);
				List<User> users = [SELECT Id, Name FROM User WHERE Name = :firstOwnerUser];
                if(users[0] != null){
                	newCases[0].OwnerId = (Id) users[0].Id;
                 }   
        	}
		}
    }*/
    // public static void handleKonnectInsightsCases(List<Case> newCases, List<Case> oldCases){
    //     for(Case caseOld: oldCases){
    //         if(caseOld.Origin.contains('Konnect Insights')){
    //             for(Case caseNew: newCases){
    //                 if(caseOld.CaseNumber==CaseNew.CaseNumber && caseOld.Status!=CaseNew.Status){
    //                     String url = KI_ENDPOINT;
    //                     String content = KonnectInsightsTicketEventUpdates.JsonContentFromObject(caseNew);
    //                     KonnectInsightsTicketEventUpdates.callout(url, content);
    //                 }
    //             }
    //         }
    //     }
    // }
}