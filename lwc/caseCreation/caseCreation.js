import { LightningElement, track, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RefreshEvent } from 'lightning/refresh';
import { IsConsoleNavigation, getFocusedTabInfo, closeTab, getTabInfo, openSubtab} from 'lightning/platformWorkspaceApi';
import { NavigationMixin } from 'lightning/navigation';
import getTipificadores from '@salesforce/apex/TipificadorController.getTipificadores';
import getCompanies from '@salesforce/apex/TipificadorController.getCompanies';
import getTipificadoresByType from '@salesforce/apex/TipificadorController.getTipificadoresByType';
import getRequiredFields from '@salesforce/apex/TipificadorController.getRequiredFields';
import updateCaseRequiredFields from '@salesforce/apex/TipificadorController.updateCaseRequiredFields';
import checkIfIsFirstAssign from '@salesforce/apex/TipificadorController.checkIfIsFirstAssign';
import getObjectType from '@salesforce/apex/TipificadorController.getObjectType';
import getAccountCompanyKey from '@salesforce/apex/TipificadorController.getAccountCompanyKey';
import createCase from '@salesforce/apex/TipificadorController.createCase';
import getPersonAccountContact from '@salesforce/apex/TipificadorController.getPersonAccountContact';
//import hasPermissionCreateCase from '@salesforce/customPermission/RestrictedCaseCreation';
import hasPermissionCreateCase from '@salesforce/customPermission/AllowCaseCreation';

const CASE_FIELDS = [
   'Case.Status',
   'Case.RecordTypeId',
   'Case.Type',
   'Case.Reason',
   'Case.Origin',
   'Case.ROTDerivation__c',
   'Case.Vazquez_Group_Company__c'
]

export default class Tipificador extends NavigationMixin(LightningElement){
   @track parentTabId;
   @track subTabId;  
   @track isLoading = false;
   @track tipoOptions = [];
   @track companiesOptions = [];
   @track tipoFilteredOptions = [];
   @track reasonOptions = [];
   @track reasonFilteredOptions = [];
   @track requiredFields = [];
   @api recordId;
   @track showRequiredFields = false;
   @track disabled = true;
   @track showTipificador = false;
   @track showTipificadorRot = false;
   @track showSecondTipificador = false;
   @track secondAssignment = false;
   @track isAccount = false;
   @track status;
   @track contact;
   @track showMessage = false;
   @track firstStep = false;
   @track shouldShowButton = false;
   @track searchCompany = false;
   @track companySelect;
   @track newCase = {
      AccountId: '',
      Subject: '',
      RecordTypeId: '',
      Description: '',
      Origin: '',
      Status:'',
      Type: '',
      ContactId: '',
      OwnerId: ''
  }
   objectType;
   showCreateCase = false;

    tipoValue = null;
    reasonValue = null;
    tipoSearchKey = '';
    reasonSearchKey = '';
    errorMessage = '';

    @wire(IsConsoleNavigation) isConsoleNavigation;


    @wire(getObjectType, { recordId: '$recordId' })
    wiredObjectType({ error, data}){
      if(data) {
         this.getObjectType = data;
         this.showCreateCase = this.getObjectType != 'Case' && this.getObjectType == 'Account'; 
      }else if(error) {
         console.error('Error al cargar el caso: ', error);
      }   
    } 

