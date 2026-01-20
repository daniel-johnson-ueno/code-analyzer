@IsTest
private class SurveyResultsControllerTest {

    @TestSetup
    private static void setup (){
        Account person = TestFactory.createPersonAccount();
        Survey__c relacionamientoDeMarca = TestFactory.createSurvey(person.Id, 'Relacionamiento_de_marca');
        Survey__c relacionamientoDeProducto = TestFactory.createSurvey(person.Id, 'Relacionamiento_de_producto');
        Survey__c satisfaccionYResolucionDeCaso = TestFactory.createSurvey(person.Id, 'Satisfaccion_y_resolucion_de_caso');

    }

    @IsTest
    private static void getSurveyResultsTest(){

        Account person = [SELECT Id FROM Account LIMIT 1];

        List<SurveyResultsController.SurveyResultWrapper> surveyResults = SurveyResultsController.getSurveysResults(person.Id);

        System.assertEquals(3, surveyResults.size());
    }
}