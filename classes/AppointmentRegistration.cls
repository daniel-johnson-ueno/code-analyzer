/**
 * @name               : AppointmentRegistration
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 28-02-2025
 * @modification date  : 10-03-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Clase utilitaria que registra encola citas de Turnero
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   28-02-2025   Alvaro Gonzales Lapponi   Initial Version
**/
public with sharing class AppointmentRegistration {
    
    static final Map<String,String> TIPODOCUMENTOFLOWMAP = new Map<String,String>{
        '1'=>'CEDULA DE IDENTIDAD PARAGUAYA',
        '2'=>'PASAPORTE',
        '6'=>'REGISTRO UNICO DEL CONTRIBUYENTE'
    };
        
    static final List<String> ATTENTIONTYPES = new List<String>{'Operaciones', 'Experiencia', 'Comercial'};

    private static Account oficina;
    private static Id owner;

    /**
    * @description Crea caso y cita según corresponda y devuelve sus Ids en un mapa
    * @param Request data
    * @return Map<String,Id>
    */
    public static Map<String,Id> queueAppointment(Request data){
        Map<String,Id> idMap = new Map<String,Id>();
        Savepoint svPoint = Database.setSavepoint();
        
        try{
            Account acc = getClientDetail(data.accountId);
            Id caseId = createCase(data, acc);
            idMap.put('case', caseId);
            
            if(data.queueable){
                Id appointmentId = createAppointment(data, caseId);
                idMap.put('appointment',appointmentId);
            }
            
        } catch(Exception e){
            Database.rollback(svPoint);
            throw new ErrorDeCitaException('Error al crear la cita o el caso: ' + e.getMessage());
        }
        
        return idMap;
    }
    
    /**
    * @description Crea el caso
    * @param Request data
    * @param Id caseId
    * @return Id
    */
    private static Id createCase(Request data, Account acc){
        Case caso = new Case();
        Account office = getOffice();
        caso.Status = data.closedCase ? 'Cerrado' : 'Nuevo';
        caso.Origin = data.origin;
        caso.Description = data.description;
        caso.AppointmentPhone__c = data.phoneNumber;
        caso.CustomerServiceCenter__c = office.Name;
        caso.RequirePriorityAttention__c = data.requirePriority;
        caso.ClientProduct__c = data.procedure;
        caso.ClientSubproduct__c = data.subprocedure;
		caso.RecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Consulta').getRecordTypeId();
        caso.AppointmentPersonType__c = data.personType;
        caso.AccountId = acc.Id;
        caso.ContactId = acc.IsPersonAccount ? acc.PersonContactId : null;
        caso.OwnerId = data.closedCase ? getOwner('TurneroClosedCases') : getOwner(office.Name);
        caso.Vazquez_Group_Company__c = getCompany(data.company).Id;
        if( (acc.Id != getNoClienteId() ) ){
            caso.DocumentNumber__c = acc.DocumentNumber__c;
            caso.DocumentType__c = TIPODOCUMENTOFLOWMAP.get(acc.DocumentType__c);
            caso.FirstName__c = acc.IsPersonAccount ? acc.FirstName : acc.Name;
            caso.LastName__c = acc.IsPersonAccount ? acc.LastName : null;
        } else{
            caso.DocumentType__c = TIPODOCUMENTOFLOWMAP.get(data.documentType);
            caso.DocumentNumber__c = data.documentNumber;
            caso.FirstName__c = data.firstName;
            caso.LastName__c = data.lastName;
        }
        
        database.insert( caso, AccessLevel.USER_MODE );
        return caso.Id;
    }
    
    /**
    * @description Crea la cita
    * @param Request data
    * @param Id caseId
    * @return Id
    */
    private static Id createAppointment(Request data, Id caseId){
        Appointment__c appointment = new Appointment__c();
        Account office = getOffice();
        appointment.Status__c = 'Ingreso';
        appointment.Account__c = data.accountId;
        appointment.Case__c = caseId;
        appointment.ClientPhoto__c = String.isNotBlank(data.picture) ? '<img src="' + data.picture + '" />' : null;
        appointment.Product__c = data.procedure;
        appointment.Subproduct__c = data.subprocedure;
        appointment.RegistrationDateTime__c = datetime.now();
        appointment.AttentionType__c = data.attentionProfile;
        appointment.ExperienceCenter__c = office.Id;
        appointment.OwnerId = getOwner(office.Name);
        appointment.RequirePriorityAttention__c = data.requirePriority;
        database.insert( appointment, AccessLevel.USER_MODE );
        return appointment.Id;
    }
    
    /**
    * @description Obtiene info del cliente si existe y si no, devuelve el registro "No Cliente"
    * @param Id accountId 
    * @return Account
    */
    private static Account getClientDetail(Id accountId){
        Account acc = new Account();
        if(accountId != null){
            acc = [SELECT Id, FirstName, LastName, Name, DocumentNumber__c, DocumentType__c, isPersonAccount, PersonContactId
                   FROM Account WHERE Id =: accountId
                   WITH USER_MODE LIMIT 1];
            
        }
        return acc;
    }
    
    private static Account getCompany(String company){
        
        return [SELECT Id
                FROM Account
                WHERE RecordType.DeveloperName = 'Vazquez_Group_Company' AND GroupCompaniesUeno__c =: company
               	WITH USER_MODE];
    }
    
    private static Account getOffice(){
        if(oficina == null){
            Id userId = UserInfo.getUserId();
            User currentUser = [SELECT Office__c FROM User WHERE Id =: userId LIMIT 1];
            Decimal officeNumber = Decimal.valueOf(currentUser.Office__c);
            oficina = [
                SELECT Id, Name, ParentId, Parent.Name, Parent.GroupCompaniesUeno__c
                FROM Account
                WHERE Numero_Oficina__c =: officeNumber AND RecordType.DeveloperName = 'Internal_Company' AND Parent.GroupCompaniesUeno__c = 'UENO_BANK'
                LIMIT 1
            ];            
        }
        return oficina;
    }
    
    private static Id getOwner(String queue){
        queue = cleanString(queue);
        owner = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName =: queue LIMIT 1].Id;
        return owner;
    }
    
    private static Id getNoClienteId(){
        String orgId15 = UserInfo.getOrganizationId().substring(0, 15);
        General_Setting__mdt generalSettings = [SELECT No_Cliente_Id__c FROM General_Setting__mdt WHERE Id__c =: orgId15 LIMIT 1];
        Account acc = new Account();
        if(Test.isRunningTest()){
            acc = [SELECT Id
                   FROM Account WHERE Name = 'No Cliente'
                   WITH USER_MODE LIMIT 1];
        }else{
            acc = [SELECT Id
                   FROM Account WHERE Id =: generalSettings.No_Cliente_Id__c
                   WITH USER_MODE LIMIT 1];
        }
        return acc.Id;
    }
    
    private static String cleanString(String input) {
        if(String.isEmpty(input)) {
            return '';
        }
        // Eliminar espacios y paréntesis
        String cleanStr = input.replaceAll('[ ()]', '');
        // Reemplazar tildes y ñ
        Map<String, String> tildesMap = new Map<String, String>{
            'á' => 'a', 'é' => 'e', 'í' => 'i', 'ó' => 'o', 'ú' => 'u', 'ñ' => 'n',
            'Á' => 'A', 'É' => 'E', 'Í' => 'I', 'Ó' => 'O', 'Ú' => 'U', 'Ñ' => 'N', '-' => '_'
        };
        for (String key : tildesMap.keySet()) {
            cleanStr = cleanStr.replaceAll(key, tildesMap.get(key));
        }
        return cleanStr;
    }
    
    public class ErrorDeCitaException extends Exception {}
    
    public class Request{
        public String origin;
        public Id accountId;
        public Boolean queueable;
        public Boolean closedCase;
        public String attentionProfile;
        public String company;
        public String personType;
        public String documentType;
        public String documentNumber;
        public String firstName;
        public String lastName;
        public String procedure;
        public String subprocedure;
        public Boolean requirePriority;
        public String phoneNumber;
        public String picture;
        public String description;
    }
    
}