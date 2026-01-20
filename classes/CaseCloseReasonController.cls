public class CaseCloseReasonController {

    @AuraEnabled(cacheable=false)
    public static List<picklistValues> getCloseReason(String companyName, String typeName, String reasonName, String recordId) {
        List<picklistValues> pValues = new List<picklistValues>();
        List<picklistValues> result = new List<picklistValues>();
        String recordTypeName = getRecordTypeName(recordId);
        for(Case_Derivation_Rules__mdt tipif: [SELECT Id,CloseReason__c FROM Case_Derivation_Rules__mdt WHERE Vazquez_Group_Company__c = :companyName AND Type__c =:typeName AND Reason__c =:reasonName AND RecordType__c = :recordTypeName]){
            List<String> optionsChain = new List<String>();
            List<String> options = new List<String>();
            List<String> optionsReason = new List<String>();
            if(tipif.CloseReason__c<>null && tipif.CloseReason__c<>''){
                if(tipif.CloseReason__c.contains('~')){
                    optionsChain = tipif.CloseReason__c.split('~');
                    for(String o : optionsChain){
                        if(o.contains(';')) options = o.split(';');
	                    optionsReason.add(options[0]);
                    }
                } else if (tipif.CloseReason__c.contains(';')) {
                        options = tipif.CloseReason__c.split(';');
	                    optionsReason.add(options[0]);
                }
                if(!optionsReason.isEmpty()){
                    for(String opValue : optionsReason){
                        pValues.add(new picklistValues(opValue,opValue));
                    }
                }
            }
        }

        Set<String> uniqueValues = new Set<String>();
        for (picklistValues r : pValues) {
            if (!uniqueValues.contains(r.value)) {
                uniqueValues.add(r.value);
                result.add(r);
            }
        }
        return result;
    }

    public static String getRecordTypeName(String recordId) {
        return [SELECT Id, RecordType.Name FROM Case WHERE Id = :recordId].RecordType.Name;
    }

    @AuraEnabled
    public static String savePreferredCloseReason(Id recordId, String closeReason, String description, String resolution) {
        try{
            Case c = [SELECT Id, CloseReason__c, CloseReasonDescription__c, Resolution__c, Status FROM Case WHERE Id = :recordId];
            c.CloseReason__c = closeReason;
            c.CloseReasonDescription__c = description;
            if(resolution!=null && resolution!=''){
                c.Resolution__c = resolution;
                c.Status = 'Cerrado';
            }
            update c;
            return 'OK';
        } catch (Exception e){
            String errormsg = '';
            if(e.getTypeName() == 'System.DmlException'){
                if(e.getDmlType(0) == StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION){
                    errormsg = e.getDmlMessage(0);
                } else if(e.getDmlType(0) == StatusCode.INSUFFICIENT_ACCESS_OR_READONLY){
                    errormsg = 'No tiene permiso para realizar esta acción.';
                }
            return errormsg;
            }
            else return 'KO';
        }
    }

    @AuraEnabled
    public static void cleanCloseReason(Id recordId) {
        Case c = [SELECT Id, CloseReason__c, CloseReasonDescription__c FROM Case WHERE Id = :recordId];
        c.CloseReason__c = '';
        c.CloseReasonDescription__c = '';
        update c;
    }

    @AuraEnabled(cacheable=false)
    public static String getCloseReasonDescription(String companyName, String typeName, String reasonName, String valuePicklist) {
        String resultado = '';
        for(Case_Derivation_Rules__mdt tipif: [SELECT Id,CloseReason__c FROM Case_Derivation_Rules__mdt WHERE Vazquez_Group_Company__c = :companyName AND Type__c =:typeName AND Reason__c =:reasonName]){
            if(tipif.CloseReason__c<>null && tipif.CloseReason__c<>''){
                List<String> options = new List<String>();
                List<String> optionsChain = new List<String>();
                if(tipif.CloseReason__c.contains('~')){
                    optionsChain = tipif.CloseReason__c.split('~');       
                        for(String o : optionsChain){
                        if(o.contains(';')) options = o.split(';');
                        if(options[0].toLowerCase().contains(valuePicklist.toLowerCase())){
                            resultado = options[1];
                        } 
                    }
                } else if (tipif.CloseReason__c.contains(';')) {
                        options = tipif.CloseReason__c.split(';');
                        if(options[0].toLowerCase().contains(valuePicklist.toLowerCase())){
                            resultado = options[1];
                        } 
                }
            }
        }

        return resultado;
    }

    public class picklistValues {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;

        public picklistValues(String label,String value){
            this.label=label;
            this.value=value;
        }
    }

}