    @wire(getRecord, { recordId: '$recordId', fields: CASE_FIELDS})
    wiredCase({ error, data}){
      if(data) {
         this.showSecondTipificador = false;
         this.showTipificadorRot = false;
         const currentStatus = getFieldValue(data, 'Case.Status');
         const type = getFieldValue(data, 'Case.Type');
         const reason = getFieldValue(data, 'Case.Reason')
         const deriveRot = getFieldValue(data, 'Case.ROTDerivation__c');
         const accountCompany = getFieldValue(data, 'Case.Vazquez_Group_Company__c');
         this.isFirstAssign();
         setTimeout(() => {
         if((type == null || reason == null) && currentStatus == 'Asignado'){
            this.showSecondTipificador = true;
         }/*else if(deriveRot && currentStatus == 'Asignado' && this.secondAssignment){
            this.showTipificadorRot = true;
            this.showSecondTipificador = true;
         } */else if(currentStatus == 'Escalado' || (deriveRot && currentStatus == 'Asignado' && this.secondAssignment)){
            this.showTipificadorRot = true;
            this.showCreateCase = false;
            this.shouldShowButton = true;
         }   
         this.showTipificador = this.showSecondTipificador || this.showTipificadorRot;
         if(accountCompany == '' || accountCompany == null){
            this.searchCompany = true;
         }else{
            this.companySelect = accountCompany;
            this.getValuesTipificacion();
         }
         this.disabled = !['Asignado', 'Escalado', 'Derivado'].includes(currentStatus);
      }, "2000");
         if(!this.disabled ) {
            this.fetchRequiredFieldsOptions();
         }
      }else if(error) {
         console.error('Error al cargar el caso: ', error);
      }  
   
    } 

    connectedCallback() {
        this.loadMetadataCompaniesRecords();
        const companyName = '';
        if(this.companySelect != null){
         if(this.companySelect.startsWith("001")){
            companyName = getAccountCompanyName(this.companySelect);
         }else{
            companyName = this.companySelect;
         }
         this.loadMetadataRecords(companyName);
        }
         if(this.getObjectType != 'Case'){
            this.getAccountInformation();
        }
         
    }

    showToast(title,message,variant){
      const event = new ShowToastEvent({
         title: title,
         message: message,
         variant: variant
      });
      this.dispatchEvent(event);
    }

    async handleSave() {
      const confirmation =  confirm('Esta seguro de que los datos que ingreso son correctos? Una vez guardados no los podra modificar.');
      if(!confirmation){
         return;
      }
      try{
         const fieldValues =  {};
         var fieldMissing = false;
         this.requiredFields.forEach(field => {
         const value = this.template.querySelector(`[data-field="${field}"]`)?.value || null;
         if(value !== null){
            fieldValues[field] = value;
         }else{
            fieldMissing = true;
         }
         });
         if(this.showCreateCase){
            if(this.newCase['Subject'] == '' || this.newCase['Origin'] == '' || this.newCase['Description'] == '' ){
               fieldMissing = true;
            }
         }
         if(!fieldMissing && !this.showCreateCase && this.companySelect != '' && this.companySelect != null
            && this.tipoValue != '' && this.tipoValue != null && this.reasonValue != '' && this.reasonValue != null){
            this.updateCaseWithRequiredFields(fieldValues);
         }else if(!fieldMissing && this.showCreateCase && this.companySelect != '' && this.companySelect != null
             && this.tipoValue != '' && this.tipoValue != null && this.reasonValue != '' && this.reasonValue != null){
            this.createNewCase(fieldValues);
         }else{
            this.showToast('Error', 'Se deben completar los campos obligatorios.','error');
            return;
         }
      }catch(error){
         console.error('Error guardando el caso: ', error);
         errorMessage = error.body.message
         this.showToast('Error', error.body.message,'error');
      }
      
    }
    
    async createNewCase(fieldValues){
      try{
         fieldValues['Subject'] = this.newCase['Subject'];
         fieldValues['Origin'] = this.newCase['Origin'];
         fieldValues['Description'] = this.newCase['Description'];
         const result = await createCase({
            accountId: this.recordId,
            fieldValues: fieldValues,
            recordTypeNameAndReason: this.reasonValue,
            type: this.tipoValue,
            contact: this.contact,
            company: this.companySelect
         });
         this.showToast('Exito', 'Se creo el caso correctamente.','success');
         this.showTipificadorRot = false;
         
         if (!this.subTabId) {
            await this.getConsoleTabsInfo(); 
         }

         await this.navigateToSubtab(result);

         if (this.subTabId && this.isSubTab) {
            await closeTab(this.subTabId);
         }
         this.clearFormValues();
      }catch(error){
         console.error('Error guardando el caso: ', error);
         this.showToast('Error', this.getTriggerError(error.body.message),'error');
      }

    }

