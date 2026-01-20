@isTest
private class ChartAgentWorkControllerTest {

    @TestSetup
    static void setupTestData() {

        // Simula datos de turno (shifts) si es necesario
        Shift__c mockShift = new Shift__c();
        mockShift.Start__c = DateTime.newInstance(2024, 12, 6, 10, 34, 45);
        mockShift.End__c = DateTime.newInstance(2024, 12, 6, 12, 34, 45);

        insert mockShift;
    }

    @IsTest
    static void testGetChartData() {

        Test.startTest();
        Date searchDate = Date.newInstance(2024, 12, 6);
        ChartAgentWorkController.ChartDataWrapper result = ChartAgentWorkController.getChartData(searchDate, 'Chat');
        Test.stopTest();

        System.assertNotEquals(null, result, 'El resultado no debe ser nulo.');
        System.assert(result.datasets.size() == 0, 'No se encontraron resultados, array vacio.');
    }

    @IsTest
    static void testBuildChartDataWrapper() {
        Map<String, List<Object>> mockData = new Map<String, List<Object>>();
        

        Shift__c shift = [SELECT Id, Start__c, End__c FROM Shift__c LIMIT 1];
        Map<String, Object> itemFields = new Map<String, Object>();
        itemFields.put('shift', shift);
        itemFields.put('isDayOff', false);

        Object item = (Object) itemFields;

        mockData.put('Test User', new List<Object>{ item });

        ChartAgentWorkController.ChartDataWrapper result = ChartAgentWorkController.buildChartDataWrapper(mockData);

        System.assertNotEquals(null, result, 'El resultado no debe ser nulo.');
    }

    @IsTest
    static void testGetChannels() {
        // Llamada al método
        Test.startTest();
        List<String> channels = ChartAgentWorkController.getChannels();
        Test.stopTest();

        // Validaciones
        System.assertNotEquals(null, channels, 'Los canales no deben ser nulos.');
        System.assert(channels.size() > 0, 'Se esperaban valores de picklist.');
    }

    @isTest
    static void testGetMinutesFromMidnight() {
        DateTime dt = DateTime.newInstance(2024, 12, 6, 12, 34, 45);
        Integer minutes = ChartAgentWorkController.getMinutesFromMidnight(dt);

        System.assertEquals(755, minutes, 'Los minutos desde medianoche deben ser 754');
    }

    @isTest
    static void testGetMinutesFromMidnightException() {

        try {
            Integer minutes = ChartAgentWorkController.getMinutesFromMidnight(null);
        } catch(IllegalArgumentException ex) {
            System.assertNotEquals(null, ex);
        }
    }

    @isTest
    static void testChartConfig() {
        // Llamamos al método que devuelve el mapa con todos los valores
        Map<String, String> config = ChartAgentWorkController.getChartConfig();
        
        // Verificamos que los valores de las constantes sean correctos
        System.assertEquals(config.get('Caso'), 'rgba(255, 99, 132, 1)', 'El color del borde de Caso no es el esperado.');
        System.assertEquals(config.get('Caso_BACKGROUND'), 'rgba(255, 99, 132, 1)', 'El color de fondo de Caso no es el esperado.');
        
        System.assertEquals(config.get('Llamada'), 'rgba(54, 162, 235, 1)', 'El color del borde de Llamada no es el esperado.');
        System.assertEquals(config.get('Llamada_BACKGROUND'), 'rgba(54, 162, 235, 1)', 'El color de fondo de Llamada no es el esperado.');
        
        System.assertEquals(config.get('Chat'), 'rgba(75, 192, 192, 1)', 'El color del borde de Chat no es el esperado.');
        System.assertEquals(config.get('Chat_BACKGROUND'), 'rgba(75, 192, 192, 1)', 'El color de fondo de Chat no es el esperado.');
        
        System.assertEquals(config.get('Turno'), 'rgba(194, 135, 255, 0.25)', 'El color del borde de Turno no es el esperado.');
        System.assertEquals(config.get('Turno_BACKGROUND'), 'rgba(194, 135, 255, 0.25)', 'El color de fondo de Turno no es el esperado.');
        
        System.assertEquals(config.get('Dia Libre'), 'rgba(255, 0, 0, 0.25)', 'El color del borde de Dia Libre no es el esperado.');
        System.assertEquals(config.get('Dia Libre_BACKGROUND'), 'rgba(255, 0, 0, 0.25)', 'El color de fondo de Dia Libre no es el esperado.');
        
        System.assertEquals(config.get('DEFAULT_BORDER_WIDTH'), '15', 'El valor por defecto del ancho del borde no es el esperado.');
        System.assertEquals(config.get('DEFAULT_FILL'), 'true', 'El valor por defecto de relleno no es el esperado.');
        System.assertEquals(config.get('DEFAULT_LABEL'), 'OTRO', 'El valor por defecto de etiqueta no es el esperado.');
    }
}