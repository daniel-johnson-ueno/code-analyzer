public with sharing class SurveyResultsController {

    public class SurveyResultWrapper {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String surveyName;
        @AuraEnabled
        public String generalProductName;
        @AuraEnabled
        public String generalCSAT;
        @AuraEnabled
        public String qrCSAT;
        @AuraEnabled
        public String qrProductName;
        @AuraEnabled
        public String duoCardCSAT;
        @AuraEnabled
        public String duoCardProductName;
        @AuraEnabled
        public String loansCSAT;
        @AuraEnabled
        public String loansProductName;
        @AuraEnabled
        public String transfersAndAccountsCSAT;
        @AuraEnabled
        public String transfersAndAccountsProductName;
        @AuraEnabled
        public String paymentOfServicesCSAT;
        @AuraEnabled
        public String paymentOfServicesProductName;
        @AuraEnabled
        public String paymentOfServicesIconClass;
        @AuraEnabled
        public String executiveCSAT;
        @AuraEnabled
        public String executiveCSATName;
        @AuraEnabled
        public String attentionRES;
        @AuraEnabled
        public String attentionRESName;
        @AuraEnabled
        public String attentionRESIconClass;
        @AuraEnabled
        public Datetime surveyDate;
        @AuraEnabled
        public String comments;
        @AuraEnabled
        public String generalIconClass;
        @AuraEnabled
        public String qrIconClass;
        @AuraEnabled
        public String duoCardIconClass;
        @AuraEnabled
        public String loansIconClass;
        @AuraEnabled
        public String transfersAndAccountsIconClass;
        @AuraEnabled
        public Boolean isProduct;
        @AuraEnabled
        public Boolean isAttentionAndExecutive;
    }


    @AuraEnabled
    public static List<SurveyResultWrapper> getSurveysResults(String accountId) {

        List<Survey__c> answeredSurveysList = new List<Survey__c>();

        try{
            List<AggregateResult> answeredSurveys = getSurveysId(accountId);

            if(answeredSurveys.size() > 0) {
                for(AggregateResult answer : answeredSurveys){
                    Survey__c surveyResult = getSurveyResult(accountId, String.valueOf(answer.get('RecordTypeId')) );
                    if(surveyResult != null)answeredSurveysList.add(surveyResult);

                }
            }

            List<SurveyResultWrapper> surveysResultsList = new List<SurveyResultWrapper>();


            for (Survey__c survey : answeredSurveysList) {
                SurveyResultWrapper surveyResults = new SurveyResultWrapper();
                surveyResults.id = survey.Id;
                surveyResults.surveyName = survey.Name;
                surveyResults.surveyDate = survey.CreatedDate;
                surveyResults.comments = survey.Pregunta_Abierta__c;
                surveyResults.isProduct = survey.Record_Type_Encuesta__c == 'Relacionamiento_de_producto';
                surveyResults.isAttentionAndExecutive = survey.Record_Type_Encuesta__c == 'Satisfaccion_y_resolucion_de_caso';

                assignSurveyResultsByType(survey, surveyResults);

                surveysResultsList.add(surveyResults);


            }

            return surveysResultsList;

        } catch (Exception e) {
            System.debug('catch ' + e + ' lineNumber: ' + e.getLineNumber());
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'SurveyResultsController', 'getSurveysResults');
            throw new AuraHandledException(e.getMessage());
        }

    }

    private static List<AggregateResult> getSurveysId(String accountId) {

        List<AggregateResult> lastThreeSurveysRecordType = [SELECT RecordTypeId, MAX(CreatedDate) maxDate FROM Survey__c
        WHERE Cuenta__c = :accountId GROUP BY RecordTypeId ORDER BY MAX(CreatedDate) DESC LIMIT 3];
        return lastThreeSurveysRecordType;
    }

    private static Survey__c getSurveyResult(String accountId, String recordTypeId) {
        List<String> lstFields = new List<String>(Schema.getGlobalDescribe().get('Survey__c').getDescribe().fields.getMap().keySet());

        String soql = 'SELECT ' + String.join(lstFields,',');
        soql += ' FROM Survey__c';
        soql += ' WHERE Cuenta__c =: accountId AND RecordTypeId =: recordTypeId';
        soql += ' ORDER BY CreatedDate DESC';
        soql += ' LIMIT 1';

        List<Survey__c> surveyResult = Database.query(soql);

        if(surveyResult.size() > 0) {
            return surveyResult[0];
        }

        return null;
    }

    private static void assignSurveyResultsByType(Survey__c survey, SurveyResultWrapper surveyResults) {
        switch on survey.Record_Type_Encuesta__c {
            when 'Relacionamiento_de_marca' {
                assignGeneralCSAT(survey.CSAT_Cliente__c, 'CSAT Cliente', surveyResults);
            }
            when 'Relacionamiento_de_producto' {
                assignProductSpecificCSAT(survey, surveyResults);
            }
            when 'Satisfaccion_y_resolucion_de_caso' {
                assignExecutiveAndAttention(survey, surveyResults);
            }
            when 'Onboarding_Personas' {
                assignGeneralCSAT(survey.CSAT_Onboarding_Personas__c, 'Onboarding Personas', surveyResults);
            }
            when 'Onboarding_Empresas' {
                assignGeneralCSAT(survey.CSAT_Onboarding_Empresas__c, 'Onboarding Empresas', surveyResults);
            }
        }
    }

    private static void assignGeneralCSAT(String csatValue, String productName, SurveyResultWrapper surveyResults) {
        surveyResults.generalCSAT = csatValue;
        surveyResults.generalProductName = productName;
        surveyResults.generalIconClass = assignedClass(csatValue);
    }

    private static void assignProductSpecificCSAT(Survey__c survey, SurveyResultWrapper surveyResults) {
        if (survey.CSAT_Duo_Card__c != null) {
            surveyResults.duoCardCSAT = survey.CSAT_Duo_Card__c;
            surveyResults.duoCardProductName = 'CSAT Duo Card';
            surveyResults.duoCardIconClass = assignedClass(survey.CSAT_Duo_Card__c);
        }
        if (survey.CSAT_Prestamos__c != null) {
            surveyResults.loansCSAT = survey.CSAT_Prestamos__c;
            surveyResults.loansProductName = 'CSAT Prestamos';
            surveyResults.loansIconClass = assignedClass(survey.CSAT_Prestamos__c);
        }
        if (survey.CSAT_QR__c != null) {
            surveyResults.qrCSAT = survey.CSAT_QR__c;
            surveyResults.qrProductName = 'CSAT pago QR';
            surveyResults.qrIconClass = assignedClass(survey.CSAT_QR__c);
        }
        if (survey.CSAT_Transferencias_y_Cuentas__c != null) {
            surveyResults.transfersAndAccountsCSAT = survey.CSAT_Transferencias_y_Cuentas__c;
            surveyResults.transfersAndAccountsProductName = 'CSAT Transf. y Cuentas';
            surveyResults.transfersAndAccountsIconClass = assignedClass(survey.CSAT_Transferencias_y_Cuentas__c);
        }
        if (survey.CSAT_Pago_de_servicios__c != null) {
            surveyResults.paymentOfServicesCSAT = survey.CSAT_Pago_de_servicios__c;
            surveyResults.paymentOfServicesProductName = 'CSAT Pago de servicios';
            surveyResults.paymentOfServicesIconClass = assignedClass(survey.CSAT_Pago_de_servicios__c);
        }
    }

    private static void assignExecutiveAndAttention(Survey__c survey, SurveyResultWrapper surveyResults) {
        surveyResults.executiveCSAT = survey.CSAT_Ejecutivo__c;
        surveyResults.attentionRES = survey.RES_de_atencion__c;
        surveyResults.executiveCSATName = 'CSAT Ejecutivo';
        surveyResults.attentionRESName = 'RES Atención';
        surveyResults.generalIconClass = assignedClass(survey.CSAT_Ejecutivo__c);
        surveyResults.attentionRESIconClass = assignedClass(survey.RES_de_atencion__c);
    }

    private static  String assignedClass(String value) {

        List<String> parts = value.split(' ');
        String selectedValue = value;
        if(parts[0].isNumeric()) {
            selectedValue = parts[0];
        }

        if(selectedValue == '1' || selectedValue == '2' || selectedValue == 'Muy difícil' || selectedValue == 'Difícil' || selectedValue == 'No') {
            return 'red';
        } else if (selectedValue == '3' || selectedValue == 'Ni fácil ni difícil' ) {
            return 'yellow';
        } else if (selectedValue == '4' || selectedValue == '5' || selectedValue == 'Fácil' || selectedValue == 'Muy fácil' || selectedValue == 'Sí') {
            return 'green';
        }

        return '';
    }
}