public with sharing class AccountDAO {

    public static Account getAccountById (String accountId){

        if(accountId == 'Simulate Exception'){
            simulateException();
        }

        List<String> lstFields = new List<String>(Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap().keySet());

        String soql = 'SELECT ' + String.join(lstFields,',');
        soql = soql + '  FROM Account ';
        soql = soql + ' WHERE Id =: accountId';

        return Database.query(soql);
    }

    public static List<Informacion_Financiera__c> getCompanyFinancialInfo(String accountId){

        if(accountId == 'Simulate Exception'){
            simulateException();
        }

        List<String> lstFields = new List<String>(Schema.getGlobalDescribe().get('Informacion_Financiera__c').getDescribe().fields.getMap().keySet());

        String soql = 'SELECT ' + String.join(lstFields,',');
        soql = soql + '  FROM Informacion_Financiera__c';
        soql = soql + ' WHERE Cuenta__c =: accountId';

        return Database.query(soql);
    }

    public static List<Vinculo_Persona_Empresa__c> getPersonCompanyLinks(String accountId){

        if(accountId == 'Simulate Exception'){
            simulateException();
        }

        List<String> lstFields = new List<String>(Schema.getGlobalDescribe().get('Vinculo_Persona_Empresa__c').getDescribe().fields.getMap().keySet());

        String soql = 'SELECT ' + String.join(lstFields,',');
        soql = soql + '  FROM Vinculo_Persona_Empresa__c';
        soql = soql + ' WHERE Cuenta__c =: accountId';

        return Database.query(soql);
    }

    public static List<Account> getAccountByTypeAndDocumentNumber (String typeAndDocNumber){

        if(typeAndDocNumber == 'Simulate Exception'){
            simulateException();
        }

        List<String> lstFields = new List<String>(Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap().keySet());

        String soql = 'SELECT ' + String.join(lstFields,',');
        soql = soql + '  FROM Account';
        soql = soql + ' WHERE Type_and_Document_Number__c =: typeAndDocNumber';

        return Database.query(soql);
    }

    public static List<Account> getAccountByTypeAndDocumentNumber (String documentNumber, String type){ //TODO: test

        if(documentNumber == 'Simulate Exception'){
            simulateException();
        }

        List<String> lstFields = new List<String>(Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap().keySet());

        String soql = 'SELECT ' + String.join(lstFields,',');
        soql = soql + '  FROM Account';
        soql = soql + ' WHERE DocumentNumber__c =: documentNumber';
        soql = soql + ' AND DocumentType__c =: type';

        return Database.query(soql);
    }

    public static List<Account> getAccountByTemporaryKey (String email, String phoneNumber){

        List<String> lstFields = new List<String>(Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap().keySet());

        String soql = 'SELECT ' + String.join(lstFields,',');
        soql = soql + '  FROM Account';
        soql = soql + ' WHERE PersonEmail =: email AND Phone =: phoneNumber';

        return Database.query(soql);
    }

    public static List<Account> getAccountByPhone (String phoneNumber){

        List<String> lstFields = new List<String>(Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap().keySet());

        String soql = 'SELECT ' + String.join(lstFields,',');
        soql = soql + '  FROM Account';
        soql = soql + ' WHERE Phone =: phoneNumber';

        return Database.query(soql);
    }


    private static void simulateException (){
        throw new QueryException('Simulated exception');
    }
}