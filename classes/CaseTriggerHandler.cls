public class CaseTriggerHandler {
    
    /**
    
    La idea es ir refactorizando y agregando los metodos llamados desde el trigger 
    de case a esta nueva clase.

    **/

    public static String STATUS_NUEVO = Label.CaseStatus_New;
    public static String STATUS_ASIGNADO = Label.CaseStatus_FirstStatus;
    public static String ESCALAMIENTO_1 = Label.CaseStatus_SecondStatus;
    public static String ESCALAMIENTO_2 = Label.CaseStatus_ThirdStatus;
    public static String BLOQUEADO = Label.CaseStatus_FourthStatus;
    public static String DICTAMEN_FINAL = Label.CaseStatus_FifthStatus;
    public static String STATUS_VALIDAR = Label.CaseStatus_Validate;
    public static String STATUS_CERRADO = Label.CaseStatus_Close;
    public static Map<Id, RecordType> recordTypes = getRecordTypes();
    public static Map<String, Group> queuesByDeveloperName = getQueues();
    public static Map<Id, String> caseErrors = new Map<Id, String>(); 
    public static List<Case_Derivation_Rules__mdt> metadatas = Case_Derivation_Rules__mdt.getAll().values();
    public static List<General_Setting__mdt> generalSettings = General_Setting__mdt.getAll().values();
 

    public static void handleCaseStatuses(List<Case> newCases, Map<Id,Case> oldCasesMap) {
        List<Case> casesToProcess = new List<Case>();
        Map<Id,Case> casesToCloseRelatedAppointment = new Map<Id,Case>();
        List<Case> casesToUpdateExecutive = new List<Case>();
    
        for(Case currentNewCase: newCases){
            Case oldCase = oldCasesMap.get(currentNewCase.Id);
            if((oldCase.Status != currentNewCase.Status) && (!IncidentCaseTriggerHandler.isCaseWithIncidentRelated(currentNewCase,oldCase))){
                casesToProcess.add(currentNewCase);
                if(oldCase.Status == STATUS_ASIGNADO && (currentNewCase.Status == ESCALAMIENTO_1 || currentNewCase.Status == STATUS_CERRADO || (currentNewCase.Status == 'Nuevo' && currentNewCase.ROTDerivation__c == true && currentNewCase.Origin == 'Turnero'))){
                    casesToCloseRelatedAppointment.put(currentNewCase.Id,currentNewCase);
                }
            }
        }

        if(casesToProcess.isEmpty()) return;

        Map<Id, List<Appointment__c>> appointmentsByCaseMap = new Map<Id, List<Appointment__c>>();
        List<Appointment__c> appointmentsToUpdate = new List<Appointment__c>();
        if(casesToCloseRelatedAppointment.size() > 0){
            appointmentsByCaseMap = getAppointmentsByCase(casesToCloseRelatedAppointment);
        }

        //Mapa de la metadata ordenada por la key   .
        Map<String, List<Case_Derivation_Rules__mdt>> metadataIndex = indexMetadata(metadatas);
        List<PermissionSetAssignment> lstPSAssign = [SELECT PermissionSet.Name, AssigneeId 
                                                        FROM PermissionSetAssignment 
                                                        WHERE Assignee.Id =:UserInfo.getUserId() AND PermissionSet.Name='ByPass_Validation_Rules'];

        Id tutiCompanyId = [SELECT Id,GroupCompaniesUeno__c FROM Account WHERE GroupCompaniesUeno__c = 'TUTI' LIMIT 1].Id;

        for(Case cs: casesToProcess){
            Case oldCase = oldCasesMap.get(cs.Id);
            if (oldCase.Status == STATUS_CERRADO &&  lstPSAssign.size()<=0){
                caseErrors.put(cs.Id, String.format('No se puede cambiar de estado una vez cerrado el caso.',new List<String>()));
            }

            //Verifica si cambia de estado de nuevo a asignado o de en validacion a cerrado
            if (setExecutiveOnPresencialCase(oldCase, cs) ){
                if(cs.Executive__c == null){
                    casesToUpdateExecutive.add(cs);
                }
            }

            if (isInitialStatus(oldCase.Status) && !areInitialFieldsComplete(cs) && lstPSAssign.size()<=0 ) {
                caseErrors.put(cs.Id, String.format(Label.CaseStatus_Error_InitialFields, new List<String>()));
                //continue;
            }

            //Verifica si el nuevo estado requiere buscar la metadata
            if (requiresMetadataValidation(cs.Status) && cs.Status != STATUS_CERRADO && (cs.SendToROT__c == true || cs.ROTDerivation__c == false)) {

                if(oldCase.Status == STATUS_ASIGNADO && (cs.Description == null || cs.Subject  == null) && lstPSAssign.size()<=0 ){
                    System.debug('error 1');
                    System.debug(lstPSAssign);
                    caseErrors.put(cs.Id, String.format('Se deben completar los campos Asunto y Descripción para avanzar al siguiente estado.', new List<String>()));
                }else{
                    //Busca la metadata
                    Case_Derivation_Rules__mdt selectedMeta = findRelevantMetadata(metadataIndex, recordTypes, cs, oldCase.Status);/*, newCase.Status, newCase.Origin*/
                    if(selectedMeta != null){
                        if(selectedMeta.CaseStatus__c != cs.Status && cs.Status != BLOQUEADO){
                            caseErrors.put(cs.Id, String.format('No se encontro un area para el estado seleccionado se debera pasar a un estado anterior validar o cerrar el caso.', new List<String>()));
                        }else if(selectedMeta.CaseStatus__c == cs.Status){
                            updateCaseFromMetadata(cs, selectedMeta);
                        }
                    }
                }

            }else if(cs.SendToROT__c == false && cs.ROTDerivation__c == true && cs.Status == ESCALAMIENTO_1){
                cs.Status = 'Nuevo';
                cs.SendToROT__c = true;
                if(queuesByDeveloperName.get('Nomina_ROT') != null){
                    cs.OwnerId = queuesByDeveloperName.get('Nomina_ROT').Id;
                }
            }else if(cs.Status == STATUS_CERRADO){
                if((cs.Description == null || cs.Subject  == null)&& lstPSAssign.size()<=0){
                    System.debug('error 2');
                    caseErrors.put(cs.Id, String.format('Se deben completar los campos Asunto y Descripción para avanzar al siguiente estado.', new List<String>()));
                }
                if(cs.Resolution__c == null && lstPSAssign.size()<=0){
                    caseErrors.put(cs.Id, String.format('Se deben completar el campo Resolución para cerrar el caso.', new List<String>()));
                }
            }

            if(oldCase.Status == STATUS_ASIGNADO && (cs.Status == ESCALAMIENTO_1 || cs.Status == STATUS_CERRADO || (cs.Status == 'Nuevo' && cs.ROTDerivation__c == true && cs.Origin == 'Turnero'))){
                closeRelatedAppointment(cs, appointmentsByCaseMap, appointmentsToUpdate);
            }

            if (isRestrictedClosing(oldCase.Status, cs.Status) && !isClosingAllowed(oldCase, metadataIndex, recordTypes) && lstPSAssign.size() <= 0){
                caseErrors.put(cs.Id, Label.CaseStatus_Error_Closing);
            }

            if(cs.Status == STATUS_VALIDAR){
                if(recordTypes.get(cs.RecordTypeId) != null) {
                    if(recordTypes.get(cs.RecordTypeId).DeveloperName == 'Reclamo_Fraude'){
                        if(queuesByDeveloperName.get(Label.QueueReclamoFraude_DN) != null){
                            cs.OwnerId = queuesByDeveloperName.get(Label.QueueReclamoFraude_DN).Id;
                        }
                    }else if(cs.Origin != null){
                        if(cs.Origin == 'Turnero' || cs.Origin == 'ROT'){
                            if(queuesByDeveloperName.get(Label.QueuePresencial_DN) != null){
                                cs.OwnerId = queuesByDeveloperName.get(Label.QueuePresencial_DN).Id;
                            }
                        }else if(cs.Origin == 'Teléfono'){
                            if(queuesByDeveloperName.get(Label.QueueTelefono_DN) != null){
                                cs.OwnerId = queuesByDeveloperName.get(Label.QueueTelefono_DN).Id;
                            }
                        }else if(cs.Origin == 'BOT'){
                            if(queuesByDeveloperName.get(Label.QueueBOT_DN) != null){
                                cs.OwnerId = queuesByDeveloperName.get(Label.QueueBOT_DN).Id;
                            }
                        }else if(cs.Origin.startsWith('Konnect Insights')){
                            if(queuesByDeveloperName.get(Label.QueueRRSS_DN) != null){
                                cs.OwnerId = queuesByDeveloperName.get(Label.QueueRRSS_DN).Id;
                            }
                            //A la fecha solo tenemos e2c de empresas
                        } else if(cs.Origin == 'Email'){
                            if(queuesByDeveloperName.get(Label.QueueEmailEmpresas_DN) != null){
                                if(cs.Vazquez_Group_Company__c != null){
                                    if(cs.Vazquez_Group_Company__c == tutiCompanyId){
                                        cs.OwnerId = queuesByDeveloperName.get(Label.QueueEmailTuti_DN).Id;
                                    }
                                }
                                else{
                                    cs.OwnerId = queuesByDeveloperName.get(Label.QueueEmailEmpresas_DN).Id;
                                }
                            }
                        } else if(cs.Origin == 'Instabug'){
                            if(queuesByDeveloperName.get(Label.QueueInstabug_DN) != null){
                                cs.OwnerId = queuesByDeveloperName.get(Label.QueueInstabug_DN).Id;
                            }
                        }
                        else if(cs.Origin == 'Whatsapp'){
                            if(cs.Vazquez_Group_Company__c != null){
                                if(cs.Vazquez_Group_Company__c == tutiCompanyId){
                                    cs.OwnerId = queuesByDeveloperName.get(Label.QueueEmailTuti_DN).Id;
                                }
                            }
                        }
                    }
                }
            }

            if(caseErrors != null || !caseErrors.isEmpty()){
                applyErrorsToCases(caseErrors, new List<Case> {cs});
            }
        }

        if(appointmentsToUpdate.size() > 0){
            update appointmentsToUpdate;
        }
        if(casesToUpdateExecutive.size() > 0){
            searchOwnerContact(casesToUpdateExecutive);
        }
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


    private static Boolean isInitialStatus(String status) {
        return status == STATUS_ASIGNADO ;
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
    
    public static void searchOwnerContact(List<Case> casesList){
        Boolean createContact = Boolean.valueOf(Label.Enable_Contact_Create);
        List<Contact> contactsToCreate = new List<Contact>();
        List<Error_Log__c> logs = new List<Error_Log__c>();
        Id internalContactId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Internal_Contact').getRecordTypeId();
        Set<Id> userIds = new Set<Id>();
        for(Case cs: casesList){
            userIds.add(cs.OwnerId);
        }

        Map<Id, User> usersById = new Map<Id, User>( [SELECT Id, Email , FirstName, LastName, Profile.Name FROM User WHERE Id IN:userIds]);
        Set<String> emails = new Set<String>();
        for(User u: usersById.values()){
            if(String.isNotBlank(u.Email)) {
                emails.add(u.Email);
            }
        }

        Map<String, Contact> contactsByEmail = new Map<String, Contact>();
        for (Contact c : [SELECT Id, Email FROM Contact WHERE Email IN :emails]) {
            contactsByEmail.put(c.Email, c);
        }

        Map<String, List<Case>> emailToCasesPendingAssignment = new Map<String, List<Case>>();

        for(Case c: casesList){
            User owner = usersById.get(c.OwnerId);
            Contact contact = contactsByEmail.get(owner.Email);
            if(contact != null){
            	c.Executive__c = contact.Id;
        	}else{
                if(createContact){
                    if (!emailToCasesPendingAssignment.containsKey(owner.Email)) {
                        emailToCasesPendingAssignment.put(owner.Email, new List<Case>());
                        Contact userContact = new Contact();
                        userContact.Email = owner.Email;
                        userContact.FirstName = owner.FirstName;
                        userContact.LastName = owner.LastName;
                        userContact.Title = owner.Profile.Name;
                        userContact.UserId__c = owner.Id;
                        userContact.RecordTypeId = internalContactId;
                        userContact.ExecutiveStatus__c = 'Activo';
                        contactsToCreate.add(userContact);
                    }
                    emailToCasesPendingAssignment.get(owner.Email).add(c);
                }else{
                    Error_Log__c log = new Error_Log__c();
                    log.Class_Name__c = 'CaseStatusTriggerHandler';
                    log.Error_Message__c = 'No se encontro un contacto para el usuario '+owner.Id+' relacionado con el caso '+c.Id+'.';
                    log.Method_Name__c = 'searchOwnerContact';
                    logs.add(log);
                }
            }
        }

        List<Database.SaveResult> resultsDB = new List<Database.SaveResult>();
        if(contactsToCreate.size() > 0){
            resultsDB = Database.insert(contactsToCreate, false);
        	for (Integer i = 0; i < resultsDB.size(); i++) {
                Database.SaveResult sr = resultsDB[i];
                String email = contactsToCreate[i].Email;
            	if(!sr.isSuccess()){
                    for (Case c : emailToCasesPendingAssignment.get(email)) {
                        Error_Log__c log = new Error_Log__c();
                        log.Class_Name__c = 'CaseStatusTriggerHandler';
                        log.Error_Message__c = 'Error al insertar el contacto.';
                        log.Execution_Date__c = Datetime.now();
                        logs.add(log);
                    }
                }else{
                    Id contactId = sr.getId();
                    for (Case c : emailToCasesPendingAssignment.get(email)) {
                        c.Executive__c = contactId;
                    }
                }
            }
        }
         if(!logs.isEmpty()){
            Database.insert(logs, false);
        }
    }

    public static Map<Id, List<Appointment__c>> getAppointmentsByCase(Map<Id,Case> casesMap) {
        Map<Id, List<Appointment__c>> returnedMap = new Map<Id, List<Appointment__c>>();
        List<Appointment__c> relatedAppointments = [SELECT Id, Status__c,Case__c FROM Appointment__c WHERE Case__c IN :casesMap.keySet()];
        for(Appointment__c app: relatedAppointments){
            if(!returnedMap.containsKey(app.Case__c)){
                returnedMap.put(app.Case__c, new List<Appointment__c>());
            }
            returnedMap.get(app.Case__c).add(app);
        }
        return returnedMap;
    }

    public static void closeRelatedAppointment (Case newCase, Map<Id, List<Appointment__c>> appointmentsByCase, List<Appointment__c> appToUpdate) {

        List<Appointment__c> relatedAppointments = appointmentsByCase.get(newCase.Id);

        if (relatedAppointments == null || relatedAppointments.isEmpty()){
            return;
        }

        for(Appointment__c app: relatedAppointments){
            if(app.Status__c == 'Llamada'){
                app.Status__c = 'Finalizado';
                app.EndDateTime__c = Datetime.now();
                appToUpdate.add(app);
            }
        }
    }
}