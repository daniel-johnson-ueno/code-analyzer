public class MyQueueable implements Queueable {
    List<AccountMappingService.AccountMappingRequest> batch;
    Integer startIndex;

    // Constructor
    public MyQueueable(List<AccountMappingService.AccountMappingRequest> batch, Integer startIndex) {
        this.batch = batch;
        this.startIndex = startIndex;
    }

    public void execute(QueueableContext context) {
        System.debug('Ejecutando método execute con índice: ' + startIndex);
        
        Integer batchSize = 1; // Procesar de 1 en 1
        Integer endIndex = Math.min(startIndex + batchSize, batch.size());

        // Obtener manualmente la sublista
        List<AccountMappingService.AccountMappingRequest> subBatch = new List<AccountMappingService.AccountMappingRequest>();
        for (Integer i = startIndex; i < endIndex; i++) {
            subBatch.add(batch[i]);
        }

        // Procesar el sublote
        String batchJson = JSON.serialize(subBatch);
        processInFuture(batchJson);

        // Encolar otro job si hay más registros pendientes
        if (endIndex < batch.size()) {
            System.debug('Encolando siguiente job con índice: ' + endIndex);
            System.enqueueJob(new MyQueueable(batch, endIndex));
        }
    }

    @future(callout=true)
    public static void processInFuture(String batchJson) {
        try {
            List<AccountMappingService.AccountMappingRequest> batch = 
                (List<AccountMappingService.AccountMappingRequest>) JSON.deserialize(batchJson, 
                List<AccountMappingService.AccountMappingRequest>.class);
            
            for (AccountMappingService.AccountMappingRequest request : batch) {
                List<AccountMappingService.AccountMappingResult> results = AccountMappingService.mapAccountData(
                    new List<AccountMappingService.AccountMappingRequest>{request}
                );
                
                for (AccountMappingService.AccountMappingResult result : results) {
                    if (result.success) {
                        System.debug('Documento: ' + result.accountId + ' - Mapeo exitoso');
                    } else {
                        System.debug('Documento: ' + result.code + ' - Error: ' + result.message);
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error en el proceso asincrónico: ' + e.getMessage());
        }
    }
}