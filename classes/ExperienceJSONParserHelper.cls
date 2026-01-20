public with sharing class ExperienceJSONParserHelper {
    @InvocableMethod(label='Parse JSON and Validate IDs' description='Extracts salesforceCaseId and salesforceAccountId, validates them, and returns them to the Flow')
    public static List<ParsedIds> parseAndValidateIds(List<String> jsonInputs) {
        List<ParsedIds> results = new List<ParsedIds>();
        
        for (String jsonInput : jsonInputs) {
            ParsedIds parsed = new ParsedIds();
            try {
                Map<String, Object> jsonData = (Map<String, Object>) JSON.deserializeUntyped(jsonInput);
                
                String caseId = (String) jsonData.get('salesforceCaseId');
                String accountId = (String) jsonData.get('salesforceAccountId');
                
                if (isValidSalesforceId(caseId, 'Case')) {
                    parsed.salesforceCaseId = caseId;
                }
                
                if (isValidSalesforceId(accountId, 'Account')) {
                    parsed.salesforceAccountId = accountId;
                }
                
            } catch (Exception e) {
                System.debug('Error parsing JSON: ' + e.getMessage());
            }
            results.add(parsed);
        }
        
        return results;
    }

    private static Boolean isValidSalesforceId(String recordId, String sObjectType) {
        if (String.isBlank(recordId) || recordId.length() != 18) {
            return false;
        }
        try {
            List<sObject> records = Database.query('SELECT Id FROM ' + sObjectType + ' WHERE Id = :recordId LIMIT 1');
            return !records.isEmpty();
        } catch (Exception e) {
            return false;
        }
    }
    
    public class ParsedIds {
        @InvocableVariable(label='Salesforce Case ID' description='Validated Case ID' required=false)
        public String salesforceCaseId;
        
        @InvocableVariable(label='Salesforce Account ID' description='Validated Account ID' required=false)
        public String salesforceAccountId;
    }
}