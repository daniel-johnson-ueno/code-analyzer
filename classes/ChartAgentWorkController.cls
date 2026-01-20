public with sharing class ChartAgentWorkController {
    
    // Colores y etiquetas para turnos y otros elementos
    private static final String CASE_LABEL = 'Caso';
    private static final String CASE_BORDER_COLOR = 'rgba(255, 99, 132, 1)';
    private static final String CASE_BACKGROUND_COLOR = 'rgba(255, 99, 132, 1)';
    
    private static final String CALL_LABEL = 'Llamada';
    private static final String CALL_BORDER_COLOR = 'rgba(54, 162, 235, 1)';
    private static final String CALL_BACKGROUND_COLOR = 'rgba(54, 162, 235, 1)';
    
    private static final String CHAT_LABEL = 'Chat';
    private static final String CHAT_BORDER_COLOR = 'rgba(75, 192, 192, 1)';
    private static final String CHAT_BACKGROUND_COLOR = 'rgba(75, 192, 192, 1)';
    
    private static final String SHIFT_LABEL = 'Turno';
    private static final String SHIFT_BORDER_COLOR = 'rgba(194, 135, 255, 0.25)';
    private static final String SHIFT_BACKGROUND_COLOR = 'rgba(194, 135, 255, 0.25)';
    
    private static final String SHIFT_DAY_OFF_LABEL = 'Dia Libre';
    private static final String SHIFT_DAY_OFF_BORDER_COLOR = 'rgba(255, 0, 0, 0.25)';
    private static final String SHIFT_DAY_OFF_BACKGROUND_COLOR = 'rgba(255, 0, 0, 0.25)';
    
    private static final Integer DEFAULT_BORDER_WIDTH = 15;
    private static final Boolean DEFAULT_FILL = true;
    private static final String DEFAULT_LABEL = 'OTRO';

    public static Map<String, String> getChartConfig() {
        Map<String, String> config = new Map<String, String>();
        config.put(CASE_LABEL, CASE_BORDER_COLOR);
        config.put(CASE_LABEL + '_BACKGROUND', CASE_BACKGROUND_COLOR);
        config.put(CALL_LABEL, CALL_BORDER_COLOR);
        config.put(CALL_LABEL + '_BACKGROUND', CALL_BACKGROUND_COLOR);
        config.put(CHAT_LABEL, CHAT_BORDER_COLOR);
        config.put(CHAT_LABEL + '_BACKGROUND', CHAT_BACKGROUND_COLOR);
        config.put(SHIFT_LABEL, SHIFT_BORDER_COLOR);
        config.put(SHIFT_LABEL + '_BACKGROUND', SHIFT_BACKGROUND_COLOR);
        config.put(SHIFT_DAY_OFF_LABEL, SHIFT_DAY_OFF_BORDER_COLOR);
        config.put(SHIFT_DAY_OFF_LABEL + '_BACKGROUND', SHIFT_DAY_OFF_BACKGROUND_COLOR);
        config.put('DEFAULT_BORDER_WIDTH', String.valueOf(DEFAULT_BORDER_WIDTH));
        config.put('DEFAULT_FILL', String.valueOf(DEFAULT_FILL));
        config.put('DEFAULT_LABEL', DEFAULT_LABEL);
        return config;
    }

    public class ChartDataWrapper {
        @AuraEnabled
        public List<ChartDatasetWrapper> datasets;

        public ChartDataWrapper(List<ChartDatasetWrapper> datasets) {
            this.datasets = datasets;
        }
    }

    public class ChartDatasetWrapper {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String userName;
        @AuraEnabled
        public String recordId;
        @AuraEnabled
        public List<AxisDataWrapper> data;
        @AuraEnabled
        public String borderColor;
        @AuraEnabled
        public String backgroundColor;
        @AuraEnabled
        public Integer borderWidth;
        @AuraEnabled
        public Boolean fill;

        public ChartDatasetWrapper(String label, String userName, String recordId, List<AxisDataWrapper> data, String borderColor, String backgroundColor, Integer borderWidth, Boolean fill) {
            this.label = label;
            this.userName = userName;
            this.recordId = recordId;
            this.data = data;
            this.borderColor = borderColor;
            this.backgroundColor = backgroundColor;
            this.borderWidth = borderWidth;
            this.fill = fill;
        }
    }

    public class AxisDataWrapper {
        @AuraEnabled
        public Integer x;
        @AuraEnabled
        public String y;

        public AxisDataWrapper(Integer x, String y) {
            this.x = x;
            this.y = y;
        }
    }

    @AuraEnabled(Cacheable=false)
    public static ChartDataWrapper getChartData(Date searchDate, String channel) {
        Map<String, List<Object>> mapItems = AgentWorkDAO.getShifts(searchDate, channel);
        ChartDataWrapper chartData = buildChartDataWrapper(mapItems);
        return chartData;
    }

    public static ChartDataWrapper buildChartDataWrapper(Map<String, List<Object>> mapItems) {
        List<ChartDatasetWrapper> datasets = new List<ChartDatasetWrapper>();
    
        for (String contactName : mapItems.keySet()) {
            List<Object> items = mapItems.get(contactName);
            for (Object item : items) {
                if (item instanceof AgentWork) {
                    AgentWork agentWork = (AgentWork) item;
                    processAgentWork(datasets, agentWork, contactName);
                } else {
                    try {
                        System.debug('a ver este item: ' + item);
                        if (item != null) {
                            AgentWorkDAO.ShiftWrapper shiftWrapper = new AgentWorkDAO.ShiftWrapper(item);
                            processShift(datasets, shiftWrapper, contactName);
                        }
                    }catch(Exception ex) {
                        System.debug('No se pudo instanciar el item de tipo ShiftWrapper: ' + ex);
                    }
                }
            }
        }
        return new ChartDataWrapper(datasets);
    }

    private static void processShift(List<ChartDatasetWrapper> datasets, AgentWorkDAO.ShiftWrapper shiftWrapper, String contactName) {
        Shift__c shift = shiftWrapper.shift;
        List<AxisDataWrapper> axisData = new List<AxisDataWrapper>();
        
        if (shift.Start__c != null) {
            axisData.add(new AxisDataWrapper(getMinutesFromMidnight(shift.Start__c), contactName));
        }
        if (shift.End__c != null) {
            axisData.add(new AxisDataWrapper(getMinutesFromMidnight(shift.End__c), contactName));
        }

        String label = SHIFT_LABEL;
        String borderColor = SHIFT_BORDER_COLOR;
        String backgroundColor = SHIFT_BACKGROUND_COLOR;

        if (shiftWrapper.isDayOff) {
            label = SHIFT_DAY_OFF_LABEL;
            borderColor = SHIFT_DAY_OFF_BORDER_COLOR;
            backgroundColor = SHIFT_DAY_OFF_BACKGROUND_COLOR;
        }

        datasets.add(new ChartDatasetWrapper(label,contactName,shift.Id,axisData,borderColor,backgroundColor,DEFAULT_BORDER_WIDTH,DEFAULT_FILL));
    }

    private static void processAgentWork(List<ChartDatasetWrapper> datasets, AgentWork agentWork, String contactName) {
        String workItemType = agentWork.WorkItem.getSObjectType().getDescribe().getName();
        String label = '';
        String borderColor = '';
        String backgroundColor = '';

        switch on workItemType {
            when 'Case' {
                label = CASE_LABEL;
                borderColor = CASE_BORDER_COLOR;
                backgroundColor = CASE_BACKGROUND_COLOR;
            }
            when 'VoiceCall' {
                label = CALL_LABEL;
                borderColor = CALL_BORDER_COLOR;
                backgroundColor = CALL_BACKGROUND_COLOR;
            }
            when 'MessagingSession' {
                label = CHAT_LABEL;
                borderColor = CHAT_BORDER_COLOR;
                backgroundColor = CHAT_BACKGROUND_COLOR;
            }
            when else {
                label = DEFAULT_LABEL;
                borderColor = CALL_BORDER_COLOR;
                backgroundColor = CHAT_BACKGROUND_COLOR;
            }
        }

        List<AxisDataWrapper> axisData = new List<AxisDataWrapper>();
        if (agentWork.AcceptDateTime != null) {
            axisData.add(new AxisDataWrapper(getMinutesFromMidnight(agentWork.AcceptDateTime), contactName));
        }
        if (agentWork.CloseDateTime != null) {
            axisData.add(new AxisDataWrapper(getMinutesFromMidnight(agentWork.CloseDateTime), contactName));
        }

        datasets.add(new ChartDatasetWrapper(label,contactName,agentWork.WorkItemId,axisData,borderColor,backgroundColor,DEFAULT_BORDER_WIDTH,DEFAULT_FILL));
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
}