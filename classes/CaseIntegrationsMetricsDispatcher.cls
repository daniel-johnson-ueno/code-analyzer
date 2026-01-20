global class CaseIntegrationsMetricsDispatcher implements Schedulable{
    
    global void execute(SchedulableContext sc) {
        executeSafe(new VoiceCallMetricsSchedulable(), 'VoiceCallMetricsSchedulable');
        executeSafe(new MessagingSessionMetricsSchedulable(), 'MessagingSessionMetricsSchedulable');
    }

    private void executeSafe(Schedulable job, String name) {
        try {
            job.execute(null);
        } catch (Exception ex) {
            GenerateLogEvent.generateErrorLogEvent(ex, name, 'CaseIntegrationsMetricsDispatcher', 'executeSafe');
            System.debug('Error ejecutando ' + name + ': ' + ex.getMessage());
        }
    }
}