@isTest
private class ChartServicePresenceControllerTest {

    @testSetup
    static void setupTestData() {

        // Crea datos de prueba para Shift_Block__c
        Shift_Block__c shiftBlocka = new Shift_Block__c();
        shiftBlocka.Start__c = DateTime.newInstance(2024, 12, 6, 10, 34, 45);
        shiftBlocka.End__c =DateTime.newInstance(2024, 12, 6, 12, 34, 45);
        shiftBlocka.Type__c = 'Work';
        insert shiftBlocka;
        Shift_Block__c shiftBlockb = new Shift_Block__c();
        shiftBlockb.Start__c = DateTime.newInstance(2024, 12, 6, 10, 34, 45);
        shiftBlockb.End__c = DateTime.newInstance(2024, 12, 6, 12, 34, 45);
        shiftBlockb.Type__c = 'Break';
        insert shiftBlockb;
        Shift_Block__c shiftBlockc = new Shift_Block__c();
        shiftBlockc.Start__c = DateTime.newInstance(2024, 12, 6, 10, 34, 45);
        shiftBlockc.End__c = DateTime.newInstance(2024, 12, 6, 12, 34, 45);
        shiftBlockc.Type__c = 'Holiday';
        insert shiftBlockc;
        Shift_Block__c shiftBlockd = new Shift_Block__c();
        shiftBlockd.Start__c = DateTime.newInstance(2024, 12, 6, 10, 34, 45);
        shiftBlockd.End__c = DateTime.newInstance(2024, 12, 6, 12, 34, 45);
        shiftBlockd.Type__c = 'Day Off';
        insert shiftBlockd;
        Shift_Block__c shiftBlocke = new Shift_Block__c();
        shiftBlocke.Start__c = DateTime.newInstance(2024, 12, 6, 10, 34, 45);
        shiftBlocke.End__c = DateTime.newInstance(2024, 12, 6, 12, 34, 45);
        shiftBlocke.Type__c = 'Half-yearly day off';
        insert shiftBlocke;
        Shift_Block__c shiftBlockf = new Shift_Block__c();
        shiftBlockf.Start__c = DateTime.newInstance(2024, 12, 6, 10, 34, 45);
        shiftBlockf.End__c =DateTime.newInstance(2024, 12, 6, 12, 34, 45);
        shiftBlockf.Type__c = 'Unpaid day off';
        insert shiftBlockf;
        Shift_Block__c shiftBlockg = new Shift_Block__c();
        shiftBlockg.Start__c = DateTime.newInstance(2024, 12, 6, 10, 34, 45);
        shiftBlockg.End__c = DateTime.newInstance(2024, 12, 6, 12, 34, 45);
        shiftBlockg.Type__c = 'Birthday';
        insert shiftBlockg;
        Shift_Block__c shiftBlockh = new Shift_Block__c();
        shiftBlockh.Start__c = DateTime.newInstance(2024, 12, 6, 10, 34, 45);
        shiftBlockh.End__c = DateTime.newInstance(2024, 12, 6, 12, 34, 45);
        shiftBlockh.Type__c = 'Maternity leave';
        insert shiftBlockh;
        Shift_Block__c shiftBlocki = new Shift_Block__c();
        shiftBlocki.Start__c =DateTime.newInstance(2024, 12, 6, 10, 34, 45);
        shiftBlocki.End__c = DateTime.newInstance(2024, 12, 6, 12, 34, 45);
        shiftBlocki.Type__c = 'Special leave';
        insert shiftBlocki;
        Shift_Block__c shiftBlockj = new Shift_Block__c();
        shiftBlockj.Start__c = DateTime.newInstance(2024, 12, 6, 10, 34, 45);
        shiftBlockj.End__c = DateTime.newInstance(2024, 12, 6, 12, 34, 45);
        shiftBlockj.Type__c = 'Training';
        insert shiftBlockj;

        // Crea un canal de prueba en un contacto
        Contact contact = new Contact(LastName = 'Test Contact', Channel__c = 'Telefono');
        insert contact;
    }

    @isTest
    static void testGetChartData() {
        Date searchDate = Date.newInstance(2024, 12, 6);
        String channel = 'Telefono';

        Test.startTest();
        ChartAgentWorkController.ChartDataWrapper result = ChartServicePresenceController.getChartData(searchDate, channel);
        Test.stopTest();

        System.assertNotEquals(null, result, 'El resultado no debe ser nulo');
        System.assert(result.datasets.size() > 0, 'Debe haber datasets en el resultado');
    }

    @isTest
    static void testBuildChartDataWrapper() {
        Map<String, List<Object>> mapItems = new Map<String, List<Object>>();
        List<Shift_Block__c> blocks = [SELECT Id, Start__c, End__c, Type__c FROM Shift_Block__c LIMIT 10];
        mapItems.put('Test Contact', blocks);

        Test.startTest();
        System.debug('debug map ' + mapItems);
        ChartAgentWorkController.ChartDataWrapper result = ChartServicePresenceController.buildChartDataWrapper(mapItems);
        Test.stopTest();

        System.debug('test  result: ' + result);
        System.assertNotEquals(null, result, 'El resultado no debe ser nulo');
        System.assert(result.datasets.size() > 0, 'Debe haber datasets en el resultado');
    }

    @isTest
    static void testGetMinutesFromMidnight() {
        DateTime dt = DateTime.newInstance(2024, 12, 6, 12, 34, 45);
        Integer minutes = ChartServicePresenceController.getMinutesFromMidnight(dt);

        System.assertEquals(755, minutes, 'Los minutos desde medianoche deben ser 754');
    }

