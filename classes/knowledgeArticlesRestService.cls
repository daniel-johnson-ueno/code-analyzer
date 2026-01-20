@RestResource(urlMapping='/KnowledgeArticlesService/*')
global class knowledgeArticlesRestService {

    @HttpPut
    global static DataResult doPut(){
        RestRequest req = RestContext.request;
        RestResponse res = Restcontext.response;
        String body = req.requestBody.toString();
        String knowledgeRecordId;
        dataInput data;
        try{
            data = (dataInput)JSON.deserialize(body, dataInput.class);
        }catch (Exception e){
            return setResult('ERROR: ' + e.getMessage(), '');
        }

        if(data.idArticle == null || data.idArticle == '' ){
            return setResult('ERROR: Invalid article Id', data.idArticle);
        } else {
            try{
                Map<String,String> mapLabelValue = getApiAndLabelValues('Calification__c', 'Reason__c');
                List<KnowledgeArticleVersion> knowledgeArticleVersion = [SELECT Id, KnowledgeArticleId FROM KnowledgeArticleVersion WHERE KnowledgeArticleId = :data.idArticle AND PublishStatus = 'Online' LIMIT 1];
                if(knowledgeArticleVersion.isEmpty()){
                    return setResult('ERROR: Article not found', data.idArticle);
                } else {
                    knowledgeRecordId = knowledgeArticleVersion[0].Id;
                }

                Calification__c calification = new Calification__c();

                if(data.personCode != null && data.personCode != ''){
                    Integer personCodeInt = Integer.valueOf(data.personCode);
                    List<Account> relatedPerson = [SELECT Id from Account WHERE PersonCode__c = :personCodeInt LIMIT 1];
                    if(!relatedPerson.isEmpty()){
                        calification.Account__c = relatedPerson[0].id;
                    }
                }

                calification.KnowledgeArticle__c = knowledgeRecordId;
                calification.PersonCode__c = data.personCode;
                if(data.reason != '' && data.reason != null){
                    if(mapLabelValue.containsKey(data.reason)){
                        calification.Reason__c = mapLabelValue.get(data.reason);
                    } else {
                        return setResult('ERROR: Invalid value for the field Reason', data.reason);
                    }
                }
                
                calification.Vote__c = data.vote;
                if(data.vote){
                    calification.Reason__c = '';
                    calification.OtherReason__c = '';
                }

                if(data.reason == 'Otro Motivo'){
                    calification.OtherReason__c = data.otherReason;
                } else {
                    calification.OtherReason__c = '';
                }
                
                insert calification;
                return setResult('Calification created successfully' , data.idArticle);
            } catch (Exception e){
                return setResult('ERROR: ' + e.getMessage(), data.idArticle);
            }
        }
    }

    public static DataResult setResult(String message, String articleId){
        DataResult result = new DataResult();
        result.message = message;
        result.articleId = articleId;
        return result;
    }

    public static Map<String, String> getApiAndLabelValues(String objectApiName, String fieldApiName) {
        Map<String, String> picklistValues = new Map<String, String>();
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap();
        Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldApiName).getDescribe();
        system.debug(fieldDescribe.getType());
        if (fieldDescribe.getType() == Schema.DisplayType.Picklist) {
            List<Schema.PicklistEntry> picklistEntries = fieldDescribe.getPicklistValues();
            for (Schema.PicklistEntry entry : picklistEntries) {
                picklistValues.put(entry.getLabel(),entry.getValue());
            }
        }
        return picklistValues;
    }

    @HttpGet
    global static ArticleInformation doGet(){
        RestRequest req = RestContext.request;
        RestResponse res = Restcontext.response;
        String articleType = RestContext.request.params.get('articleType');
        ArticleInformation result = new articleInformation();
        List<ArticleInfo> resultList = new List<ArticleInfo>();
        Set<Id> kavsId = new Set<Id>();
        Set<String> idResults = new Set<String>();
        Map<String,KnowledgeArticleVersion> idArticleVersion = new Map<String,KnowledgeArticleVersion>();
        Map<String,String> kavCategoryGroup = new Map<String,String>();
        Map<String,String> kavCategoryGroupNames = new Map<String,String>();
        Map<String,String> kavCategoryGroupIds = new Map<String,String>();
        try{
            if(articleType == '' || articleType == null){
                result.message = 'Invalid articleType';
                result.articlesType = articleType;
                return result;
            } else {
                //Obetener articulos segun RecordType
                List<Knowledge__kav> kavList = [SELECT Id FROM Knowledge__kav WHERE RecordType.DeveloperName =:articleType];
                if(kavList.isEmpty()){
                    result.message = 'No articles found for articleType: ' + articleType + '.';
                    result.articlesType = articleType;
                    return result;
                } else {
                    for(Knowledge__kav kav : kavList){
                        kavsId.add(kav.id);
                    }
                }

                //Obtener categoria por Articulos.
                for(Knowledge__DataCategorySelection kavCate : [SELECT ParentId, DataCategoryGroupName, DataCategoryName FROM Knowledge__DataCategorySelection WHERE ParentId =:kavsId]){
                    kavCategoryGroup.put(kavCate.ParentId,kavCate.DataCategoryGroupName + '~' + kavCate.DataCategoryName);
                }

                //Obtener Nombre categoria.
                for(Data_Category_Label__mdt dcLabels : [SELECT Api_Name__c, Label_Name__c FROM Data_Category_Label__mdt]){
                    kavCategoryGroupNames.put(dcLabels.Api_Name__c, dcLabels.Label_Name__c);
                }

                //Obtener informacion del articulo.
                List<KnowledgeArticleVersion> kList = [SELECT Id, KnowledgeArticleId, ArticleNumber, lastPublishedDate, Summary, title, UrlName, ArticleTotalViewCount FROM KnowledgeArticleVersion WHERE Id IN :kavsId AND PublishStatus = 'Online'];

                //Map para identificar las versiones + Info.
                for(KnowledgeArticleVersion kl: kList){
                    idArticleVersion.put(kl.KnowledgeArticleId,kl);
                    kavCategoryGroupIds.put(kl.KnowledgeArticleId,kl.id);
                }
                Set<String> artNum = new Set<String>();
                for(KnowledgeArticle kav : [SELECT Id, ArticleNumber FROM KnowledgeArticle WHERE Id IN :idArticleVersion.keySet() AND LastPublishedDate <> null]){
                    idResults.add(kav.Id);
                    artNum.add(kav.ArticleNumber);
                }

                List<ArticleInfo> articleInfoList = new List<ArticleInfo>();
                Map<String,voteWrapper> mapCalification = getCalification(artNum);

                for(KnowledgeArticle a : [SELECT Id, ArticleNumber, LastPublishedDate, TotalViewCount FROM KnowledgeArticle WHERE Id IN :idResults]){
                    ArticleInfo info = new ArticleInfo();
                    String category;
                    categoryGroups cg = new categoryGroups();
                    voteWrapper vw = new voteWrapper();
                    info.Id = a.Id;
                    info.articleNumber = a.ArticleNumber;
                    info.title = idArticleVersion.get(a.Id).Title;
                    info.UrlName = idArticleVersion.get(a.Id).UrlName;
                    info.url = '/services/data/v60.0/support/knowledgeArticles/' + a.Id;
                    info.LastPublishedDate = a.LastPublishedDate;
                    info.summary = idArticleVersion.get(a.Id).Summary;
                    if(kavCategoryGroupIds.containsKey(a.Id)){
                        if(kavCategoryGroup.containsKey(kavCategoryGroupIds.get(a.Id))){
                            category = kavCategoryGroup.get(kavCategoryGroupIds.get(a.Id));
                            cg.DataCategoryGroupName = category.substringBefore('~');
                            if(kavCategoryGroupNames.containsKey(category.substringAfter('~'))){
                                cg.DataCategoryName = kavCategoryGroupNames.get(category.substringAfter('~'));
                            } else {
                                cg.DataCategoryName = category.substringAfter('~');
                            }
                        }
                    }
                    info.categoryGroups = cg;
                    info.viewCount = a.TotalViewCount;
                    if(mapCalification.containsKey(a.ArticleNumber)){
                        vw = mapCalification.get(a.ArticleNumber);
                        info.voteUp = vw.voteUp;
                        info.voteDown = vw.voteDown;
                    } else {
                        info.voteUp = 0;
                        info.voteDown = 0;
                    }
                    articleInfoList.add(info);
                }
                resultList.addAll(articleInfoList);
                
            }
            
        } catch (Exception e){
            result.message = e.getMessage();
            return result;
        }
        result.message = resultList.size() + ' Articles found.';
        result.articleInfo = resultList;
        result.articlesType = articleType;
       return result;
  }

    public static Map<String,voteWrapper> getCalification(Set<String> articleNumberSet){
        Map<String,voteWrapper> result = new Map<String,voteWrapper>();
        
        //Query para voto Positivo
        AggregateResult [] calificationsUp = [SELECT COUNT(Id) total, KnowledgeArticle__c FROM Calification__c WHERE Vote__c = true AND KnowledgeArticle__r.ArticleNumber IN:articleNumberSet GROUP BY KnowledgeArticle__c];
        Map <String,String> mapIdAndNumber = new Map<String,String>();
        Set<String> artNumber = new Set<String>();

        for(AggregateResult ar : calificationsUp){
            artNumber.add((String)ar.get('KnowledgeArticle__c'));
        }

        for(Knowledge__kav a : [SELECT Id, ArticleNumber FROM Knowledge__kav WHERE Id IN :artNumber]){
            mapIdAndNumber.put(a.Id,a.ArticleNumber);
        }
        
        for(AggregateResult ar : calificationsUp){
            voteWrapper vw = new voteWrapper();
            Integer voteUpInt = (Integer)ar.get('total');
            
            if(result.containsKey(mapIdAndNumber.get((String)ar.get('KnowledgeArticle__c')))){
                vw = result.get(mapIdAndNumber.get((String)ar.get('KnowledgeArticle__c')));
                vw.voteUp = vw.voteUp + voteUpInt;
            } else {
                vw.voteUp = voteUpInt;
            }
            result.put(mapIdAndNumber.get((String)ar.get('KnowledgeArticle__c')),vw);
        }


        //Query para voto Negativo
        AggregateResult [] calificationsDown = [SELECT COUNT(Id) total, KnowledgeArticle__c FROM Calification__c WHERE Vote__c = false AND KnowledgeArticle__r.ArticleNumber IN:articleNumberSet GROUP BY KnowledgeArticle__c];
        Set<String> artNumberDowm = new Set<String>();
        Map <String,String> mapIdAndNumberDown = new Map<String,String>();

        for(AggregateResult ar : calificationsDown){
            artNumberDowm.add((String)ar.get('KnowledgeArticle__c'));
        }

        for(Knowledge__kav a : [SELECT Id, ArticleNumber FROM Knowledge__kav WHERE Id IN :artNumberDowm]){
            mapIdAndNumberDown.put(a.Id,a.ArticleNumber);
        }

        for(AggregateResult ar : calificationsDown){
            Integer voteDownInt = (Integer)ar.get('total');
            voteWrapper vw = new voteWrapper();

            if(result.containsKey(mapIdAndNumberDown.get((String)ar.get('KnowledgeArticle__c')))){
                vw = result.get(mapIdAndNumberDown.get((String)ar.get('KnowledgeArticle__c')));
                vw.voteDown = vw.voteDown +  voteDownInt;
            } else {
                vw.voteDown = voteDownInt;
            }
            result.put(mapIdAndNumberDown.get((String)ar.get('KnowledgeArticle__c')),vw);
            
        }

        return result;
    }

    public class voteWrapper {
        public Integer voteUp;
        public Integer voteDown;
        public voteWrapper(){
            this.voteDown = 0;
            this.voteUp = 0;
        }
    }

    global class ArticleInformation {
        public String message;
        public String articlesType;
        public List<ArticleInfo> articleInfo;
    }
    global class ArticleInfo {
        public String id;
        public CategoryGroups categoryGroups;
        public Datetime lastPublishedDate;
        public String articleNumber;
        public String urlName;
        public String url;
        public String summary;
        public String title;
        public Integer viewCount;
        public Integer voteUp;
        public Integer voteDown;

    }

    public class categoryGroups {
        public String DataCategoryGroupName;
        public String DataCategoryName;
    }

    public class DataInput {
        public String idArticle;
        public String PersonCode;
        public Boolean vote;
        public String reason;
        public String otherReason;
    }

    global class DataResult {
        public String message;
        public String articleId;
    }
}