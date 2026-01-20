public without sharing class DocumentosAdjuntosController {
    //TODO: Una vez que le saquemos todas las fichas a Vurpix cambiar el campo Documentos__c a LongText en lugar de RichText.
    // Una vez hecho esto, no actualizar siempre la cuenta, primero validar si el campo es distinto del response

    @AuraEnabled(continuation=true cacheable=false)
    public static List<DocumentosAdjuntosHelper.DocumentsWrapper> getCustomerDocuments(String accountId){

        List<DocumentosAdjuntosHelper.DocumentsWrapper> documents = new List<DocumentosAdjuntosHelper.DocumentsWrapper>();

        try{
            Account customer = [SELECT Id, PersonCode__c, Documentos__c FROM Account WHERE Id =: accountId];

            if(customer.PersonCode__c != null) {
                String JSONresponse = DocumentosAdjuntosHelper.getDocumentsByPersonCode(customer.PersonCode__c);

                if(JSONresponse != null && JSONresponse != ''){
                    documents = (List<DocumentosAdjuntosHelper.DocumentsWrapper>)JSON.deserialize(JSONresponse, List<DocumentosAdjuntosHelper.DocumentsWrapper>.class);
    
                    customer.Documentos__c = JSONresponse;
                    Database.update(customer);
                }
            } 
        } catch (Exception e){
            System.debug('catch ' + e);
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'DocumentosAdjuntosController', 'getCustomerDocuments');
            throw new AuraHandledException(e.getMessage());
        }

        return documents;
    }
}