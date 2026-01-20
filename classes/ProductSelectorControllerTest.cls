/**
 * @description       : 
 * @author            : Noe Vasquez
 * @group             : 
 * @last modified on  : 06-20-2025
 * @last modified by  : Noe Vasquez
**/
@isTest
public class ProductSelectorControllerTest {

    @testSetup
    static void setupTestData() {

        Account acc = new Account(Name = 'Test Account');
        Account testPersonAccount = (Account)TestFactoryFramework.createSObject(acc, true);

    
        Id standardPBId = Test.getStandardPricebookId();
    
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Asignación',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id,
            Pricebook2Id = standardPBId
        );
        Opportunity opp = (Opportunity)TestFactoryFramework.createSObject(testOpp, true);

        System.debug('Opportunity Id: ' + opp.Id);

        // Insert products
        Product2 prod1 = new Product2(Name = 'Product 1', IsActive = true);
        Product2 prod2 = new Product2(Name = 'Product 2', IsActive = true);
        prod1 = (Product2)TestFactoryFramework.createSObject(prod1, true);
        prod2 = (Product2)TestFactoryFramework.createSObject(prod2, true);

        // Insert price entries
        PricebookEntry standardPBE = new PricebookEntry(Pricebook2Id = standardPBId, Product2Id = prod1.Id, UnitPrice = 2000, IsActive = true);
        standardPBE = (PricebookEntry)TestFactoryFramework.createSObject(standardPBE, true);
    
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = standardPBId, Product2Id = prod2.Id, UnitPrice = 1000, IsActive = true);
        standardPBE = (PricebookEntry)TestFactoryFramework.createSObject(pbe, true);


    }
    

    @isTest
    static void test_addProductToOpportunity() {
        
        Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
        Id standardPBId = Test.getStandardPricebookId();

        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Product 1' LIMIT 1];
    
        // Creamos un PricebookEntry para el producto y el Pricebook estándar
        PricebookEntry pbe = [SELECT Id, Pricebook2Id, UnitPrice, Product2Id FROM PricebookEntry WHERE Pricebook2Id = :standardPBId LIMIT 1];
    
        Test.startTest();
        ProductSelectorController.addProductToOpportunity(
            opp.Id, pbe.Id, 2, 100
        );
        Test.stopTest();
    
        OpportunityLineItem oli = [
            SELECT Id, Product2Id, Quantity, UnitPrice
            FROM OpportunityLineItem
            WHERE OpportunityId = :opp.Id
            LIMIT 1
        ];
        Assert.areNotEqual(null, oli);
        Assert.areEqual(prod.Id, oli.Product2Id);
        Assert.areEqual(2, oli.Quantity);
        Assert.areEqual(100, oli.UnitPrice);
        
    }
    
    @isTest
    static void test_deleteOpportunityLineItem() {
        // Arrange
        Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1];

        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Product 1' LIMIT 1];
        Id standardPBId = Test.getStandardPricebookId();
        PricebookEntry pbe = [SELECT Id, Pricebook2Id, UnitPrice, Product2Id FROM PricebookEntry WHERE Pricebook2Id = :standardPBId LIMIT 1];

        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opp.Id, Product2Id = prod.Id, Quantity = 1, UnitPrice = 100, PricebookEntryId = pbe.Id);       
        oli = (OpportunityLineItem)TestFactoryFramework.createSObject(oli, true);
        
        Test.startTest();
        ProductSelectorController.deleteOpportunityLineItem(oli.Id);
        Test.stopTest();

        List<OpportunityLineItem> check = [SELECT Id FROM OpportunityLineItem WHERE Id = :oli.Id LIMIT 1];

        Assert.areEqual(new List<OpportunityLineItem>(), check, 'Debe haberse eliminado el OpportunityLineItem');// Esto lanzará error si existe
    }

    
    @isTest
    static void test_getProductEntriesByPricebookId() {
        Id standardPBId = Test.getStandardPricebookId();
        List<PricebookEntry> entries;

        Test.startTest();
        entries = ProductSelectorController.getProductEntriesByPricebookId(standardPBId);
        Test.stopTest();

    }

    @isTest
    static void test_getProductEntries_withExclusions() {
        List<Product2> products = [SELECT Id FROM Product2];
        Set<Id> excludedIds = new Set<Id>{ products[0].Id };

        Test.startTest();
        List<PricebookEntry> result = ProductSelectorController.getProductEntries(excludedIds);
        
        Test.stopTest();
    }

    @isTest
    static void test_getProduct() {
        List<Product2> products = [SELECT Id FROM Product2];
        Set<Id> excludedIds = new Set<Id>{ products[0].Id };
        Id standardPBId = Test.getStandardPricebookId();
        Test.startTest();
        List<PricebookEntry> result = ProductSelectorController.getProducts(excludedIds, 'Electronics', '', standardPBId);
        result = ProductSelectorController.getProducts(excludedIds, 'Electronics', 'Test Name', standardPBId);
        Test.stopTest();

    }


    @isTest
    static void test_refreshAndUpdateLineItems() {
        Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
        List<Product2> products = [SELECT Id FROM Product2];

        Test.startTest();
        List<OpportunityLineItem> checkOut = ProductSelectorController.refreshOpportunityLineItems(opp.Id);
        if(checkOut.size() == 0) {
            Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Product 1' LIMIT 1];
            Id standardPBId = Test.getStandardPricebookId();
            
            PricebookEntry pbe = [SELECT Id, Pricebook2Id, UnitPrice, Product2Id FROM PricebookEntry 
                                    WHERE Pricebook2Id = :standardPBId LIMIT 1];
            
            OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opp.Id, Product2Id = prod.Id, Quantity = 1, UnitPrice = 100, PricebookEntryId = pbe.Id);
            oli = (OpportunityLineItem)TestFactoryFramework.createSObject(oli, true);
            OpportunityLineItem opi = ProductSelectorController.updateOpportunityLineItem(oli);

        }
        
        Test.stopTest();
    }

    @isTest
    static void test_searchProducts() {
       
        Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
        Id standardPBId = Test.getStandardPricebookId();

        Test.startTest();
        List<PricebookEntry> results = ProductSelectorController.searchProducts(opp.Id, 'Comex', '', standardPBId);
        ProductSelectorController.getProductFamilyPicklistValues();
        Test.stopTest();

    }

    @isTest
    static void test_updateOpportunityLineItem_withValidationError() {
        Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
        
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Product 1' LIMIT 1];
        Id standardPBId = Test.getStandardPricebookId();
            
        PricebookEntry pbe = [SELECT Id, Pricebook2Id, UnitPrice, Product2Id FROM PricebookEntry 
                                    WHERE Pricebook2Id = :standardPBId LIMIT 1];
            
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opp.Id, Product2Id = prod.Id, Quantity = 1, UnitPrice = 100, PricebookEntryId = pbe.Id);
        oli = (OpportunityLineItem)TestFactoryFramework.createSObject(oli, true);
        
        OpportunityLineItem opi = ProductSelectorController.updateOpportunityLineItem(oli);


        Set<String> errorsList = new Set<String>{'Script-thrown exception', 'FIELD_CUSTOM_VALIDATION_EXCEPTION'};
        // Ahora quitamos un campo obligatorio para causar error sin excepción
        oli.Quantity = null;
    
        Test.startTest();
        try {
            ProductSelectorController.updateOpportunityLineItem(oli);
            Assert.fail('Se esperaba una excepción pero no se lanzó.');

        } catch (AuraHandledException ex) {
            System.debug('Excepción capturada correctamente: ' + ex.getMessage());
            Assert.isTrue(errorsList.contains(ex.getMessage()), 'Mensaje de error esperado no fue encontrado.');

        }
        Test.stopTest();
    }
    
    @isTest
    static void test_getPricebooks() {
        Opportunity opp = [SELECT Id, Name, AccountId, OwnerId FROM Opportunity LIMIT 1];
        Test.startTest();
        try {
            ProductSelectorController.getPricebooks(opp.AccountId, opp.OwnerId);
        } catch (AuraHandledException ex) {
            System.debug('Excepción capturada correctamente: ' + ex.getMessage());
        }
        Test.stopTest();
    }
    


    @isTest
    static void test_updateLineItem() {

        Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1];

        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Product 1' LIMIT 1];
        Id standardPBId = Test.getStandardPricebookId();
        PricebookEntry pbe = [SELECT Id, Pricebook2Id, UnitPrice, Product2Id FROM PricebookEntry WHERE Pricebook2Id = :standardPBId LIMIT 1];

        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opp.Id, Product2Id = prod.Id, Quantity = 1, UnitPrice = 100, PricebookEntryId = pbe.Id);       
        oli = (OpportunityLineItem)TestFactoryFramework.createSObject(oli, true);

        Decimal nuevoPrecio = 7899999;

        Test.startTest();
        ProductSelectorController.updateLineItemPrice(oli.Id, nuevoPrecio);
        Test.stopTest();

        // Validar que el precio se actualizó
        OpportunityLineItem actualizado = [SELECT UnitPrice FROM OpportunityLineItem WHERE Id = :oli.Id];
        Assert.areEqual(nuevoPrecio, actualizado.UnitPrice, 'El precio del OpportunityLineItem debe haberse actualizado correctamente');
    }

}