    @isTest
    static void testGetMinutesFromMidnightException() {

        try {
            Integer minutes = ChartServicePresenceController.getMinutesFromMidnight(null);
        } catch(IllegalArgumentException ex) {
            System.assertNotEquals(null, ex);
        }
    }

    @isTest
    static void testGetChannels() {
        Test.startTest();
        List<String> channels = ChartServicePresenceController.getChannels();
        Test.stopTest();

        System.assertNotEquals(null, channels, 'El resultado no debe ser nulo');
        System.assert(channels.size() > 0, 'Debe haber canales disponibles');
    }

    @isTest
    public static void testGetChartConfig() {
        Map<String, String> config = ChartServicePresenceController.getChartConfig();

        System.assertEquals('rgba(120, 255, 170, 1)', config.get('USP_AVAILABLE_BORDER_COLOR'));
        System.assertEquals('rgba(120, 255, 170, 1)', config.get('USP_AVAILABLE_BACKGROUND_COLOR'));
        System.assertEquals('rgba(146, 211, 254, 1)', config.get('USP_AVAILABLE_CHAT_BORER_COLOR'));
        System.assertEquals('rgba(146, 211, 254, 1)', config.get('USP_AVAILABLE_CHAT_BACKGROUND_COLOR'));
        System.assertEquals('rgba(82, 205, 138, 1)', config.get('USP_PRESENCIAL_BORDER_COLOR'));
        System.assertEquals('rgba(82, 205, 138, 1)', config.get('USP_PRESENCIAL_BACKGROUND_COLOR'));
        System.assertEquals('rgba(75, 155, 109, 1)', config.get('USP_WSP_BORDER_COLOR'));
        System.assertEquals('rgba(75, 155, 109, 1)', config.get('USP_WSP_BACKGROUND_COLOR'));
        System.assertEquals('rgba(54, 143, 137, 1)', config.get('USP_SOCIAL_BORDER_COLOR'));
        System.assertEquals('rgba(54, 143, 137, 1)', config.get('USP_SOCIAL_BACKGROUND_COLOR'));
        System.assertEquals('rgba(255, 209, 111, 1)', config.get('USP_PHONE_BORDER_COLOR'));
        System.assertEquals('rgba(255, 209, 111, 1)', config.get('USP_PHONE_BACKGROUND_COLOR'));
        System.assertEquals('rgba(249, 96, 0, 1)', config.get('USP_BUSY_BORDER_COLOR'));
        System.assertEquals('rgba(249, 96, 0, 1)', config.get('USP_BUSY_BACKGROUND_COLOR'));
        System.assertEquals('rgba(233, 227, 60, 1)', config.get('USP_LUNCH_BORDER_COLOR'));
        System.assertEquals('rgba(233, 227, 60, 1)', config.get('USP_LUNCH_BACKGROUND_COLOR'));
        System.assertEquals('rgba(215, 209, 59, 1)', config.get('USP_BREAK_BORDER_COLOR'));
        System.assertEquals('rgba(215, 209, 59, 1)', config.get('USP_BREAK_BACKGROUND_COLOR'));
        System.assertEquals('rgba(125, 125, 125, 1)', config.get('USP_OFFLINE_BORDER_COLOR'));
        System.assertEquals('rgba(125, 125, 125, 1)', config.get('USP_OFFLINE_BACKGROUND_COLOR'));
        System.assertEquals('rgba(0, 255, 0, 0.25)', config.get('AVAILABLE_BORDER_COLOR'));
        System.assertEquals('rgba(0, 255, 0, 0.25)', config.get('AVAILABLE_BACKGROUND_COLOR'));
        System.assertEquals('rgba(226, 245, 16, 0.5)', config.get('BREAK_BORDER_COLOR'));
        System.assertEquals('rgba(226, 245, 16, 0.5)', config.get('BREAK_BACKGROUND_COLOR'));
        System.assertEquals('rgba(194, 135, 255, 0.5)', config.get('VACATION_BORDER_COLOR'));
        System.assertEquals('rgba(194, 135, 255, 0.5)', config.get('VACATION_BACKGROUND_COLOR'));
        System.assertEquals('rgba(255, 0, 0, 0.25)', config.get('DAY_OFF_BORDER_COLOR'));
        System.assertEquals('rgba(255, 0, 0, 0.25)', config.get('DAY_OFF_BACKGROUND_COLOR'));
        System.assertEquals('rgba(255, 198, 255, 0.5)', config.get('TRAINING_BORDER_COLOR'));
        System.assertEquals('rgba(255, 198, 255, 0.5)', config.get('TRAINING_BACKGROUND_COLOR'));
        System.assertEquals('rgba(249, 0, 129, 0.25)', config.get('LICENSE_BORDER_COLOR'));
        System.assertEquals('rgba(249, 0, 129, 0.25)', config.get('LICENSE_BACKGROUND_COLOR'));
        System.assertEquals('rgba(233, 236, 239, 0.25)', config.get('DEFAULT_BORDER_COLOR'));
        System.assertEquals('rgba(233, 236, 239, 0.25)', config.get('DEFAULT_BACKGROUND_COLOR'));
        
        // Validar los valores numéricos (DEFAULT_BORDER_WIDTH, DEFAULT_FILL, DEFAULT_LABEL)
        System.assertEquals('15', config.get('DEFAULT_BORDER_WIDTH'));
        System.assertEquals('true', config.get('DEFAULT_FILL'));
        System.assertEquals('OTRO', config.get('DEFAULT_LABEL'));
    }
}