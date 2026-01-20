public class MappingHelper {

	public class Wrapper{
		public Boolean success;
		public String message;
		public String code;
		public String accountId;
		public String field_error;
	}

	public class AccountWrapper{
		public Account currentaccount;
		public String message;
        public AccountWrapper(){}
        public AccountWrapper(Account currentaccount,String message){
            this.currentaccount = currentaccount;
            this.message = message;
        }
	}

	public class AccountCompanyWrapper{
		public Account currentAccount;
		public List<Account> personList;
		public List<Vinculo_Persona_Empresa__c> personCompanyLinkList;
		public List<Informacion_Financiera__c> financialInfoList;
		public String message;
        public AccountCompanyWrapper(){}
        public AccountCompanyWrapper(Account currentAccount, List<Account> personList, List<Vinculo_Persona_Empresa__c> personCompanyLinkList, String message){//List<Account> listPerson
            this.currentAccount = currentAccount;
			this.personCompanyLinkList = personCompanyLinkList;
            this.personList = personList;
            this.message = message;
        }
	}

	public class stepsWrapper{
		public String name;
		public String status;
		public String updatedAt;
	}

	public static Wrapper getAccountFromBankitti(String documentId, String documentType) {
		try {
			Map<String, Object> accountMap = AccountRemoteSiteManager.getAccount(documentId, documentType);
            system.debug('accountMap: ' + JSON.serialize(accountMap, true));
			if(accountMap.get('code') != null && accountMap.get('code') != 200) {
				return getAccountFromSalesforce(documentId, documentType, accountMap);
			}
			return processAccountMap(accountMap);

		} catch (Exception e) {

			GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'MappingHelper', 'getAccountFromBankitti');

			Wrapper wrapper = new Wrapper();
			wrapper.success = false;
			wrapper.message = 'Error al obtener la cuenta: ' + e.getMessage() + ' line:' + e.getLineNumber();
			return wrapper;
		}
	}

	public static Wrapper getAccountFromBankittiByPersonCode(String personCode) {

		try {
			Map<String, Object> accountMap = AccountRemoteSiteManager.getAccountByPersonCode(personCode);
			System.debug(accountMap);
			return processAccountMap(accountMap);

		} catch (Exception e) {

			GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'MappingHelper', 'getAccountFromBankittiByPersonCode');

			Wrapper wrapper = new Wrapper();
			wrapper.success = false;
			wrapper.message = 'Error al obtener la cuenta: ' + e.getMessage();
			return wrapper;
		}
	}

	public static Wrapper getAccountFromSalesforce(String documentNumber, String documentType, Map<String, Object> apiResponse) { //TODO: test
		
		try {
			List<Account> accounts = new List<Account>();
			if(documentType != '99'){
				accounts = AccountDAO.getAccountByTypeAndDocumentNumber(documentNumber, documentType);
			} else {
				accounts = AccountDAO.getAccountByPhone(documentNumber);
			}
			System.debug('getAccountFromSalesforce - accounts: ' + accounts);
			Wrapper wrapperResponse = accounts.isEmpty() ? createErrorWrapper('Error en el servicio: ' + apiResponse.get('message') + ' ' + apiResponse.get('code'), String.valueOf(apiResponse.get('code'))) : createSuccessWrapper(accounts[0].Id);
			System.debug('getAccountFromSalesforce - wrapperResponse: ' + wrapperResponse);
			return wrapperResponse;

		} catch (Exception e) {

			GenerateLogEvent.generateErrorLogEvent(e, UserInfo.getUserId(), 'MappingHelper', 'getAccountFromSalesforce');

			Wrapper wrapper = new Wrapper();
			wrapper.success = false;
			wrapper.message = 'Error al obtener la cuenta: ' + e.getMessage();
			return wrapper;
		}
	}
	
	private static Wrapper processAccountMap(Map<String, Object> accountMap) {

		Wrapper wrapper = new Wrapper();
		if (isErrorResponse(accountMap)) {
			wrapper.success = false;
			wrapper.message = 'Error en el servicio: ' + accountMap.get('message') + ' ' + accountMap.get('code');
			wrapper.code= String.valueOf(accountMap.get('code'));
			return wrapper;
		}
		
		if ((Boolean) accountMap.get('isPerson')) {
			wrapper = processPersonAccount(accountMap);
		} else {
			wrapper = processCompanyAccount(accountMap);
		}
		
		return wrapper;
	}
	
	private static Boolean isErrorResponse(Map<String, Object> accountMap) {
		return (Integer) accountMap.get('code') == 400 || (Integer) accountMap.get('code') == 404 || (Integer) accountMap.get('code') == 500;
	}
	
	private static Wrapper processPersonAccount(Map<String, Object> accountMap) {

		try {

			AccountWrapper result = mapAccountFields(accountMap, true);
			List<RecordType> recordTypes = [SELECT Id FROM RecordType WHERE DeveloperName = 'PersonAccount' LIMIT 1];
			String recordTypeId = recordTypes.isEmpty() ? null : recordTypes[0].Id;

            if(result.message=='601'){
                return createErrorWrapper('error en el mapeo de persona','601');
            }else{
                 persistPersonAccount(result.currentaccount, recordTypeId);
				 return createSuccessWrapper(result.currentaccount.Id);
            }
			
		} catch (Exception e) {
			System.debug('Line: ' + e.getLineNumber() + ' Ex: ' + e);
			return createErrorWrapper('Error al insertar la cuenta de persona: ' + e.getMessage(),'600');
		}
	}
	
	private static Wrapper processCompanyAccount(Map<String, Object> accountMap) {

		try {
			AccountCompanyWrapper result = mapCompanyAccountFields(accountMap);
			List<RecordType> recordTypes = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'IndustriesBusiness' LIMIT 1];
			String recordTypeId =  recordTypes.isEmpty() ? null : recordTypes[0].Id;

            if(result.message=='601'){
                return createErrorWrapper('error en el mapeo de empresa','601');
            }
            else{
                persistCompanyAccount(result.currentAccount, recordTypeId, result.personList, result.personCompanyLinkList, result.financialInfoList);
                return createSuccessWrapper(result.currentAccount.Id);
            }
		} catch (Exception e) {
			return createErrorWrapper('Error al insertar la cuenta de empresa: ' + e.getMessage(),'600');
		}
	}

	private static void persistPersonAccount(Account account, String recordTypeId) {

		account.RecordTypeId = recordTypeId;
		if(account.Type_and_Document_Number__c != null && AccountDAO.getAccountByTypeAndDocumentNumber(account.Type_and_Document_Number__c).size() > 0){
			upsert account Type_and_Document_Number__c;
		} else if(account.PersonEmail != null && account.Phone != null){
			List<Account> retrievedAccounts = AccountDAO.getAccountByTemporaryKey(account.PersonEmail, account.Phone);
			if(retrievedAccounts.size() > 0) {
				account.Id = retrievedAccounts[0].Id;
				update account;
			}else {
				insert account;
			}
		} else {
			insert account;
		}
	}


    private static void persistCompanyAccount(Account account, String recordTypeId, List<Account> personList,  List<Vinculo_Persona_Empresa__c> personCompanyLinkList, List<Informacion_Financiera__c> companyFinancialInfo) { //recordType no esta siendo usado dentro de este metodo List<Account> personAccounts
		//If exist a Company Account, it will be updated
		upsert account Type_and_Document_Number__c;
        String accountId = account.Id;

		//Upsert Person Accounts and create a map using Type_and_Document_Number__c as key
		Map<String, Account> personAccountsByDocNumber = new Map<String, Account>();
		Set<String> personAccountIds = new Set<String> ();

		if(personList.size() > 0){
			upsert personList Type_and_Document_Number__c;
		}

		for(Account person : personList){
			personAccountsByDocNumber.put(person.Type_and_Document_Number__c, person);
			personAccountIds.add(person.Id);
		}

		List<Account> persons = [SELECT Id, PersonContactId, Type_and_Document_Number__c FROM Account WHERE Id IN : personAccountIds];
		Map<Id,Account> personsById = new Map<Id,Account>(persons);

		//Find existing Vinculo_Persona_Empresa__c records related to the Account and delete them
		List<Vinculo_Persona_Empresa__c> existingPersonCompanyLinks = AccountDAO.getPersonCompanyLinks(accountId);
		if(existingPersonCompanyLinks.size() > 0){
			Database.delete(existingPersonCompanyLinks);
		}

		//Add the AccountId(Company) and AccountId(Person) to new Vinculo_Persona_Empresa__c records and insert them
		for(Vinculo_Persona_Empresa__c vinculo : personCompanyLinkList){
			vinculo.Cuenta__c = accountId;
			vinculo.Persona__c = personAccountsByDocNumber.get(vinculo.Type_and_Document_Number__c).Id;
		}

		if(personCompanyLinkList.size() > 0){
			Database.insert(personCompanyLinkList);
		}

		List<AccountContactRelation> relationsToInsert = new List<AccountContactRelation>();
		List<AccountContactRelation> relationBetweenContactAndAccount = [SELECT Id, ContactId, Contact.AccountId, AccountId FROM AccountContactRelation WHERE AccountId =: accountId and Contact.RecordType.Name != 'Business'];

		if(relationBetweenContactAndAccount.size() > 0) {
			Database.delete(relationBetweenContactAndAccount);
		}

		if(personsById.size() > 0){

			for(Id personId : personsById.keySet()){

				AccountContactRelation acr = new AccountContactRelation(
						AccountId = accountId,
						ContactId = personsById.get(personId).PersonContactId
				);

				relationsToInsert.add(acr);

			}
		}

		if(relationsToInsert.size() > 0){
			Database.insert(relationsToInsert);
		}

		//If there is existing financial info this must be deleted then insert new company financial information
		List<Informacion_Financiera__c> existingCompanyFinancialInfo = AccountDAO.getCompanyFinancialInfo(accountId);
		if(existingCompanyFinancialInfo.size() > 0){
			Database.delete(existingCompanyFinancialInfo);
		}

		if(companyFinancialInfo.size() > 0){
			for(Informacion_Financiera__c financialInfo : companyFinancialInfo){
				financialInfo.Cuenta__c = accountId;
			}
			Database.insert(companyFinancialInfo);
		}
    }
	
	private static Wrapper createSuccessWrapper(String accountId) {
		Wrapper wrapper = new Wrapper();
		wrapper.success = true;
		wrapper.accountId = accountId;
		wrapper.code='200';
		wrapper.message = 'Cuenta insertada correctamente';
		return wrapper;
	}
	
	private static Wrapper createErrorWrapper(String message, String code) {
		Wrapper wrapper = new Wrapper();
		wrapper.success = false;
		wrapper.message = message;
		wrapper.code=code;
		return wrapper;
	}

	public static AccountWrapper mapAccountFields( Map<String, Object> accountMap, Boolean isPerson){
		String fieldError;
		AccountWrapper accWrapper = new AccountWrapper();

		try{

			List<Int_RequestMapping_PersonAccount__mdt> requestMappingPersonAcc = [SELECT DeveloperName, MasterLabel, Type__c, Value__c,level_json__c
																					FROM Int_RequestMapping_PersonAccount__mdt ];
			Account acc = new Account();

			if(accountMap.containsKey('documentNumber') && accountMap.containsKey('documentType') && accountMap.containsKey('completeName')){
				
				acc.put('Account_Name__c', accountMap.get('completeName'));
				
				for(Int_RequestMapping_PersonAccount__mdt requestMapping : requestMappingPersonAcc){

					if(isPerson && requestMapping.Value__c=='IsPerson__c'){
						acc.put('IsPerson__c',true );

					} else if(requestMapping.DeveloperName == 'images' && accountMap.containsKey('images') && accountMap.get('images')!=null){
						List<Object> images= (List<Object>) accountMap.get('images');
						String fileIcon = getImg('fileIcon');

						if(images.size()>0){
							Integer i =0;
							String list_image='';
							while (i<images.size()){
								list_image=list_image+'<p><a href="'+((Map<String, Object>) images[i]).get('url')+'" >'+fileIcon+' '+((Map<String, Object>) images[i]).get('description')+'</a></p>';
								i++;
							}

							acc.put(requestMapping.Value__c,list_image );
						}

					} else if(requestMapping.Type__c == 'Date' && accountMap.get(requestMapping.DeveloperName) != null){
						mapAccountDates(accountMap, requestMapping, acc, fieldError);
					} else if(requestMapping.DeveloperName=='documentType'){
						String documentType = String.valueOf(accountMap.get(requestMapping.DeveloperName));
						fieldError=requestMapping.Value__c+' con valor '+documentType;
						acc.put(requestMapping.Value__c, documentType);

					} else if(requestMapping.DeveloperName=='type_documentNumber'){
						fieldError=requestMapping.Value__c+' con valor '+accountMap.get('documentType')+'_'+accountMap.get('documentNumber');
						acc.put(requestMapping.Value__c, accountMap.get('documentType')+'_'+accountMap.get('documentNumber'));

					} else if(requestMapping.level_json__c == 'spouse' && accountMap.get('spouse')!= null ){
						String spouse_field =(requestMapping.DeveloperName).substringAfterLast('_');
						if(spouse_field=='documentNumber' ){
							String spouseValue = String.valueOf((String) ((Map<String, Object>) accountMap.get('spouse')).get(spouse_field));
							fieldError=requestMapping.Value__c+' con valor '+spouseValue;
							acc.put(requestMapping.Value__c, spouseValue);

						} else if(spouse_field=='documentType'){
							String spouseValue = String.valueOf((Integer) ((Map<String, Object>) accountMap.get('spouse')).get(spouse_field));
							fieldError=requestMapping.Value__c+' con valor '+spouseValue;
							acc.put(requestMapping.Value__c, spouseValue);

						} else{
							String spouseValue = (String) ((Map<String, Object>) accountMap.get('spouse')).get(spouse_field);
							fieldError=requestMapping.Value__c+' con valor '+spouseValue;
							acc.put(requestMapping.Value__c, spouseValue);
						}

					} else if(requestMapping.level_json__c  == 'Address'){
						acc = AddressMapper.mapAddressFields(requestMapping.Value__c, (List<Object>) accountMap.get('addresses'), acc);
						acc = AddressMapper.mapAddressFields(requestMapping.Value__c, (List<Object>) accountMap.get('addresses'), acc);

					} else if(requestMapping.level_json__c == 'accountManager' && accountMap.get('accountManager') != null){
						mapAccountManager(accountMap, requestMapping, acc);
					} else if(requestMapping.level_json__c == 'income' && accountMap.get('income')!= null ){
						String income_field =(requestMapping.DeveloperName).substringAfterLast('_');

						if(income_field=='value'){
							Decimal incomeValue = Decimal.valueOf((Integer) ((Map<String, Object>) accountMap.get('income')).get('value'));
							fieldError=requestMapping.Value__c+' con valor '+incomeValue;
							acc.put(requestMapping.Value__c, incomeValue);

						} else{
							String incomeValue = (String) ((Map<String, Object>) accountMap.get('income')).get(income_field);
							fieldError=requestMapping.Value__c+' con valor '+incomeValue;
							acc.put(requestMapping.Value__c, incomeValue);
						}

					} else if(requestMapping.level_json__c == 'gvUser' && accountMap.get('gvUser')!= null ){

						Map<String, Object> gvUser = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(accountMap.get('gvUser')));
						acc.put(String.valueOf(requestMapping.get('Value__c')), String.valueOf(gvUser.get(requestMapping.DeveloperName)));

						if(gvUser.containsKey('onboarding')) {
							Map<String, Object> onboarding = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(gvUser.get('onboarding')));
							if(onboarding.containsKey('status')) {
								String onboardingStatus = String.valueOf(onboarding.get('status'));
								for(String key : onboarding.keySet()) {
									if(key == 'steps') {
										List<Object> steps = (List<Object>) JSON.deserializeUntyped(JSON.serialize(onboarding.get(key)));
										mapAccountOnboardingStatus(steps, acc, onboardingStatus);

									}
								}
							}
						}


					} else if(requestMapping.DeveloperName=='employmentInformation' && accountMap.containsKey('employmentInformation')){
						List<Object> employmentInformation = (List<Object>) JSON.deserializeUntyped(JSON.serialize(accountMap.get('employmentInformation')));
						System.debug('employmentInformation');
						System.debug(employmentInformation);
						String companyNames = '';
						for(Object obj : employmentInformation) {
							Map<String, Object> employment = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(obj));

							if(employment.containsKey('current') && employment.get('current') == true) {
								if(companyNames == ''){
									if(employment.containsKey('current') && employment.get('current') == true) {
										companyNames = String.valueOf(employment.get('workplaceName'));
									}
								} else {
									companyNames = companyNames + ', ' + String.valueOf(employment.get('workplaceName'));
								}
							}
						}

						if(companyNames != '') {
							acc.put(requestMapping.Value__c, companyNames);
						}

					}else if(accountMap.get(requestMapping.DeveloperName)!=null) {
						fieldError=requestMapping.Value__c+' con valor '+accountMap.get(requestMapping.DeveloperName);

						if(requestMapping.Type__c== 'Number') {
							acc.put(requestMapping.Value__c, Integer.valueOf(accountMap.get(requestMapping.DeveloperName)));

						} else if(requestMapping.Value__c == 'PersonEmail'){
							if(isValidEmail(String.valueOf(accountMap.get(requestMapping.DeveloperName)))){
								acc.put(requestMapping.Value__c, accountMap.get(requestMapping.DeveloperName));
							}
						} else {
							acc.put(requestMapping.Value__c, accountMap.get(requestMapping.DeveloperName));
						}
					}
				}

			} else {
				Map<String, Object> gvUser = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(accountMap.get('gvUser')));
				acc.put('LastName', 'Onboarding Pendiente');
				Map<String, Object> email = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(gvUser.get('email')));
				Map<String, Object> phone = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(gvUser.get('phoneNumber')));
				System.debug(email);
				if(isValidEmail(String.valueOf(email.get('value')))){
					acc.put('PersonEmail', email.get('value'));
				}
				acc.put('Phone', phone.get('value'));
				acc.put('Onboarding_Status__c', 'email;phone');
			}

			accWrapper.currentaccount = acc;
			return accWrapper;

		} catch(Exception e){
			System.debug('Line: ' + e.getLineNumber() + ' ' + e + ' ' + fieldError + ' error en el mapeo');
            return new AccountWrapper(null,'601');
		}
	}

    private static String getImg(String fileName){
        StaticResource static_resource = [SELECT Id, SystemModStamp, Name
                                      FROM StaticResource
                                      WHERE Name = :fileName
                                      LIMIT 1];
        String url_file_ref = '/resource/'
                            + String.valueOf(((DateTime)static_resource.get('SystemModStamp')).getTime())
                            + '/'
                            + static_resource.get('Name');

        String imgTag = '<img src="'+url_file_ref+'" style="margin-bottom: 3px;">';
        return imgTag;
	}

	public static AccountCompanyWrapper mapCompanyAccountFields(Map<String, Object> companyMap ){

		String fieldError;
		AccountCompanyWrapper accWrapper = new AccountCompanyWrapper();
		Account accCompany = new Account();
		List<Account> personAccounts= new List<Account>();//antes era persons_account
		Map<String, Account> personAccountsByDocNumber = new Map<String, Account>();
		List<Vinculo_Persona_Empresa__c> personCompanyLink = new List <Vinculo_Persona_Empresa__c>();
		List<Informacion_Financiera__c> companyFinancialInfoList = new List<Informacion_Financiera__c>();
		System.debug('companyMap');
		try{
			List<Int_RequestMapping_Account__mdt> requestMappingAcc = [SELECT  DeveloperName, MasterLabel, Value__c, level_json__c, Type__c  FROM Int_RequestMapping_Account__mdt ];

			for(Int_RequestMapping_Account__mdt requestMapping : requestMappingAcc){

				if(requestMapping.Value__c == 'person'){

					List<Object> persons = (List<Object>) companyMap.get('persons');
					if(persons.size()>0){

						for(Object person: persons){

							Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(person));
							personCompanyLink.add(createVinculoPersonaEmpresa(jsonMap));

							if(jsonMap.containsKey('documentNumber') && !personAccountsByDocNumber.containsKey((String)jsonMap.get('documentNumber'))){//new
								AccountWrapper person_Company= mapAccountFields(jsonMap, true);
								personAccountsByDocNumber.put(String.valueOf(jsonMap.get('documentNumber')), person_Company.currentaccount);

							}

						}
						personAccounts.addAll(personAccountsByDocNumber.values());
					}
				}else if(requestMapping.Value__c == 'financialInfo'){

					List<Object> financialInfoList = (List<Object>) companyMap.get(requestMapping.Value__c);
					if(financialInfoList != null && financialInfoList.size() > 0){

						for(Object financialInfo : financialInfoList){
							Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(financialInfo));
							companyFinancialInfoList.add(createCompanyFinancialInfo(jsonMap));
						}

					}

				}else if(requestMapping.level_json__c == 'accountManager' && companyMap.get('accountManager') != null){
					mapAccountManager(companyMap, requestMapping, accCompany);
				}else if(requestMapping.Value__c == 'DocumentExpirationDate__c' && companyMap.containsKey(requestMapping.DeveloperName)){
					fieldError=requestMapping.Value__c+' con el valor '+companyMap.get(requestMapping.DeveloperName);
					accCompany.put(requestMapping.Value__c, Date.valueOf(String.valueOf(companyMap.get(requestMapping.DeveloperName))));

				}else if(requestMapping.Value__c == 'PartnersQty__c'&& companyMap.containsKey(requestMapping.DeveloperName)){
					fieldError=requestMapping.Value__c+' con el valor '+companyMap.get(requestMapping.DeveloperName);
					accCompany.put(requestMapping.Value__c, Decimal.valueOf(String.valueOf(companyMap.get(requestMapping.DeveloperName))));

				}else if(requestMapping.DeveloperName =='companyName'){
					fieldError=requestMapping.Value__c+' con el valor '+companyMap.get(requestMapping.DeveloperName);
					accCompany.put('Name', String.valueOf(companyMap.get(requestMapping.DeveloperName)));
					accCompany.put('Account_Name__c', String.valueOf(companyMap.get(requestMapping.DeveloperName)));
					accCompany.put(requestMapping.Value__c, String.valueOf(companyMap.get(requestMapping.DeveloperName)));

				}else if(requestMapping.Type__c == 'Date' && companyMap.get(requestMapping.DeveloperName) != null){
					mapAccountDates(companyMap, requestMapping, accCompany, fieldError);
				}else if(requestMapping.Type__c =='Number'){
					fieldError=requestMapping.Value__c+' con el valor '+companyMap.get(requestMapping.DeveloperName);
					accCompany.put(requestMapping.Value__c, Integer.valueOf(companyMap.get(requestMapping.DeveloperName)));

				}else if(requestMapping.Type__c =='Bolean'){
					fieldError=requestMapping.Value__c+' con el valor bolean'+companyMap.get(requestMapping.DeveloperName);
					accCompany.put(requestMapping.Value__c,companyMap.get(requestMapping.DeveloperName));

				}else if(requestMapping.DeveloperName=='type_documentNumber' ){
					fieldError=requestMapping.Value__c+' con valor '+companyMap.get('documentType')+'_'+companyMap.get('documentNumber');
					accCompany.put(requestMapping.Value__c, companyMap.get('documentType')+'_'+companyMap.get('documentNumber'));

				}else if(requestMapping.level_json__c  == 'Address'){
					accCompany = AddressMapper.mapAddressFields(requestMapping.Value__c, (List<Object>) companyMap.get('addresses'), acccompany);
					accCompany = AddressMapper.mapAddressFields(requestMapping.Value__c, (List<Object>) companyMap.get('addresses'), acccompany);

				}else if(companyMap.get(requestMapping.DeveloperName)!=null){
					fieldError=requestMapping.Value__c+' con el valor el '+companyMap.get(requestMapping.DeveloperName);
					accCompany.put(requestMapping.Value__c, String.valueOf(companyMap.get(requestMapping.DeveloperName)));

				}
			}

			accWrapper.personList=personAccounts;
			accWrapper.personCompanyLinkList = personCompanyLink;
			accWrapper.currentAccount=accCompany;
			accWrapper.financialInfoList = companyFinancialInfoList;

			return accWrapper;

		}catch(Exception e){
			System.debug('Line: ' + e.getLineNumber() + ' Exception: ' + e);
			System.debug('error en el mapeo de listado de personas');
            return new AccountCompanyWrapper(null,null, null,'601');

		}
	}

	//Method used to create Informacion_Financiera__c record
	private static Informacion_Financiera__c createCompanyFinancialInfo (Map<String, Object> financialInfo){

		Informacion_Financiera__c newFinancialInfo = new Informacion_Financiera__c();
		newFinancialInfo.Concepto__c = (String) financialInfo.get('concept');
		newFinancialInfo.Fecha_de_la_Informacion__c = Date.valueOf((String) financialInfo.get('informationDate')) ;
		newFinancialInfo.Moneda__c = (String) financialInfo.get('currency');
		newFinancialInfo.Monto__c = (Decimal) financialInfo.get('amount');

		return newFinancialInfo;

	}

	//Method used to create Vinculo_Persona_Empresa__c record
	private static Vinculo_Persona_Empresa__c createVinculoPersonaEmpresa (Map<String, Object> personInfo){

		Vinculo_Persona_Empresa__c newLink = new Vinculo_Persona_Empresa__c();
		newLink.Name = personInfo.containsKey('relationType') ? (String) personInfo.get('relationType') : 'RELACION NO ENCONTRADA';
		newLink.Type_and_Document_Number__c = String.valueOf((Integer)personInfo.get('documentType')) + '_' +  String.valueOf(personInfo.get('documentNumber'));
		newLink.Descripcion__c = personInfo.containsKey('profileDescription') ? (String) personInfo.get('profileDescription') : '';
		newLink.Fecha_de_Vencimiento__c =  personInfo.containsKey('expirationDate')? Date.valueOf((String) personInfo.get('expirationDate')) : null;

		return newLink;

	}

	private static void mapAccountDates(Map<String, Object> requestMap, SObject requestMapping, Account acc, String fieldError) {
		String accountDate = String.valueOf(requestMap.get(String.valueOf(requestMapping.get('DeveloperName'))));
		Date formatedDate = Date.valueOf(accountDate);
		fieldError = String.valueOf(requestMapping.get('Value__c')) + ' con valor ' + formatedDate;
		acc.put(String.valueOf(requestMapping.get('Value__c')), formatedDate);
	}

	private static void mapAccountOnboardingStatus (List<Object> steps,  Account acc, String onboardingStatus){

		String onboardingStepsStatus = '';
		if(onboardingStatus == 'SUCCESS' || onboardingStatus == 'MANUAL_SUCCESS'){
			onboardingStepsStatus += 'successfulOnboarding';
		} else if(onboardingStatus == 'OPERATOR_REVIEW' || onboardingStatus == 'MANUAL_REVIEW'){
			onboardingStepsStatus += 'onboardingReview';
		}

		for(Object step : steps){
			Map<String, Object> currentStep = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(step));
			if(currentStep.get('status') == 'SUCCESS'){
				onboardingStepsStatus += onboardingStepsStatus == '' ? currentStep.get('name').toString() : ';' + currentStep.get('name').toString();
			}
		}

		acc.put('Onboarding_Status__c', onboardingStepsStatus);
	}

	private static void mapAccountManager(Map<String, Object> requestMap, SObject requestMapping, Account acc){
		Map<String, Object> accountManager = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(requestMap.get('accountManager')));
	
		switch on String.valueOf(requestMapping.get('MasterLabel')) {
			when 'accountManagerEmail' {
	
				acc.put(String.valueOf(requestMapping.get('Value__c')), String.valueOf(accountManager.get('email')));
			}
			when 'accountManagerPhoneNumber' {
				acc.put(String.valueOf(requestMapping.get('Value__c')), String.valueOf(accountManager.get('phoneNumber')));
			}
			when 'accountManagerName' {
				acc.put(String.valueOf(requestMapping.get('Value__c')), String.valueOf(accountManager.get('name')));
			}
			when else {
				System.debug('invalid account manager field');
			}
		}
	}

	private static Boolean isValidEmail(String email) {
		// Expresión regular para validar el correo electrónico
		String emailPattern = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$';

		// Verificamos si el correo electrónico coincide con el patrón
		if (email != null && email != '') {
			Pattern pattern = Pattern.compile(emailPattern);
			Matcher matcher = pattern.matcher(email);
			return matcher.matches(); // Devuelve true si el correo coincide con el patrón
		}

		return false;
	}
	public static void setSegmentation(SegmentationService.SegmentationWrapper segmentation, String accountId){
		if (accountId!=null && segmentation!=null && segmentation.value!=''	) {
			Account acc = [SELECT Id FROM Account WHERE Id = :accountId LIMIT 1];
			acc.Segment__c = segmentation.value;
			update acc;				
		}
	}
}