    async updateCaseWithRequiredFields(fieldValues ){
      try{
         await updateCaseRequiredFields({
            caseId: this.recordId,
            fieldValues: fieldValues,
            recordTypeNameAndReason: this.reasonValue,
            type: this.tipoValue,
            company: this.companySelect
         });
         this.showToast('Exito', 'Se actualizo correctamente.','success');
         this.showTipificadorRot = false;
         this.refreshPage();
      }catch(error){
         console.error('Error guardando el caso: ', error);
         this.showToast('Error', this.getTriggerError(error.body.message),'error');
      }

    }

    async loadMetadataCompaniesRecords() {
      try {
         const metadata = await getCompanies();
         const setCompanies = metadata.map(record => record.GroupCompaniesUeno__c)
         this.companiesOptions = setCompanies.filter(companyValue=>['UENO_BANK','UPAY','WEPA','TUTI','UELA'].includes(companyValue));
         this.companiesOptions = this.companiesOptions.map(value => ({
            label: this.normCompaniesOptions(value),
            value: value}));
      } catch (error) {
          console.error('Error fetching metadata companies:', error);
      }
  }

    async loadMetadataRecords(company) {
        try {
            const metadata = await getTipificadores({companyName: company});
            const setTipo = [...new Set(metadata.map(record => record.Type__c))];
            this.tipoOptions = setTipo.map(value => ({
                label: this.normOptions(value),
                value: value
            }));
        } catch (error) {
            console.error('Error fetching metadata:', error);
        }
    }

    handleTipoSearch(event) {
        this.tipoSearchKey = event.target.value.toLowerCase();
        this.tipoFilteredOptions = this.tipoOptions.filter(option =>
         option.label.toLowerCase().includes(this.normOptions(this.tipoSearchKey))
        );
    }

    handleReasonSearch(event) {
      this.reasonSearchKey = event.target.value.toLowerCase();
      this.reasonFilteredOptions = this.reasonOptions.filter(option =>
         option.label.toLowerCase().includes(this.normOptions(this.reasonSearchKey))
      );
  }

    handleTipoSelect(event) {
      const selectedValue = event.currentTarget.dataset.value;
      this.tipoValue = selectedValue;
      this.tipoFilteredOptions = [];
      this.fetchReasonOptions();
      this.reasonValue = '';
    }

    handleCompanySelect(event){
      this.tipoOptions = [];
      this.tipoValue = '';
      this.reasonOptions = [];
      this.reasonValue = '';
      this.requiredFields = [];
      this.companySelect = event.detail.value;
      this.loadMetadataRecords(this.companySelect);
    }

    async fetchReasonOptions(){
      const metadataByType = await getTipificadoresByType({type: this.tipoValue});
   
      const setReason = [...new Set(metadataByType.map(record => `${record.Reason__c} | ${record.RecordType__c}` ))];
      this.reasonOptions = setReason.map(value => ({
         label: this.normOptions(value),
         value: value
     }));
    }

    handleReasonSelect(event) {
      const selectedValue = event.currentTarget.dataset.value;
      this.reasonValue = selectedValue;
      this.reasonFilteredOptions = [];
      this.fetchRequiredFieldsOptions();
    }

    async fetchRequiredFieldsOptions(){
      const metadataRequiredFields = await getRequiredFields({type: this.tipoValue, reasonAndRecordType: this.reasonValue});
      if(metadataRequiredFields && metadataRequiredFields[0].RequiredFields__c){
         this.requiredFields = metadataRequiredFields[0].RequiredFields__c
         .split(';')
         .map(field => field.trim());
      }else{
         this.requiredFields = [];
      }
    }

    handleTipoBlur(){
      this.tipoFilteredOptions = [];
    }
    handleReasonBlur(){
      this.reasonFilteredOptions = [];
    }


   refreshPage(){
      this.dispatchEvent(new RefreshEvent());
   }

   async isFirstAssign(){
      this.secondAssignment = await checkIfIsFirstAssign({caseId: this.recordId});
   }

   normOptions(label){
      return label.normalize('NFD').replace(/[\u0300-\u036f]/g, '');
   }

