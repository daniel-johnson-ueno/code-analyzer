/**
 * @description       : 
 * @author            : Noe Vasquez
 * @group             : 
 * @last modified on  : 06-19-2025
 * @last modified by  : Noe Vasquez
**/
public without sharing class ProductSelectorController {
    private static Set<String> forbiddenProductsLabels = getForbiddenProducts();


    @AuraEnabled(cacheable=true)
    public static List<Pricebook2> getPricebooks(String accountType, String ownerId) {
        System.debug('acountType: ' + accountType);
        System.debug('ownerId: ' + ownerId);
        
        if(String.isBlank(accountType) || String.isBlank(ownerId)) {
            return [SELECT Id, Name FROM Pricebook2 WHERE IsActive = true ORDER BY Name];
        }
        
        try {
            Map<String, Map<String, String>> pricebookRules = new Map<String, Map<String, String>>{
                'Ueno Bank' => new Map<String, String>{
                    'IndustriesBusiness' => 'ueno empresas',
                    'PersonAccount' => 'ueno personas'
                },
                'Upay' => new Map<String, String>{
                    '*' => 'upay' // Regla comodín para cualquier accountType
                }
            };
            
            User usrOwner = [SELECT CompanyName FROM User WHERE Id = :ownerId AND IsActive = true LIMIT 1];
            if(usrOwner == null) return null;
            
            String ownerCompany = usrOwner.CompanyName;
            String pricebookName;
            
            if(pricebookRules.containsKey(ownerCompany)) {
                Map<String, String> companyRules = pricebookRules.get(ownerCompany);
                
                pricebookName = companyRules.get(accountType);
                if(pricebookName == null) {
                    pricebookName = companyRules.get('*'); // Intenta con regla comodín
                }
            }
            
            // Construir query según si encontramos regla específica
            String query = 'SELECT Id, Name FROM Pricebook2 WHERE IsActive = true';
            if(String.isNotBlank(pricebookName)) {
                query += ' AND Name = :pricebookName';
            }
            query += ' ORDER BY Name';
            
            return Database.query(query);
        } catch(Exception e) {
            System.debug('Error en getPricebooks: ' + e.getMessage());
            return null;
        }
    }

    private static Set<String> getForbiddenProducts() {
        List<forbiddenProducts__mdt> forbiddenProducts = forbiddenProducts__mdt.getAll().values();
        Set<String> forbiddenProductsLabels = new Set<String>();
        for (forbiddenProducts__mdt prod : forbiddenProducts__mdt.getAll().values()) {
            forbiddenProductsLabels.add(prod.Label);
        }

        return forbiddenProductsLabels;
    }

    @AuraEnabled(cacheable=true)
    public static List<PricebookEntry> getProductEntriesByPricebookId(Id pricebook2Id) {
        return [SELECT Id, UnitPrice, Product2Id, Product2.Name, Product2.Family 
                FROM PricebookEntry 
                WHERE IsActive = true
                    AND Pricebook2.Id =: pricebook2Id
                    AND Product2.Name NOT IN :forbiddenProductsLabels 
                ORDER BY Product2.Name
                LIMIT 200];
    }

    public static List<PricebookEntry> getProductEntries(Set<Id> excludedProductIds) {
        return [SELECT Id, UnitPrice, Product2Id, Product2.Name, Product2.Family 
                FROM PricebookEntry 
                WHERE IsActive = true
                    AND Pricebook2.IsStandard = true
                    AND Product2Id NOT IN :excludedProductIds
                    AND Product2.Name NOT IN :forbiddenProductsLabels 
                ORDER BY Product2.Name
                LIMIT 200];
    }

    public static List<PricebookEntry> getProducts(Set<Id> excludedProductIds, String family, String name, Id pricebook2Id) {
        String query = 'SELECT Id, UnitPrice, Product2Id, Product2.Name, Product2.Family ' +
                       'FROM PricebookEntry ' +
                       'WHERE IsActive = true ' +
                       'AND Pricebook2.Id =: pricebook2Id ';
        System.debug(query);
        if(String.isNotBlank(family)) {
            query += 'AND Product2.Family = :family ';
        }
        
        if(!excludedProductIds.isEmpty()) {
            query += 'AND Product2Id NOT IN :excludedProductIds ';
        }

        if(String.isNotBlank(name)) {
            query += 'AND Product2.Name LIKE \'%' + String.escapeSingleQuotes(name) + '%\' ';
        }
        
        query += 'ORDER BY Product2.Name LIMIT 100';
        return Database.query(query);
    }

    @AuraEnabled(cacheable=true) // Mantén cacheable para @wire
    public static List<OpportunityLineItem> getOpportunityLineItems(Id opportunityId) {
        return [SELECT Id, Quantity, UnitPrice, TotalPrice, Product2.Name, Product2Id, Product2.Family, CurrencyIsoCode 
                FROM OpportunityLineItem
                WHERE OpportunityId = :opportunityId];
    }

    @AuraEnabled
    public static List<OpportunityLineItem> refreshOpportunityLineItems(Id opportunityId) {
        return [SELECT Id, Quantity, UnitPrice, TotalPrice, Product2.Name, Product2Id, Product2.Family, CurrencyIsoCode 
                FROM OpportunityLineItem
                WHERE OpportunityId = :opportunityId];
    }

    @AuraEnabled
    public static OpportunityLineItem updateOpportunityLineItem(OpportunityLineItem oppLineItem) {
        try {
            Database.SaveResult result = Database.update(oppLineItem, false); 
            if (!result.isSuccess()) {
                String errorMessage = 'Error al actualizar OpportunityLineItem: ';
                for (Database.Error err : result.getErrors()) {
                    errorMessage += err.getMessage() + ' ';
                }
                throw new AuraHandledException(errorMessage.trim());
            }
    
            return oppLineItem;
        } catch (Exception ex) {
            System.debug('Excepción al actualizar OpportunityLineItem: ' + ex);
            throw new AuraHandledException('Ocurrió un error inesperado al actualizar el registro.');
        }
    }
    

    @AuraEnabled(cacheable=true)
    public static List<PricebookEntry> searchProducts(Id opportunityId, String family, String name, Id pricebook2Id) {
        System.debug('' + opportunityId + ' ' + family + ' ' + name);
        Set<Id> excludedProductIds = new Set<Id>();
        List<OpportunityLineItem> items = getOpportunityLineItems(opportunityId);
        
        for (OpportunityLineItem oli : items) {
            if (oli.Product2Id != null) {
                excludedProductIds.add(oli.Product2Id);
            }
        }
        return getProducts(excludedProductIds, family, name, pricebook2Id);
    }


    @AuraEnabled(cacheable=true)
    public static List<String> getProductFamilyPicklistValues() {
        List<String> picklistValues = new List<String>();
        Schema.DescribeSObjectResult productDescribe = Product2.SObjectType.getDescribe();
        Schema.DescribeFieldResult fieldDescribe = productDescribe.fields.getMap().get('Family').getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldDescribe.getPicklistValues();
        
        for (Schema.PicklistEntry entry : picklistEntries) {
            picklistValues.add(entry.getLabel());
        }
        
        return picklistValues;
    }


    @AuraEnabled
    public static void addProductToOpportunity(Id oppId, Id pbEntryId, Decimal qty, Decimal price) {
        List<OpportunityLineItem> existing = [
            SELECT Id FROM OpportunityLineItem
            WHERE OpportunityId = :oppId
            LIMIT 1
        ];
        
        if (!existing.isEmpty()) {
            throw new AuraHandledException('La oportunidad ya cuenta con un producto asociado.');
        }

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = oppId,
            PricebookEntryId = pbEntryId,
            Quantity = qty,
            UnitPrice = price
        );
        
        insert oli;
    }

    @AuraEnabled
    public static Boolean deleteOpportunityLineItem(Id oppLineItemId) {
        try {
            OpportunityLineItem oliToDelete = [SELECT Id FROM OpportunityLineItem WHERE Id = :oppLineItemId LIMIT 1];
            delete oliToDelete;
            return true;
        } catch (Exception ex) {
            System.debug('Error al eliminar OpportunityLineItem: ' + ex.getMessage());
            return false;
        }
    }

    @AuraEnabled
    public static void updateLineItemPrice(Id lineItemId, Decimal newPrice) {
        try {
            OpportunityLineItem oli = [SELECT Id, UnitPrice FROM OpportunityLineItem WHERE Id = :lineItemId LIMIT 1];
            oli.UnitPrice = newPrice;
            update oli;
        }catch (Exception ex) {
            System.debug('Error al actualizar OpportunityLineItem: ' + ex.getMessage());
        }

    }

}