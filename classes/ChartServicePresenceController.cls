public with sharing class ChartServicePresenceController {
    
    // Colores y etiquetas para ServicePresence
    private static final String USP_AVAILABLE_BORDER_COLOR = 'rgba(120, 255, 170, 1)';
    private static final String USP_AVAILABLE_BACKGROUND_COLOR = 'rgba(120, 255, 170, 1)';
    
    private static final String USP_AVAILABLE_CHAT_BORER_COLOR = 'rgba(146, 211, 254, 1)';
    private static final String USP_AVAILABLE_CHAT_BACKGROUND_COLOR = 'rgba(146, 211, 254, 1)';
    
    private static final String USP_PRESENCIAL_BORDER_COLOR = 'rgba(82, 205, 138, 1)';
    private static final String USP_PRESENCIAL_BACKGROUND_COLOR = 'rgba(82, 205, 138, 1)';
    
    private static final String USP_WSP_BORDER_COLOR = 'rgba(75, 155, 109, 1)';
    private static final String USP_WSP_BACKGROUND_COLOR = 'rgba(75, 155, 109, 1)';

    private static final String USP_SOCIAL_BORDER_COLOR = 'rgba(54, 143, 137, 1)';
    private static final String USP_SOCIAL_BACKGROUND_COLOR = 'rgba(54, 143, 137, 1)';

    private static final String USP_PHONE_BORDER_COLOR = 'rgba(255, 209, 111, 1)';
    private static final String USP_PHONE_BACKGROUND_COLOR = 'rgba(255, 209, 111, 1)';

    private static final String USP_LUNCH_BORDER_COLOR = 'rgba(233, 227, 60, 1)';
    private static final String USP_LUNCH_BACKGROUND_COLOR = 'rgba(233, 227, 60, 1)';

    private static final String USP_BREAK_BORDER_COLOR = 'rgba(215, 209, 59, 1)';
    private static final String USP_BREAK_BACKGROUND_COLOR = 'rgba(215, 209, 59, 1)';

    private static final String USP_TRAINING_BORDER_COLOR = 'rgba(202, 124, 255, 1)';
    private static final String USP_TRAINING_BACKGROUND_COLOR = 'rgba(202, 124, 255, 1)';

    private static final String USP_SANITARY_BORDER_COLOR = 'rgba(101, 44, 0, 1)';
    private static final String USP_SANITARY_BACKGROUND_COLOR = 'rgba(101, 44, 0, 1)';

    private static final String USP_BUSY_BORDER_COLOR = 'rgba(249, 96, 0, 1)';
    private static final String USP_BUSY_BACKGROUND_COLOR = 'rgba(249, 96, 0, 1)';

    private static final String USP_OFFLINE_BORDER_COLOR = 'rgba(125, 125, 125, 1)';
    private static final String USP_OFFLINE_BACKGROUND_COLOR = 'rgba(125, 125, 125, 1)';
    
    // Colores y etiquetas para ShiftBlocks
    private static final String AVAILABLE_BORDER_COLOR = 'rgba(0, 255, 0, 0.25)';
    private static final String AVAILABLE_BACKGROUND_COLOR = 'rgba(0, 255, 0, 0.25)';
    
    private static final String BREAK_BORDER_COLOR = 'rgba(226, 245, 16, 0.5)';
    private static final String BREAK_BACKGROUND_COLOR = 'rgba(226, 245, 16, 0.5)';
    
    private static final String VACATION_BORDER_COLOR = 'rgba(194, 135, 255, 0.5)';
    private static final String VACATION_BACKGROUND_COLOR = 'rgba(194, 135, 255, 0.5)';
    
    private static final String DAY_OFF_BORDER_COLOR = 'rgba(255, 0, 0, 0.25)';
    private static final String DAY_OFF_BACKGROUND_COLOR = 'rgba(255, 0, 0, 0.25)';

    private static final String TRAINING_BORDER_COLOR = 'rgba(255, 198, 255, 0.5)';
    private static final String TRAINING_BACKGROUND_COLOR = 'rgba(255, 198, 255, 0.5)';

    private static final String LICENSE_BORDER_COLOR = 'rgba(249, 0, 129, 0.25)';
    private static final String LICENSE_BACKGROUND_COLOR = 'rgba(249, 0, 129, 0.25)';
    

    // Colores y etiquedas default
    private static final String DEFAULT_BORDER_COLOR = 'rgba(233, 236, 239, 0.25)';
    private static final String DEFAULT_BACKGROUND_COLOR = 'rgba(233, 236, 239, 0.25)';
    private static final Integer DEFAULT_BORDER_WIDTH = 15;
    private static final Boolean DEFAULT_FILL = true;
    private static final String DEFAULT_LABEL = 'OTRO';


    @AuraEnabled(Cacheable=false)
    public static ChartAgentWorkController.ChartDataWrapper getChartData(Date searchDate, String channel) {
        Map<String, List<Object>> mapItems = ServicePresenceDAO.getServicePresence(searchDate, channel);
        ChartAgentWorkController.ChartDataWrapper chartData = buildChartDataWrapper(mapItems);
        return chartData;
    }

    public static ChartAgentWorkController.ChartDataWrapper buildChartDataWrapper(Map<String, List<Object>> mapItems) {
        List<ChartAgentWorkController.ChartDatasetWrapper> datasets = new List<ChartAgentWorkController.ChartDatasetWrapper>();
    
        for (String contactName : mapItems.keySet()) {
            List<Object> items = mapItems.get(contactName);
            for (Object item : items) {
                if (item instanceof UserServicePresence) {
                    UserServicePresence usp = (UserServicePresence) item;
                    processUserServicePresence(datasets, usp, contactName);
                } else if (item instanceof Shift_Block__c) {
                    Shift_Block__c shiftBlock = (Shift_Block__c) item;
                    processShiftBlocks(datasets, shiftBlock, contactName);
                }
                }
            }
        return new ChartAgentWorkController.ChartDataWrapper(datasets);
    }

    private static void processShiftBlocks(List<ChartAgentWorkController.ChartDatasetWrapper> datasets, Shift_Block__c shiftBlock, String contactName) {

        List<ChartAgentWorkController.AxisDataWrapper> axisData = new List<ChartAgentWorkController.AxisDataWrapper>();
        
        if (shiftBlock.Start__c != null) {
            axisData.add(new ChartAgentWorkController.AxisDataWrapper(getMinutesFromMidnight(shiftBlock.Start__c), contactName));
        }
        if (shiftBlock.End__c != null) {
            axisData.add(new ChartAgentWorkController.AxisDataWrapper(getMinutesFromMidnight(shiftBlock.End__c), contactName));
        }

        String label = '';
        String borderColor = '';
        String backgroundColor = '';

        switch on shiftBlock.Type__c {
            when 'Work' {
                label = 'Disponible';
                borderColor = AVAILABLE_BORDER_COLOR;
                backgroundColor = AVAILABLE_BACKGROUND_COLOR;
            }
            when 'Break' {
                label = 'Descanso';
                borderColor = BREAK_BORDER_COLOR;
                backgroundColor = BREAK_BACKGROUND_COLOR;
            }
            when 'Holiday' {
                label = 'Vacaciones';
                borderColor = VACATION_BORDER_COLOR;
                backgroundColor = VACATION_BACKGROUND_COLOR;
            }
            when 'Day Off' {
                label = 'Dia libre';
                borderColor = DAY_OFF_BORDER_COLOR;
                backgroundColor = DAY_OFF_BORDER_COLOR;
            }
            when 'Half-yearly day off' {
                label = 'Dia libre semestral';
                borderColor = DAY_OFF_BORDER_COLOR;
                backgroundColor = DAY_OFF_BORDER_COLOR;
            }
            when 'Unpaid day off' {
                label = 'Dia libre sin goce';
                borderColor = DAY_OFF_BORDER_COLOR;
                backgroundColor = DAY_OFF_BORDER_COLOR;
            }
            when 'Birthday' {
                label = 'Cumpleaños';
                borderColor = DAY_OFF_BORDER_COLOR;
                backgroundColor = DAY_OFF_BORDER_COLOR;
            }
            when 'Maternity leave' {
                label = 'Licencia maternidad';
                borderColor = DAY_OFF_BORDER_COLOR;
                backgroundColor = DAY_OFF_BORDER_COLOR;
            }
            when 'Special leave' {
                label = 'Licencia especial';
                borderColor = DAY_OFF_BORDER_COLOR;
                backgroundColor = DAY_OFF_BORDER_COLOR;
            }
            when 'Training' {
                label = 'Entrenamiento';
                borderColor = TRAINING_BORDER_COLOR;
                backgroundColor = TRAINING_BACKGROUND_COLOR;
            }
            when else {
                label = 'Otro';
                borderColor = DEFAULT_BORDER_COLOR;
                backgroundColor = DEFAULT_BACKGROUND_COLOR;
            }
        }
        datasets.add(new ChartAgentWorkController.ChartDatasetWrapper(label,contactName,null,axisData,borderColor,backgroundColor,DEFAULT_BORDER_WIDTH,DEFAULT_FILL));
    }

    private static void processUserServicePresence(List<ChartAgentWorkController.ChartDatasetWrapper> datasets, UserServicePresence usp, String contactName) {
        String labelFromObj = usp.ServicePresenceStatus.MasterLabel;
        String label = '';
        String borderColor = '';
        String backgroundColor = '';

        switch on labelFromObj {
            when 'Disponible' { //TODO: modificar labels en base a lo que se cargue en el ambiente
                label = labelFromObj;
                borderColor = USP_AVAILABLE_BORDER_COLOR;
                backgroundColor = USP_AVAILABLE_BACKGROUND_COLOR;
            }
            when 'Disponible - Chat' {
                label = labelFromObj;
                borderColor = USP_AVAILABLE_CHAT_BORER_COLOR;
                backgroundColor = USP_AVAILABLE_CHAT_BACKGROUND_COLOR;
            }
            when 'Disponible - Presencial' {
                label = labelFromObj;
                borderColor = USP_PRESENCIAL_BORDER_COLOR;
                backgroundColor = USP_PRESENCIAL_BACKGROUND_COLOR;
            }
            when 'Disponible - Whastapp' {
                label = labelFromObj;
                borderColor = USP_WSP_BORDER_COLOR;
                backgroundColor = USP_WSP_BACKGROUND_COLOR;
            }
            when 'Disponible - Teléfono' {
                label = labelFromObj;
                borderColor = USP_PHONE_BORDER_COLOR;
                backgroundColor = USP_PHONE_BACKGROUND_COLOR;
            }
            when 'Disponible - Redes' {
                label = labelFromObj;
                borderColor = USP_SOCIAL_BORDER_COLOR;
                backgroundColor = USP_SOCIAL_BACKGROUND_COLOR;
            }
            when 'No Disponible' {
                label = labelFromObj;
                borderColor = USP_BUSY_BORDER_COLOR;
                backgroundColor = USP_BUSY_BACKGROUND_COLOR;
            }
            when 'Ausente - Almuerzo' {
                label = labelFromObj;
                borderColor = USP_LUNCH_BORDER_COLOR;
                backgroundColor = USP_LUNCH_BACKGROUND_COLOR;
            }
            when 'Ausente - Break' {
                label = labelFromObj;
                borderColor = USP_BREAK_BORDER_COLOR;
                backgroundColor = USP_BREAK_BACKGROUND_COLOR;
            }
            when 'Ausente - Entrenamiento' {
                label = labelFromObj;
                borderColor = USP_TRAINING_BORDER_COLOR;
                backgroundColor = USP_TRAINING_BACKGROUND_COLOR;
            }
            when 'Ausente - Sanitario' {
                label = labelFromObj;
                borderColor = USP_SANITARY_BORDER_COLOR;
                backgroundColor = USP_SANITARY_BACKGROUND_COLOR;
            }
            when 'Ocupado' {
                label = labelFromObj;
                borderColor = USP_BUSY_BORDER_COLOR;
                backgroundColor = USP_BUSY_BACKGROUND_COLOR;
            }
            when 'Offline' {
                label = labelFromObj;
                borderColor = USP_OFFLINE_BORDER_COLOR;
                backgroundColor = USP_OFFLINE_BACKGROUND_COLOR;
            }
            when else {
                label = labelFromObj;
                borderColor = DEFAULT_BORDER_COLOR;
                backgroundColor = DEFAULT_BACKGROUND_COLOR;
            }
        }

        List<ChartAgentWorkController.AxisDataWrapper> axisData = new List<ChartAgentWorkController.AxisDataWrapper>();
        if (agentWork.AcceptDateTime != null) {
            axisData.add(new ChartAgentWorkController.AxisDataWrapper(getMinutesFromMidnight(usp.StatusStartDate), contactName));
        }
        if (agentWork.CloseDateTime != null) {
            axisData.add(new ChartAgentWorkController.AxisDataWrapper(getMinutesFromMidnight(usp.StatusEndDate), contactName));
        }
        
        datasets.add(new ChartAgentWorkController.ChartDatasetWrapper(label,contactName,usp.Idle_Time__c,axisData,borderColor,backgroundColor,DEFAULT_BORDER_WIDTH,DEFAULT_FILL));
    }

    public static Integer getMinutesFromMidnight(DateTime dt) {
        if (dt == null) {
            throw new IllegalArgumentException('DateTime no puede ser nulo.');
        }
        Integer hours = dt.hour();
        Integer minutes = dt.minute();
        Integer seconds = dt.second();

        Integer totalMinutes = (hours * 60) + minutes;

        if (seconds >= 30) {
            totalMinutes++;
        }

        return totalMinutes;
    }

    @AuraEnabled(Cacheable = true)
    public static List<String> getChannels() {
        List<String> picklistValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Contact.Channel__c.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry entry : picklistEntries) {
            picklistValues.add(entry.getLabel());
        }
        return picklistValues;
    }


    public static Map<String, String> getChartConfig() {
        Map<String, String> config = new Map<String, String>();
        
        // Añadimos las nuevas constantes al mapa
        config.put('USP_AVAILABLE_BORDER_COLOR', USP_AVAILABLE_BORDER_COLOR);
        config.put('USP_AVAILABLE_BACKGROUND_COLOR', USP_AVAILABLE_BACKGROUND_COLOR);
        
        config.put('USP_AVAILABLE_CHAT_BORER_COLOR', USP_AVAILABLE_CHAT_BORER_COLOR);
        config.put('USP_AVAILABLE_CHAT_BACKGROUND_COLOR', USP_AVAILABLE_CHAT_BACKGROUND_COLOR);
        
        config.put('USP_PRESENCIAL_BORDER_COLOR', USP_PRESENCIAL_BORDER_COLOR);
        config.put('USP_PRESENCIAL_BACKGROUND_COLOR', USP_PRESENCIAL_BACKGROUND_COLOR);
        
        config.put('USP_WSP_BORDER_COLOR', USP_WSP_BORDER_COLOR);
        config.put('USP_WSP_BACKGROUND_COLOR', USP_WSP_BACKGROUND_COLOR);
        
        config.put('USP_PHONE_BORDER_COLOR', USP_PHONE_BORDER_COLOR);
        config.put('USP_PHONE_BACKGROUND_COLOR', USP_PHONE_BACKGROUND_COLOR);
        
        config.put('USP_BUSY_BORDER_COLOR', USP_BUSY_BORDER_COLOR);
        config.put('USP_BUSY_BACKGROUND_COLOR', USP_BUSY_BACKGROUND_COLOR);
        
        config.put('USP_LUNCH_BORDER_COLOR', USP_LUNCH_BORDER_COLOR);
        config.put('USP_LUNCH_BACKGROUND_COLOR', USP_LUNCH_BACKGROUND_COLOR);
        
        config.put('USP_BREAK_BORDER_COLOR', USP_BREAK_BORDER_COLOR);
        config.put('USP_BREAK_BACKGROUND_COLOR', USP_BREAK_BACKGROUND_COLOR);

        config.put('USP_SOCIAL_BORDER_COLOR', USP_SOCIAL_BORDER_COLOR);
        config.put('USP_SOCIAL_BACKGROUND_COLOR', USP_SOCIAL_BACKGROUND_COLOR);
        
        config.put('USP_OFFLINE_BORDER_COLOR', USP_OFFLINE_BORDER_COLOR);
        config.put('USP_OFFLINE_BACKGROUND_COLOR', USP_OFFLINE_BACKGROUND_COLOR);
        
        config.put('AVAILABLE_BORDER_COLOR', AVAILABLE_BORDER_COLOR);
        config.put('AVAILABLE_BACKGROUND_COLOR', AVAILABLE_BACKGROUND_COLOR);
        
        config.put('BREAK_BORDER_COLOR', BREAK_BORDER_COLOR);
        config.put('BREAK_BACKGROUND_COLOR', BREAK_BACKGROUND_COLOR);
        
        config.put('VACATION_BORDER_COLOR', VACATION_BORDER_COLOR);
        config.put('VACATION_BACKGROUND_COLOR', VACATION_BACKGROUND_COLOR);
        
        config.put('DAY_OFF_BORDER_COLOR', DAY_OFF_BORDER_COLOR);
        config.put('DAY_OFF_BACKGROUND_COLOR', DAY_OFF_BACKGROUND_COLOR);
        
        config.put('TRAINING_BORDER_COLOR', TRAINING_BORDER_COLOR);
        config.put('TRAINING_BACKGROUND_COLOR', TRAINING_BACKGROUND_COLOR);
        
        config.put('LICENSE_BORDER_COLOR', LICENSE_BORDER_COLOR);
        config.put('LICENSE_BACKGROUND_COLOR', LICENSE_BACKGROUND_COLOR);
        
        config.put('DEFAULT_BORDER_COLOR', DEFAULT_BORDER_COLOR);
        config.put('DEFAULT_BACKGROUND_COLOR', DEFAULT_BACKGROUND_COLOR);
        
        config.put('DEFAULT_BORDER_WIDTH', String.valueOf(DEFAULT_BORDER_WIDTH));
        config.put('DEFAULT_FILL', String.valueOf(DEFAULT_FILL));
        config.put('DEFAULT_LABEL', DEFAULT_LABEL);

        return config;
    }
}