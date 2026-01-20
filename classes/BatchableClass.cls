global with sharing class BatchableClass implements Database.Batchable<SObject>, Database.Stateful {

        global static Database.QueryLocator start(Database.BatchableContext BC) {
            return Database.getQueryLocator([
                    SELECT Id, Note__c, Linea__c, Tipo_Tarjeta__c, Contrato_Unico__c  FROM Account WHERE Note__c = TRUE
            ]);
        }

        global void execute(Database.BatchableContext BC, List<Account> accounts) {

            List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
            Map<String, ContentNote> noteByAccount = new Map<String, ContentNote>();

            for (Account acc : accounts) {
                ContentNote note = new ContentNote();
                note.Title = System.Label.APX_NoteTitle;
                note.Content = Blob.valueOf(System.Label.APX_NoteBody);
                acc.Note__c = false;
                noteByAccount.put(acc.Id, note);

            }
            
            if (noteByAccount.size() > 0) {
                Database.upsert(accounts);
                Database.insert(noteByAccount.values());

                for (String accountId : noteByAccount.keySet()) {
                    ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
                    contentDocumentLink.ContentDocumentId = noteByAccount.get(accountId).Id;
                    contentDocumentLink.LinkedEntityId = accountId;
                    contentDocumentLink.ShareType = 'V';

                    contentDocumentLinks.add(contentDocumentLink);
                }

                if (!contentDocumentLinks.isEmpty()) {
                    Database.insert (contentDocumentLinks);
                }
            }
        }

        global void finish(Database.BatchableContext BC) {
            System.debug('Batch process complete.');
        }
}