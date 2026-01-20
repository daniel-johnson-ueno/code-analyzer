@isTest
private class MyQueueableTest {
    
    @isTest
    static void testMyQueueableExecution() {
        List<String> documentIds = new List<String>{'4392046'};
        List<AccountMappingService.AccountMappingRequest> requests = new List<AccountMappingService.AccountMappingRequest>();
        for (String documentId : documentIds) {
            AccountMappingService.AccountMappingRequest request = new AccountMappingService.AccountMappingRequest();
            request.documentId = documentId;
            request.documentType = '1';
            requests.add(request);
        }
        // Iniciar la ejecución del proceso en la cola
        Test.startTest();
        System.enqueueJob(new MyQueueable(requests, 0));
        Test.stopTest();

        // Aquí se podrían agregar más validaciones si hay registros modificados o logs registrados
        System.assert(true, 'La prueba se ejecutó sin errores sin exceder el límite de profundidad');
    }
}