public class AccountRemoteSiteManager {

    public static Map<String, Object> getAccount(String documentNumber,String documentType){

        Map<String, String> parametersMap = new Map<String, String>();
        Map<String, Object> parsedResponse = new Map<String, Object>();

        try{

            if(documentType=='99'){
                parametersMap.put('phoneNumber',documentNumber);
            }else{
                parametersMap.put('documentNumber',documentNumber);
                parametersMap.put('documentType',documentType);
            }

            HttpResponse res = AccountRemoteSiteConection.getAccountFromBankitti(parametersMap);
            System.debug(res);

            if(res!=null){

                String jsonString = res.getBody();
                System.debug('/////JSON DEBUG////');
                System.debug(jsonString);
                parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(jsonString);

                if (parsedResponse != null) {
                    parsedResponse.put('code', res.getStatusCode());
                }
            }

        } catch (Exception e){
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'AccountRemoteSiteManager', 'getAccount');
            return null;
        }

               
        return parsedResponse;        
    }

    public static Map<String, Object> getAccountByPersonCode(String personCode){

        Map<String, String> parametersMap = new Map<String, String>();
        Map<String, Object> parsedResponse = new Map<String, Object>();

        try{

            parametersMap.put('personCode',personCode);

            HttpResponse res = AccountRemoteSiteConection.getAccountFromBankitti(parametersMap);
            System.debug(res);

            if(res!=null){

                String jsonString = res.getBody();
                System.debug('/////JSON DEBUG////');
                System.debug(jsonString);
                parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(jsonString);

                if (parsedResponse != null) {
                    parsedResponse.put('code', res.getStatusCode());
                }
            }

        } catch (Exception e){
            GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'AccountRemoteSiteManager', 'getAccount');
            return null;
        }

               
        return parsedResponse;        
    }
}