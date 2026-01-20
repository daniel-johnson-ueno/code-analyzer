@isTest
public class KnowledgeArticleCalificationTest {

    @TestSetup static void setup() {
        Knowledge__kav kav = Testfactory.createKnowledgeArticle('FAQ');
    }

    @isTest
    static void testRetrieveVoteUpCount(){
        
        Knowledge__kav article = [SELECT Id, KnowledgeArticleId FROM Knowledge__kav LIMIT 1];
        Calification__c calificacion = new Calification__c();
        calificacion.KnowledgeArticle__c = article.Id;
        calificacion.PersonCode__c = '123';
        calificacion.Vote__c = true;
        insert calificacion;
        
        Test.startTest();
        KnowledgeArticleCalificationController.KnowledgeArticleWrapper result = KnowledgeArticleCalificationController.retrieveVoteCount(article.Id);
        Test.stopTest();
        System.assertEquals(1, result.voteUp, 'voteUp should be 1');
        System.assertEquals(0, result.voteDown, 'voteDown should be 0');
        
    }

    @isTest
    static void testRetrieveVoteDownCount(){
        
        Knowledge__kav article = [SELECT Id, KnowledgeArticleId FROM Knowledge__kav LIMIT 1];
        Calification__c calificacion = new Calification__c();
        calificacion.KnowledgeArticle__c = article.Id;
        calificacion.PersonCode__c = '123';
        calificacion.Vote__c = false;
        insert calificacion;
        
        Test.startTest();
        KnowledgeArticleCalificationController.KnowledgeArticleWrapper result = KnowledgeArticleCalificationController.retrieveVoteCount(article.Id);
        Test.stopTest();
        System.assertEquals(0, result.voteUp, 'voteUp should be 0');
        System.assertEquals(1, result.voteDown, 'voteDown should be 1');
        
    }
}