   normCompaniesOptions(label){
      if(label == 'UENO_BANK'){
         return 'Ueno Bank';
      }else if(label == 'UPAY'){
         return 'Upay';
      }else if(label == 'WEPA'){
         return 'Wepa';
      }else if (label == 'TUTI') {
         return 'Tuti';
      }
      else{
         return label
      } 
   }

   getTriggerError(errorTrigger){
      var mess = errorTrigger.split(',');
      var messFinal = mess[1].includes(": []") ? mess[1].replace(": []","") : mess[1];
      return messFinal ? messFinal:'Error al actualizar el caso.';
   }

   getAccountInformation(){
      this.isLoading = true;
      this.getConsoleTabsInfo();

      setTimeout(() => {

          if(this.recordId && this.recordId.startsWith('001')){
            this.showCreateCase = true;
            this.searchCompany = true;
            //if(!this.isNotAllowed){
               if(this.isAllowed){
               this.showSecondTipificador = true;
            }
              getPersonAccountContact({accountId: this.recordId})
              .then( result => {
                  if(result != null){
                      this.contact = result;
                  }
              })
              .catch(error =>{
                  showErrorMessage('Error', error?.body?.message)
              })

              this.isLoading = false;
              this.firstStep = true;
              this.showTipificador = true;
         } else if(this.recordId && this.recordId.startsWith('005')){
            this.showTipificador = true;
            this.isLoading = false;
         }else if(this.recordId == null){
            this.showCreateCase = true;
            this.showTipificador = true;
            this.isLoading = false;
            this.showMessage = true;
            this.firstStep = false;
       }
      }, "2000");
  }

  async getConsoleTabsInfo() {
   const currentTabInfo =  await getFocusedTabInfo();

   if(currentTabInfo.isSubtab){
       const primaryTabInfo = await getTabInfo(currentTabInfo.parentTabId);
       this.parentTabId = primaryTabInfo.tabId;
   } else {
       this.parentTabId = currentTabInfo.tabId;
   }

   this.recordId = currentTabInfo.pageReference.attributes.recordId;
   this.subTabId = currentTabInfo.tabId;
}

   async navigateToSubtab(caseId) {
      await openSubtab(this.parentTabId, { recordId: caseId, focus: true });
   }

   handleChange(event){
      const fieldChanged = event.detail.fieldName
      const newFieldValue = event.detail.value
      this.newCase[fieldChanged] = newFieldValue;
   }

   async closeTab() {
      if (!this.isConsoleNavigation) {
          return;
      }
      await closeTab(this.subTabId);
   }

   get isAllowed(){
      return hasPermissionCreateCase; 
    }

    async handleTipificador(){
      this.showSecondTipificador = true;
      this.shouldShowButton = false;
      try{
         this.loadMetadataCompaniesRecords();
         if(this.companySelect != null){
            if(this.companySelect.startsWith("001")){
               const companyName = await getAccountCompanyKey({idCompanyName: this.companySelect});
               this.loadMetadataRecords(companyName);
            }else{
               this.loadMetadataRecords(this.companySelect);
            }
         }

      }catch(error){
         console.log('ERROR '+error.body.message);
      }
      
    }

   
    get conditionalClass(){
      return this.showCreateCase ? 'custom-container' : 'case-container';
    } 

   async getValuesTipificacion(){
      try{
         this.loadMetadataCompaniesRecords();
         if(this.companySelect != null){
            if(this.companySelect.startsWith("001")){
               const companyName = await getAccountCompanyKey({idCompanyName: this.companySelect});
               this.loadMetadataRecords(companyName);
            }else{
               this.loadMetadataRecords(this.companySelect);
            }
         }

      }catch(error){
         console.log('ERROR '+error.body.message);
      }

   }

   clearFormValues(){
      this.newCase = {
            AccountId: '',
            Subject: '',
            RecordTypeId: '',
            Description: '',
            Origin: '',
            Status:'',
            Type: '',
            ContactId: '',
            OwnerId: ''
         }
         this.tipoValue = null;
         this.reasonValue = null;
         this.companySelect=null;
         this.requiredFields = [];
   }

    
   }