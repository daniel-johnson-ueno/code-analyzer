global with sharing class NewRelicMetricsSender {

    public class InvalidMetricTypeException extends Exception {}
    public class NewRelicMetricsException extends Exception {}

    global class MetricsWrapper {
        @InvocableVariable(required=true label='Metrics' description='Metrics to be sent')
        global List<Metric> metrics;

        global MetricsWrapper() {
            this.metrics = new List<Metric>();
        }
    }

    global class Metric {
        global String name;
        global String type;
        global Decimal value;
        global Long timestamp;
        global Long intervalMs;
        global Map<String, Object> attributes;

        global Metric() {
            this.attributes = new Map<String, Object>();
        }
    }

    global class MetricsWrapperBuilder {
        private List<Metric> metricsList = new List<Metric>();

        global MetricsWrapperBuilder addMetric(String name, String type, Decimal value, Long timestamp, Long intervalMs, Map<String, Object> attributes) {
            Metric m = new Metric();
            m.name = name;
            m.type = type;
            m.value = value;
            m.timestamp = timestamp;
            m.intervalMs = intervalMs;
            m.attributes = attributes;
            metricsList.add(m);
            return this;
        }

        global List<MetricsWrapper> build() {
            if (metricsList.isEmpty()) {
                return new List<MetricsWrapper>();
            } 
            MetricsWrapper wrapper = new MetricsWrapper();
            wrapper.metrics.addAll(metricsList);
            return new List<MetricsWrapper>{ wrapper };
        }
    }

    @InvocableMethod(label='Send metrics to New Relic')
    global static void sendMetricsToNewRelic(List<MetricsWrapper> requestPayload) {
        New_Relic_Settings__c settings = New_Relic_Settings__c.getOrgDefaults();
        if(settings.FeatureFlag__c){
            validateMetricTypes(requestPayload);
            String request = serializeRequest(requestPayload);
            validateRequestSize(request);
            performHttpCallout(request);
        }
    }

    @Future(callout=true)
    private static void performHttpCallout(String body) {

        HttpHelper.HttpClientWithRetry httpClient = new HttpHelper.HttpClientWithRetry();
        try {
            HttpRequest req = buildRequest(body);
            HTTPResponse res = httpClient.doCallout(req);
            
            if (res.getStatusCode() != 202) {
                GenerateLogEvent.generateIntegrationLogEvent(req, res);
            }
        } catch (Exception e) {
            System.debug('Error sending metrics to New Relic: ' + e.getMessage());
            throw new NewRelicMetricsException('Error al enviar la metrica. Ex: ' + e.getMessage());
        }
    }

    private static HttpRequest buildRequest(String body) {
        New_Relic_Settings__c settings = New_Relic_Settings__c.getOrgDefaults();
        HttpRequest request = new HttpRequest();
        
        request.setEndpoint(settings.DomainName__c);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Api-Key', settings.ApiKey__c);
        request.setBody(body);

        return request;
    }

    private static String serializeRequest(List<MetricsWrapper> request){
        String body = JSON.serialize(request);
        return body.replaceAll('"intervalMs":', '"interval.ms":');
    }

    private static void validateRequestSize(String request) {
        Integer sizeInBytes = Blob.valueOf(request).size();
        Integer maxSafeSize = 750000;
    
        if (sizeInBytes > maxSafeSize) {
            throw new NewRelicMetricsException(
                'El cuerpo del request está alcanzando el límite permitido por New Relic (' +
                sizeInBytes + ' bytes). Supera el umbral de seguridad de ' + maxSafeSize + ' bytes.'
            );
        }
    }

    private static void validateMetricTypes(List<MetricsWrapper> requestPayload) {
        List<String> validTypes = new List<String>{'COUNT', 'GAUGE'};

        for (MetricsWrapper wrapper : requestPayload) {
            for (Metric metric : wrapper.metrics) {
                if (!validTypes.contains(metric.type.toUpperCase())) {
                    throw new InvalidMetricTypeException('Tipo de métrica inválido: ' + metric.type);
                }
            }
        }
    }
}