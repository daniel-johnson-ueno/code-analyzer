/**
 * @description       : 
 * @author            : Noe Vasquez
 * @group             : 
 * @last modified on  : 06-02-2025
 * @last modified by  : Noe Vasquez
**/
public without sharing class OpportunityTriggerHelper {
    private static final String DEFAULT_PRODUCT = 'Caja de Ahorro';    
    private static final String DEFAULT_PRODUCT_UPAY = 'Pos upay';    
    private static final Id RECORDTYPE_GENERAL_ID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('General').getRecordTypeId(); 
    private static final Id RECORDTYPE_UPAY_ID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('upay').getRecordTypeId(); 

    public static void preventDuplicateOpportunities(List<Opportunity> newOpps) {
        Id onboardingRecordTypeId;
        try {
            onboardingRecordTypeId = [
                SELECT Id FROM RecordType WHERE Name = 'Onboarding' AND SObjectType = 'Opportunity' LIMIT 1
            ].Id;
        } catch (Exception e) {
            System.debug('No se encontró el Record Type "Onboarding"');
            return;
        }
        Set<String> uniqueKeys = new Set<String>();
        Map<String, Opportunity> existingOppsMap = new Map<String, Opportunity>();

        for (Opportunity opp : newOpps) {
            if (opp.AccountId != null && opp.Name != null && opp.RecordTypeId == onboardingRecordTypeId) {
                String uniqueKey = opp.AccountId + '-' + opp.Name;
                uniqueKeys.add(uniqueKey);
            }
        }

        if (!uniqueKeys.isEmpty()) {
            List<Opportunity> existingOpps = [
                SELECT Id, AccountId, Name 
                FROM Opportunity 
                WHERE RecordTypeId = :onboardingRecordTypeId
                AND (StageName = 'Asignación'
                OR StageName = 'Gestiones internas'
                OR StageName = 'Exitoso')
                AND AccountId != null 
                AND Name != null
            ];

            for (Opportunity existingOpp : existingOpps) {
                String key = existingOpp.AccountId + '-' + existingOpp.Name;
                existingOppsMap.put(key, existingOpp);
            }
        }

        if (!existingOppsMap.isEmpty()) {
            for (Opportunity opp : newOpps) {
                String uniqueKey = opp.AccountId + '-' + opp.Name;
                if (existingOppsMap.containsKey(uniqueKey)) {
                    opp.addError('Ya existe una oportunidad de tipo "Onboarding" con este nombre para la misma cuenta.');
                }
            }
        }
    }

    public static void createProductDefaultOnboarding(List<Opportunity> onboardingOpps) {
        if (onboardingOpps == null || onboardingOpps.isEmpty()) return;

        List<OpportunityLineItem> oliToInsert = new List<OpportunityLineItem>();

        Map<Id, Opportunity> oppsWithProducts = new Map<Id, Opportunity>([
            SELECT Id, (SELECT Id FROM OpportunityLineItems) 
            FROM Opportunity 
            WHERE Id IN :onboardingOpps
        ]);


        for(Opportunity opp : onboardingOpps) {
            System.debug('My opp: ' + opp);
            System.debug('opp Id: ' + opp.Id);
            
            if(oppsWithProducts.get(opp.Id).OpportunityLineItems.isEmpty()) {
                PricebookEntry entry = getDefaultProductEntry(opp.Pricebook2Id, DEFAULT_PRODUCT);

                if(entry == null) return;

                oliToInsert.add(new OpportunityLineItem(
                    OpportunityId = opp.Id,
                    PricebookEntryId = entry.Id,
                    Product2Id = entry.Product2Id,
                    Quantity = 1,
                    UnitPrice = entry.UnitPrice
                ));
            }
        }

        if(!oliToInsert.isEmpty()) {
            try {
                insert oliToInsert;

                for(OpportunityLineItem item: oliToInsert) {
                    System.debug('Oli creado - ID: ' + item.Id + 
                                ' para Opportunity: ' + item.OpportunityId);
                }
            } catch(DmlException e) {
                System.debug('Error al agregar productos default: ' + e.getMessage());
                GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'OpportunityTriggerHelper', 'createProductDefaultOnboarding');

            }
        }
    
    }

    public static void createProductDefaultUpay(List<Opportunity> upayOpps) {
        List<OpportunityLineItem> oliToInsert = new List<OpportunityLineItem>();
        Map<Id, Opportunity> oppsWithProducts = new Map<Id, Opportunity>([
            SELECT Id, (SELECT Id FROM OpportunityLineItems) 
            FROM Opportunity 
            WHERE Id IN :upayOpps
        ]);

        for(Opportunity opp : upayOpps) {
            if(oppsWithProducts.get(opp.Id).OpportunityLineItems.isEmpty()) {

                PricebookEntry entry = getDefaultProductEntry(opp.Pricebook2Id, DEFAULT_PRODUCT_UPAY);
                if(entry == null) {
                    return;
                }

                oliToInsert.add(new OpportunityLineItem(
                    OpportunityId = opp.Id,
                    PricebookEntryId = entry.Id,
                    Product2Id = entry.Product2Id,
                    Quantity = 1,
                    UnitPrice = entry.UnitPrice
                    ));
            }
        }
        

        if(!oliToInsert.isEmpty()) {
            try {
                insert oliToInsert;

                for(OpportunityLineItem item: oliToInsert) {
                    System.debug('Oli creado - ID: ' + item.Id + 
                                ' para Opportunity: ' + item.OpportunityId);
                }
            } catch(DmlException e) {
                System.debug('Error al agregar productos default: ' + e.getMessage());
                GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'OpportunityTriggerHelper', 'createProductDefaultUpay');

            }
        }
    
    }
    
    public static List<Opportunity> excludeByRecordType(List<Opportunity> opps, Id recordTypeId) {
        List<Opportunity> filteredOpps = new List<Opportunity>();
        
        if(opps.isEmpty() || recordTypeId == null) return filteredOpps;
        
        
        for(Opportunity opp : opps) {
            if(opp.RecordTypeId == recordTypeId) {
                filteredOpps.add(opp);
            }
        }

        return filteredOpps;
    }

    public static void setPricebookId(List<Opportunity> opps) {
        if (opps == null || opps.isEmpty()) return;
    
        // Filtrar oportunidades que no tienen PricebookId asignado
        List<Opportunity> oppsToProcess = new List<Opportunity>();
        Set<Id> ownerIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();

        for (Opportunity opp : opps) {
            //if (opp.Pricebook2Id == null) {
                oppsToProcess.add(opp);
                // Recolectar IDs de usuarios y cuentas
                if (opp.OwnerId != null) ownerIds.add(opp.OwnerId);
                if (opp.AccountId != null) accountIds.add(opp.AccountId);
            //}
        }

        if (oppsToProcess.isEmpty()) return;
    
        Map<Id, User> ownerMap = ownerIds.isEmpty() ? new Map<Id, User>() :
            new Map<Id, User>([SELECT Id, CompanyName FROM User WHERE Id IN :ownerIds]);
    
        Map<Id, Account> accountMap = accountIds.isEmpty() ? new Map<Id, Account>() :
            new Map<Id, Account>([SELECT Id, RecordType.DeveloperName FROM Account WHERE Id IN :accountIds]);
    
        // Determinar nombres de pricebooks necesarios
        Set<String> requiredPricebookNames = new Set<String>();
        List<String> pricebookNamesByOpportunityIndex = new List<String>();
    
        for (Opportunity opp : oppsToProcess) {
            String ownerCompany = ownerMap.get(opp.OwnerId)?.CompanyName;
            String accountRT = accountMap.get(opp.AccountId)?.RecordType?.DeveloperName;
            String pbName = null;
    
            if(opp.RecordTypeId == RECORDTYPE_UPAY_ID) {
                pbName = 'upay';

            }
            else if (ownerCompany == 'Ueno Bank') {
                if (accountRT == 'IndustriesBusiness') {
                    pbName = (opp.CurrencyIsoCode == 'USD') ? 'ueno empresas USD' : 'ueno empresas';
                } else if (accountRT == 'PersonAccount') {
                    pbName = (opp.CurrencyIsoCode == 'USD') ? 'ueno personas USD' : 'ueno personas';
                }
            }
    
            pricebookNamesByOpportunityIndex.add(pbName);
            if (pbName != null) {
                requiredPricebookNames.add(pbName.toLowerCase());
            }
        }
    
        // Consultar los Pricebooks activos requeridos
        Map<String, Id> pricebookMap = new Map<String, Id>();
        if (!requiredPricebookNames.isEmpty()) {
            System.debug('requiredPricebookNames: ' + requiredPricebookNames);
            for (Pricebook2 pb : [
                SELECT Id, Name
                FROM Pricebook2
                WHERE Name IN :requiredPricebookNames AND IsActive = true
            ]) {
                pricebookMap.put(pb.Name.toLowerCase(), pb.Id);
                System.debug('pricebookMap: ' + pricebookMap);
            }
        }
    
        // Asignar Pricebook2Id a cada oportunidad
        for (Integer i = 0; i < oppsToProcess.size(); i++) {
            String pbName = pricebookNamesByOpportunityIndex[i];
            Id pbId = pbName != null ? pricebookMap.get(pbName.toLowerCase()) : null;
            if (pbId != null) {
                oppsToProcess[i].Pricebook2Id = pbId;
            }
        }
    }

    private static PricebookEntry getDefaultProductEntry(Id pricebook2Id, String productName) {
        List<PricebookEntry> entries = [
            SELECT Id, Product2Id, UnitPrice, Pricebook2Id 
            FROM PricebookEntry 
            WHERE Product2.Name =: productName 
            AND Pricebook2Id = :pricebook2Id
            AND IsActive = true
            LIMIT 1
        ];
        
        if (entries.isEmpty()) {
            return null; //throw new AuraHandledException('No se encontró el producto "' + productName + '" en el catálogo de precios especificado');
        }
        
        return entries[0];
    }

    /*
    private static Boolean isUserUpay() {
        // Obtener el nombre del perfil actual en minúsculas
        String profileName = [
            SELECT Name 
            FROM Profile 
            WHERE Id = :UserInfo.getProfileId()
            LIMIT 1
        ].Name.toLowerCase();

        Set<String> perfilesPermitidos = new Set<String>();
        for (Allow_Profiles_Upay__mdt mdt : [
            SELECT Label FROM Allow_Profiles_Upay__mdt 
            WHERE IsActive__c = true
        ]) {
            if (mdt.Label != null) {
                perfilesPermitidos.add(mdt.Label.toLowerCase());
            }
        }

        // Comparar si el perfil del usuario está permitido
        return perfilesPermitidos.contains(profileName);
    }

    private static Map<String, String> buildUserPayMap(List<Opportunity> opps) {
        Map<String, String> userPayMap = new Map<String, String>();
        // Recolectar IDs de usuarios y cuentas
        Set<Id> ownerIds = new Set<Id>();
    
        for (Opportunity opp : opps) {
            if (opp.OwnerId != null) ownerIds.add(opp.OwnerId);
        }
    
        // Mapas con datos necesarios
        Map<Id, User> ownerMap = ownerIds.isEmpty() ? new Map<Id, User>() :
            new Map<Id, User>([SELECT Id, CompanyName FROM User WHERE Id IN :ownerIds]);
    
        for (Opportunity opp : opps) {
            String ownerCompany = ownerMap.get(opp.OwnerId)?.CompanyName;
            if(ownerCompany == 'Upay') {
                userPayMap.put(opp.Id, ownerCompany);
            }
        }

        return userPayMap;
    }*/

    public static Map<String, Id> getCurrencyPricebookMap() {
        // Obtener todos los pricebooks activos y relacionados a monedas
        Map<String, Id> mapResult = new Map<String, Id>();
        for (Pricebook2 pb : [
            SELECT Id, Name, IsActive, CurrencyIsoCode 
            FROM Pricebook2 
            WHERE IsActive = true
        ]) {
            mapResult.put(pb.CurrencyIsoCode, pb.Id);
        }
        return mapResult;
    }

    public static void checkAccountsOnBankittiBatch(List<Account> accounts) {
        List<AccountMappingService.AccountMappingRequest> requests = new List<AccountMappingService.AccountMappingRequest>();
    	 List<String> resultAccountIds = new List<String>();
        for (Account acc : accounts) {
            if (String.isNotBlank(acc.DocumentNumber__c)) {
                AccountMappingService.AccountMappingRequest request = new AccountMappingService.AccountMappingRequest();
                request.documentId = acc.DocumentNumber__c;
                request.documentType = '1';
                requests.add(request);
            }
        }
    
        if (requests.isEmpty()) return;
    
        List<AccountMappingService.AccountMappingResult> results = AccountMappingService.mapAccountData(requests);
        for (AccountMappingService.AccountMappingResult result : results) {  if (result.success) { resultAccountIds.add(result.accountId); }  }
    }


}