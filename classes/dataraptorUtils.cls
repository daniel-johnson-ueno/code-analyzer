public class dataraptorUtils implements Callable {
    public Object call(String action, Map<String,Object>args){
        
        Map<String,Object>input=(Map<String,Object>)args.get('input');
        Map<String,Object>output=(Map<String,Object>)args.get('output');
        Map<String,Object>options=(Map<String,Object>)args.get('options');
        
        return invokeMethod(action,input,output,options);
    }
    
    public boolean invokeMethod(String methodName, Map<String,Object> input,Map<String,Object> output,Map<String,Object> options)
    {
        system.debug(methodName);
        System.debug(input.get('arguments'));
        try{
            if(methodName.equalsIgnoreCase('capitalize')){
                List<Object> arg = (List<Object>)input.get('arguments');
                
             	output.put('result',capitalizeText((String) arg.get(0)));
            }else if (methodName.equalsIgnoreCase('getPicklistLabel')){
                system.debug('gettingpicklistValues');
                List<Object> arg = (List<Object>)input.get('arguments');
                
             	output.put('result',getPicklistLabel((String) arg.get(0),(String) arg.get(1),String.valueOf(arg.get(2))));
            }
            
        }
        catch(Exception e){
            return false;
        }
        return true;
    }
    
    //public methods
    
    public static String capitalizeText(String text){
        List<String> words = new List<String>();
        for (String word: text.split(' ')){
            words.add(capitalize(word));
        }
        return String.join(words, ' ');
    }
    
    public static String getPicklistLabel(String objectApiName, String fieldApiName, String picklistValue) {
        system.debug('gettingPicklistValues');
        system.debug(objectApiName);
        system.debug(fieldApiName);
        system.debug(picklistValue);
        String label = null;
        
        // Obtener el mapa de valores y etiquetas del campo picklist
        Map<String, String> picklistValues = getPicklistValues(objectApiName, fieldApiName);
        
        // Buscar el valor y obtener la etiqueta correspondiente
        system.debug(picklistValue);
        if (picklistValues.containsKey(picklistValue)) {
            system.debug('picklistValue');
            label = picklistValues.get(picklistValue);
        }
        system.debug(label);
        return label;
    }
    
    
    //private methods
    private static String capitalize(String word){
        system.debug('capitalizing');
        word = word.toLowerCase();
        return word.capitalize();
    }
    
    private static Map<String, String> getPicklistValues(String objectApiName, String fieldApiName) {
        Map<String, String> picklistValues = new Map<String, String>();
        
        // Describe el objeto para obtener información sobre el campo picklist
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap();
        
        Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldApiName).getDescribe();
        system.debug(fieldDescribe.getType());
        // Verifica si el campo es de tipo picklist
        if (fieldDescribe.getType() == Schema.DisplayType.Picklist) {
            List<Schema.PicklistEntry> picklistEntries = fieldDescribe.getPicklistValues();
            for (Schema.PicklistEntry entry : picklistEntries) {
                system.debug('adding pair: ('+entry.getValue()+','+entry.getLabel()+')');
                picklistValues.put(entry.getValue(), entry.getLabel());
            }
        }
        
        return picklistValues;
    }
}