public class KnowledgeArticleCalificationController {
    
    @AuraEnabled
    public static KnowledgeArticleWrapper retrieveVoteCount(String recordId){
        KnowledgeArticleWrapper result = new KnowledgeArticleWrapper();
        Integer votetUp = 0;
        Integer votetDown = 0;
        Knowledge__kav knowledgeArt = [SELECT Id, ArticleNumber, VersionNumber, PublishStatus FROM Knowledge__kav WHERE Id =:recordId LIMIT 1];
        List<Calification__c> calificacionList = [SELECT Id, Name, KnowledgeArticle__r.ArticleNumber, KnowledgeArticle__c, Vote__c, Calification__c, OtherReason__c, Reason__c, PersonCode__c FROM Calification__c WHERE KnowledgeArticle__r.ArticleNumber =: knowledgeArt.ArticleNumber];

        for(Calification__c c : calificacionList){
            if(c.Vote__c){
                votetUp++;
            } 
            else{
                votetDown++;
            }
        }

        result.voteUp = votetUp;
        result.voteDown = votetDown;
        result.articleVersion = knowledgeArt.VersionNumber;
        result.articleNumber = knowledgeArt.ArticleNumber;

        return result;
    }

    public class KnowledgeArticleWrapper{
        @AuraEnabled
        public Integer voteUp {get;set;}
        @AuraEnabled
        public Integer voteDown {get;set;}
        @AuraEnabled
        public Integer articleVersion {get;set;}
        @AuraEnabled
        public String articleNumber {get;set;}
    }
}