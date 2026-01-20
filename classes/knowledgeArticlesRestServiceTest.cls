@isTest
public class knowledgeArticlesRestServiceTest {

@TestSetup
    static void setup() {
        Knowledge__kav kav = Testfactory.createKnowledgeArticle('FAQ');
        Knowledge__kav kav2 = Testfactory.createKnowledgeArticle('FAQ');
        List<Knowledge__kav> article = [SELECT Id, KnowledgeArticleId FROM Knowledge__kav LIMIT 2];
        KbManagement.PublishingService.publishArticle(article[0].KnowledgeArticleId, true);
        KbManagement.PublishingService.publishArticle(article[1].KnowledgeArticleId, true);
    }

@isTest
    static void testDoPutNewArticle() {
        KnowledgeArticleVersion kaVersion = [SELECT Id, KnowledgeArticleId, PublishStatus FROM KnowledgeArticleVersion LIMIT 1];
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/KnowledgeArticlesService/';
        req.httpMethod = 'PUT';
        String body = '{"idArticle":"' + kaVersion.KnowledgeArticleId +'","personCode":"299238","vote":true,"reason":"Otro motivo", "otherReason":"Test Test"}';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;

        knowledgeArticlesRestService.DataInput data = new knowledgeArticlesRestService.DataInput();
        data.idArticle = kaVersion.KnowledgeArticleId;
        data.personCode = '299238';
        data.reason = 'Otro motivo';
        data.vote = true;
        data.otherReason = 'Test Test';

        knowledgeArticlesRestService.doPut();
        Test.stopTest();
        Calification__c calification = [SELECT Id, KnowledgeArticle__c, Reason__c, Vote__c, Account__r.PersonCode__c FROM Calification__c WHERE KnowledgeArticle__c = :kaVersion.Id];
        System.assertEquals(kaVersion.Id, calification.KnowledgeArticle__c);
    }

    @isTest
    static void testDoPutNewArticleReason() {
        KnowledgeArticleVersion kaVersion = [SELECT Id, KnowledgeArticleId, PublishStatus FROM KnowledgeArticleVersion LIMIT 1];
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/KnowledgeArticlesService/';
        req.httpMethod = 'PUT';
        String body = '{"idArticle":"' + kaVersion.KnowledgeArticleId +'","personCode":"299238","vote":true,"reason":"No encontré lo que buscaba", "otherReason":"Test Test"}';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;

        knowledgeArticlesRestService.DataInput data = new knowledgeArticlesRestService.DataInput();
        data.idArticle = kaVersion.KnowledgeArticleId;
        data.personCode = '299238';
        data.reason = 'Otro Motivo';
        data.vote = true;
        data.otherReason = 'Test Test';

        knowledgeArticlesRestService.doPut();
        Test.stopTest();
        Calification__c calification = [SELECT Id, KnowledgeArticle__c, Reason__c, Vote__c, Account__r.PersonCode__c FROM Calification__c WHERE KnowledgeArticle__c = :kaVersion.Id];
        System.assertEquals(kaVersion.Id, calification.KnowledgeArticle__c);
        
    }

    @isTest
    static void testDoPutNewArticleJSONError() {
        Knowledge__kav article = [SELECT Id, KnowledgeArticleId, Title, UrlName FROM Knowledge__kav LIMIT 1];
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/KnowledgeArticlesService/';
        req.httpMethod = 'PUT';
        String body = '{"idArticle":"' + article.Id +'","personCode":"299238","vote":true,reason":"Otro Motivo", "otherReason":"Test Test"}';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;

        knowledgeArticlesRestService.DataInput data = new knowledgeArticlesRestService.DataInput();
        data.idArticle = article.Id;
        data.personCode = '299238';
        data.reason = 'Otro Motivo';
        data.vote = true;
        data.otherReason = 'Test Test';

        knowledgeArticlesRestService.doPut();
        Test.stopTest();
        
    }

