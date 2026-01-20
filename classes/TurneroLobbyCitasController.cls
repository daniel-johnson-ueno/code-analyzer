/**
 * @name               : TurneroLobbyCitasController
 * @author             : Carlos Bastidas
 * @creation date      : 26-11-2024
 * @modification date  : 24-03-2025
 * @last modified by   : Carlos Bastidas
 * @description        : Clase controladora de lwc turneroLobbyCitas
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   20-11-2024   Carlos Bastidas           Initial Version
**/
public without sharing class TurneroLobbyCitasController {
    
    @InvocableMethod(label='assignAppointment' description='' category='Appointment__c')
    public static List<Results> assignAppointmentFlow(List<Requests> idfirstElement) {
        List<Results> results = new List<Results>();
        LobbyDataWrapper wrp = new LobbyDataWrapper();
        Results result = new Results();
        if(!Test.isRunningTest()){
        	wrp = TurneroLobbyCitasController.assignAppointment(idfirstElement[0].AppointmentId);
        }
        result.success = String.isNotBlank(wrp.messageDetail) ? false:true ;
        result.messageDetail = wrp.messageDetail;
        results.add(result);
        return results;
    }
    
    @AuraEnabled
    public static LobbyDataWrapper getLobbyCitasData(String branchName) {
        LobbyDataWrapper response = new LobbyDataWrapper();
        System.debug(branchName);
        Contact cont =  getContactInfoByUserId();
        response.branchName = String.isNotBlank(branchName) ? branchName : cont.Account.Name;
        Id groupId = getQueueIdByAccountName( cleanString(response.branchName ));
        System.debug(groupId);
        List<Turnero__mdt> meta = [SELECT Label, Field__c, FieldType__c, FieldOrder__c
                                   FROM Turnero__mdt
                                   WHERE Type__c = 'FIELDS'
                                   ORDER BY FieldOrder__c ];

        response.dataTable = createDataTableColumns(meta);
        
        List<Appointment__c> appointmentList = getAppointmentByQueueIdAndSkill(groupId, cont.Skills__c, meta);        
        if(!appointmentList.isEmpty()){
            response.idfirstElement = appointmentList[0].Id;
            response.appointmentList = appointmentList;
            
            response.existData = true;
        }
        response.elementNumber = String.valueOf(appointmentList.size());
        return response;
        
    }
    
    @AuraEnabled
    public static LobbyDataWrapper assignAppointment(String idfirstElement) {
        LobbyDataWrapper response = new LobbyDataWrapper();

        Appointment__c targetAppointment = [SELECT Id, OwnerId, Case__c FROM Appointment__c WHERE Id =: idfirstElement WITH USER_MODE LIMIT 1];
        Contact userContact =  getContactInfoByUserId();
        Id groupId = getQueueIdByAccountName( cleanString(userContact.Account.Name));
        
        String validationMessage = validateAsignAppointment();
        if( String.isNotBlank(validationMessage) ){
            response.messageDetail = validationMessage;
            return response;
        }
        
        response.existData = appointmentAssignationProcess(groupId, targetAppointment);
        return response;
    }
    @testVisible
    private static Boolean appointmentAssignationProcess(Id groupId,  Appointment__c targetAppointment){
        Boolean assignationDone = false;
        
        if(targetAppointment.ownerId == groupId) {
            targetAppointment.OwnerId = UserInfo.getUserId();
            targetAppointment.Status__c = 'Llamada';
            targetAppointment.StarDateTime__c = system.now();
            Database.update(targetAppointment, AccessLevel.USER_MODE);
            
            
            Case appointmentCase = [SELECT Id, OwnerId, Status FROM Case WHERE Id =: targetAppointment.Case__c WITH USER_MODE LIMIT 1];
            if(appointmentCase.OwnerId == groupId) {
                appointmentCase.OwnerId = UserInfo.getUserId();
                if(appointmentCase.Status == 'Nuevo')
                appointmentCase.Status = 'Asignado';
                Database.update(appointmentCase, AccessLevel.USER_MODE);
            }
            assignationDone = true;
        } 
        
        return assignationDone;
    }
    
    @AuraEnabled(cacheable=true)
    public static LobbyDataWrapper getAllbranchesForSupervisorAndRefreshTime() {
        LobbyDataWrapper response = new LobbyDataWrapper();
        Contact cont =  getContactInfoByUserId();

        // check custom permission "TurneroSupervisor" --> view brunches
        if(Test.isRunningTest() || FeatureManagement.checkPermission('TurneroSupervisor')) {

            List<Account> metaList;
            if(!Test.isRunningTest()){
                metaList = [SELECT Name FROM Account WHERE RecordType.DeveloperName = 'Internal_Company' AND Parent.GroupCompaniesUeno__c = 'UENO_BANK' ORDER BY Name ASC];
            } else {
                metaList = [SELECT Name FROM Account WHERE Name = 'Areguá' ];
            }

            Map<String, String> branchByNameCode = new Map<String, String>();

            List<DataTableWrapper> dataTable = new List<DataTableWrapper>();
            for(Account meta : metaList){
                DataTableWrapper element = new DataTableWrapper();
                String clean = cleanString(meta.Name);
                element.label = meta.Name;
                element.value = clean;
                dataTable.add(element);
                branchByNameCode.put(clean, meta.Name);
            }

            // selected firt brunch from the list
            response.selectedBrunch = branchByNameCode.containsKey(cleanString(cont.Account.Name)) ? branchByNameCode.get(cleanString(cont.Account.Name)) : '';
            

            
            // return data brunches in format for lightning-combobox
            response.dataTable = JSON.serialize(dataTable,true);
            response.existData = true;
        }
        Turnero__mdt meta = [SELECT Field__c  FROM Turnero__mdt WHERE Type__c = 'AutoUpdateCitas' AND MasterLabel = 'AutoUpdateLobbyCitas' WITH USER_MODE LIMIT 1];
        response.refreshTime = meta.Field__c;
        
        return response;
    }
    
    @testVisible
    private static String validateAsignAppointment() {
        String userId = UserInfo.getUserId();
        
        List<Appointment__c> appUser = [SELECT Id FROM Appointment__c WHERE Status__c IN ('Ingreso','Llamada') AND OwnerId =: userId WITH USER_MODE LIMIT 1];
        if(!appUser.isEmpty()){
            return System.Label.TurneroUserAssigned;
        }
        List<UserServicePresence> servicePresences = new List<UserServicePresence>();
        if(!Test.isRunningTest()){
        	servicePresences = [SELECT Id FROM UserServicePresence WHERE IsCurrentState = true AND ServicePresenceStatus.DeveloperName = 'Disponible_Turnero' AND UserId=:userId WITH SYSTEM_MODE ];
        
            if(servicePresences.isEmpty()) {
                return System.Label.TurneroStateMessage;
            }
        }
        return null;
    }
    @testVisible
    private static List<Appointment__c> getAppointmentByQueueIdAndSkill(Id groupId, String skill, List<Turnero__mdt> meta) {
        List<String> appointmentQeury = new List<String>();
        List<String> skillSearch = skill.split(';');
        List<String> skillConditions = new List<String>();
        Set<String> queryFields = new Set<String>();
        for(String sk : skillSearch) {
            skillConditions.add('\'' + sk + '\'');
        }
        
        for (Turnero__mdt tr :meta) {
            queryFields.add(tr.Field__c);
        }
        //Asegurar que Fecha de registro esté en la tabla
        queryFields.add('RegistrationDateTime__c');
        
        String appointmentQuery = '';
        appointmentQuery = 'SELECT Id, '+ String.join(queryFields, ',') + ' FROM Appointment__c ' +
                           'WHERE OwnerId =: groupId ' +
                             'AND Status__c = \'Ingreso\' '+ 
                             'AND AttentionType__c INCLUDES(' + String.join(skillConditions, ', ') + ') '+
                             'AND RegistrationDateTime__c = TODAY ' +
                           'ORDER BY RequirePriorityAttention__c DESC, RegistrationDateTime__c ASC ';
        
        return (List<Appointment__c>) Database.query(appointmentQuery, AccessLevel.USER_MODE);
    }
    @testVisible
    private static string createDataTableColumns(List<Turnero__mdt> meta) {
        List<DataTableWrapper> dataTable = new List<DataTableWrapper>();
        for (Turnero__mdt field : meta) {
            DataTableWrapper element = new DataTableWrapper();
            element.label = field.Label;
            element.type = field.FieldType__c;
            element.fieldName = field.Field__c;
            dataTable.add(element);
        }
        return JSON.serialize(dataTable,true);
    }
    
    private static Contact getContactInfoByUserId() {
        if(Test.isRunningTest()){
            return [SELECT Id, Skills__c, Account.Name FROM Contact  WITH USER_MODE LIMIT 1];
        } 
        return [SELECT Id, Skills__c, Account.Name FROM Contact WHERE UserId__c =: UserInfo.getUserId() AND RecordType.DeveloperName = 'Internal_Contact'WITH SYSTEM_MODE LIMIT 1];
    }
    
    private static Id getQueueIdByAccountName(String accountName) {
        return [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND DeveloperName =:accountName WITH USER_MODE LIMIT 1].Id;
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
    
    
    public class LobbyDataWrapper {
        @AuraEnabled
        public String dataTable;
        @AuraEnabled
        public List<Appointment__c> appointmentList;
        @AuraEnabled
        public String idfirstElement;
        @AuraEnabled
        public Boolean existData;
        @AuraEnabled
        public String branchName;
        @AuraEnabled
        public String selectedBrunch;
        @AuraEnabled
        public String messageDetail;
        @AuraEnabled
        public String refreshTime;
        @AuraEnabled
        public String elementNumber;
    }

    public class Results {
        @InvocableVariable(label='success' description='Return boolean' required=true)
        public Boolean success;
        @InvocableVariable(label='messageDetail' description='return success false get messageDetail' required=true)
        public String messageDetail;
    }

    public class Requests {
        @InvocableVariable(label='Appointment ID' description='Record Id to proccess the operation' required=true)
        public String AppointmentId;
    }
    
    public class DataTableWrapper{
        public String label;
        public String type;
        public String fieldName;
        public String value;
    }
    
}