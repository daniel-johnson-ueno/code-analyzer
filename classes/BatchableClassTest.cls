@isTest
private class BatchableClassTest {

    @isTest
    static void testBatchableClass() {
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            testAccounts.add(new Account(
                    Name = 'Test Account ' + i,
                    Note__c = true,
                    Linea__c = '500000',
                    Tipo_Tarjeta__c = 'Gold',
                    Contrato_Unico__c = 'Contrato_' + i
            ));
        }

        insert testAccounts;

        Test.startTest();
        BatchableClass batch = new BatchableClass();
        Database.executeBatch(batch, 5);
        Test.stopTest();

//        List<Account> updatedAccounts = [SELECT Id, Note__c FROM Account WHERE Id IN :testAccounts];
//        for (Account acc : updatedAccounts) {
//            System.assertEquals(false, acc.Note__c, 'El campo Note__c debería ser false después de la ejecución del batch.');
//        }
//
//        List<ContentNote> contentNotes = [SELECT Id, Title, Content FROM ContentNote];
//        System.assertEquals(5, contentNotes.size(), 'Se deben crear 5 ContentNotes para las cuentas de prueba.');
//
//        for (ContentNote note : contentNotes) {
//            System.assert(note.Content.toString().contains('Cliente incluido en campaña de tarjeta pre aprobada'), 'El contenido de la nota no es el esperado.');
//        }
//
//        List<ContentDocumentLink> contentDocumentLinks = [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :testAccounts];
//        System.assertEquals(5, contentDocumentLinks.size(), 'Se deben crear 5 ContentDocumentLinks para las cuentas de prueba.');

    }
}