    @isTest
    static void testDoPutNewArticleInvalidId() {
        Knowledge__kav article = [SELECT Id, KnowledgeArticleId, Title, UrlName FROM Knowledge__kav LIMIT 1];
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/KnowledgeArticlesService/';
        req.httpMethod = 'PUT';
        String body = '{"idArticle":"","personCode":"299238","vote":true,"reason":"Otro Motivo", "otherReason":"Test Test"}';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;

        knowledgeArticlesRestService.DataInput data = new knowledgeArticlesRestService.DataInput();
        data.idArticle = '';
        data.personCode = '299238';
        data.reason = 'Otro Motivo';
        data.vote = true;
        data.otherReason = 'Test Test';

        knowledgeArticlesRestService.DataResult result =  knowledgeArticlesRestService.doPut();
        Test.stopTest();
        System.assertEquals(true, result.message.contains('ERROR: '));
    }

    @isTest
    static void testDoPutNewArticleIdNotFound() {
        Knowledge__kav article = [SELECT Id, KnowledgeArticleId, Title, UrlName FROM Knowledge__kav LIMIT 1];
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/KnowledgeArticlesService/';
        req.httpMethod = 'PUT';
        String body = '{"idArticle":"ka0WK0000024tHpYAY","personCode":"299238","vote":true,"reason":"Otro Motivo", "otherReason":"Test Test"}';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;

        knowledgeArticlesRestService.DataInput data = new knowledgeArticlesRestService.DataInput();
        data.idArticle = 'ka0WK0000024tHpYAY';
        data.personCode = '299238';
        data.reason = 'Otro Motivo';
        data.vote = true;
        data.otherReason = 'Test Test';

        knowledgeArticlesRestService.DataResult result =  knowledgeArticlesRestService.doPut();
        Test.stopTest();
        System.assertEquals(true, result.message.contains('ERROR: '));
    }

    
@isTest
    static void testDoGetMethodInvalidArticleType(){
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/KnowledgeArticlesService/';
        req.params.put('articleType', 'FAQ__kav');
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;

        test.startTest();
        knowledgeArticlesRestService.ArticleInformation doGet = new knowledgeArticlesRestService.ArticleInformation();
        doGet = knowledgeArticlesRestService.doGet();
        test.stopTest();
        System.assertEquals('No articles found for articleType: FAQ__kav.', doGet.message);
    }

    @isTest
    static void testDoGetMethodArticleType(){
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/KnowledgeArticlesService/';
        req.params.put('articleType', 'FAQ');
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;

        List<Knowledge__kav> article = [SELECT Id, KnowledgeArticleId FROM Knowledge__kav LIMIT 2];
        Calification__c calificacion = new Calification__c();
        calificacion.KnowledgeArticle__c = article[0].Id;
        calificacion.PersonCode__c = '123';
        calificacion.Vote__c = true;
        insert calificacion;

        Calification__c calificacion2 = new Calification__c();
        calificacion2.KnowledgeArticle__c = article[1].Id;
        calificacion2.PersonCode__c = '123';
        calificacion2.Vote__c = true;
        insert calificacion2;


        Calification__c calificacion3 = new Calification__c();
        calificacion3.KnowledgeArticle__c = article[1].Id;
        calificacion3.PersonCode__c = '123';
        calificacion3.Vote__c = false;
        insert calificacion3;

        test.startTest();
        knowledgeArticlesRestService.ArticleInformation doGet = new knowledgeArticlesRestService.ArticleInformation();
        doGet = knowledgeArticlesRestService.doGet();
        test.stopTest();
        System.assertEquals('2 Articles found.', doGet.message); 
    }

    @isTest
    static void testDoGetMethodNullArticleType(){
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/KnowledgeArticlesService/';
        req.params.put('articleType', '');
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;

        test.startTest();
        knowledgeArticlesRestService.ArticleInformation doGet = new knowledgeArticlesRestService.ArticleInformation();
        doGet = knowledgeArticlesRestService.doGet();
        test.stopTest();
        System.assertEquals('Invalid articleType', doGet.message);    
    }
}