import { LightningElement, track, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RefreshEvent } from 'lightning/refresh';
import { IsConsoleNavigation, getFocusedTabInfo, closeTab, getTabInfo, openSubtab } from 'lightning/platformWorkspaceApi';
import { NavigationMixin } from 'lightning/navigation';
import getTipificadores from '@salesforce/apex/TipificadorController.getTipificadores';
import getCompanies from '@salesforce/apex/TipificadorController.getCompanies';
import getTipificadoresByType from '@salesforce/apex/TipificadorController.getTipificadoresByType';
import getRequiredFields from '@salesforce/apex/TipificadorController.getRequiredFields';
import updateCaseRequiredFields from '@salesforce/apex/TipificadorController.updateCaseRequiredFields';
import checkIfIsFirstAssign from '@salesforce/apex/TipificadorController.checkIfIsFirstAssign';
import getAccountCompanyKey from '@salesforce/apex/TipificadorController.getAccountCompanyKey';

//campos del caso a consultar
const CASE_FIELDS = [
   'Case.Status',
   'Case.RecordTypeId',
   'Case.Type',
   'Case.Reason',
   'Case.Origin',
   'Case.Subject',
   'Case.Description',
   'Case.ROTDerivation__c',
   'Case.Vazquez_Group_Company__c'
]

export default class Tipificador extends NavigationMixin(LightningElement) {
   @track parentTabId;
   @track subTabId;
   //variable para el listado de opciones type
   @track tipoOptions = [];
   //variable para el listado de opciones companias
   @track companiesOptions = [];
   //variable para el listado de opciones type filtradas por input
   @track tipoFilteredOptions = [];
   //variable para el listado de opciones motivo(reason)
   @track reasonOptions = [];
   //variable para el listado de opciones reason filtradas por input
   @track reasonFilteredOptions = [];
   //variable para el listado de campos requeridos segun la mdt
   @track requiredFields = [];
   //variable para el id del caso
   @api recordId;
   //variable para indicar si muestra campos requeridos
   @track showRequiredFields = false;
   //variable para indicar si carga campos obligatorios segun el estado del caso
   @track disabled = true;
   //variable para mostrar el tipificador completo
   @track showTipificador = false;
   //variable para mostrar el tipificador si esta en el ROT
   @track showTipificadorRot = false;
   //variable para mostrar campos de tipificador
   @track showSecondTipificador = false;
   //variable para indicar si el caso esta enm el ROT
   @track secondAssignment = false;
   //variable para indicar si el caso tiene asunto y/ descripcion vacio
   @track emptySubject = false;
   //variable para indicar si el caso tiene asunto y/ descripcion vacio
   @track emptyDescription = false;
   //variable para guardar el estado del caso
   @track status;
   //variable para indicar si se debe mostrar el boton de Re tipificar
   @track shouldShowButton = false;
   //variable para indicar si debe seleccionar la empresa o el caso ya esta relacionado 
   @track searchCompany = false;
   //variable para guardar el valor de la empresa del grupo vazquez
   @track companySelect;
   //variable para guardar el type seleccionado
   tipoValue = null;
   //variable para guardar el reason seleccionado
   reasonValue = null;
   //variable para guardar la key ingresada para la busqueda del type
   tipoSearchKey = '';
   //variable para guardar la key ingresada para la busqueda del reason
   reasonSearchKey = '';
   //variable para mostrar el mensaje de error
   errorMessage = '';
   //variable para guardar el valor del asunto
   @track subjectValue;
   //variable para guardar el valor la descripcion
   @track descriptionValue;
   @track isTipificacionComplete = false;
   @track isSubjectComplete = false;
   @track isDescriptionComplete = false;
   @track  queue = '';

   @wire(IsConsoleNavigation) isConsoleNavigation;

   @wire(getRecord, { recordId: '$recordId', fields: CASE_FIELDS })
   wiredCase({ error, data }) {
      if (data) {
         this.showSecondTipificador = false;
         this.showTipificadorRot = false;
         const currentStatus = getFieldValue(data, 'Case.Status');
         const type = getFieldValue(data, 'Case.Type');
         const reason = getFieldValue(data, 'Case.Reason');
         const subject = getFieldValue(data, 'Case.Subject');
         const description = getFieldValue(data, 'Case.Description')
         const deriveRot = getFieldValue(data, 'Case.ROTDerivation__c');
         const accountCompany = getFieldValue(data, 'Case.Vazquez_Group_Company__c');
         this.isFirstAssign();
         setTimeout(() => {
            if ((type == null || reason == null) && currentStatus == 'Asignado') {
               this.showSecondTipificador = true;
            } else if (currentStatus == 'Escalado' || (deriveRot && currentStatus == 'Asignado' && this.secondAssignment)) {
               this.showTipificadorRot = true;
               this.shouldShowButton = true;
            }
            this.showTipificador = this.showSecondTipificador || this.showTipificadorRot;
            if (accountCompany == '' || accountCompany == null) {
               this.searchCompany = true;
            } else {
               this.companySelect = accountCompany;
               this.getValuesTipificacion();
            }
            if(subject == '' || subject == null){
               this.emptySubject = true;
            }else{
               this.subjectValue = subject;
            }
            if(description == '' || description == null){
               this.emptyDescription = true;
            }else{
               this.descriptionValue = description;
            }
            this.disabled = !['Asignado', 'Escalado', 'Derivado'].includes(currentStatus);
         }, "2000");
         if (!this.disabled) {
            this.fetchRequiredFieldsOptions();
         }
      } else if (error) {
         console.error('Error al cargar el caso: ', error);
      }
   }

   connectedCallback() {
      this.loadMetadataCompaniesRecords();
      const companyName = '';
      if (this.companySelect != null) {
         companyName = this.companySelect;
      }
      this.loadMetadataRecords(companyName);
   }

   showToast(title, message, variant) {
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
         this.isTipificacionComplete = this.tipoValue != '' && this.tipoValue != null && this.reasonValue != '' && this.reasonValue != null;
         this.isSubjectComplete = this.subjectValue != '' && this.subjectValue != null;
         this.isDescriptionComplete = this.descriptionValue != '' && this.descriptionValue != null;

         if(!fieldMissing && this.companySelect != '' && this.companySelect != null
            && this.isTipificacionComplete && this.isSubjectComplete && this.isDescriptionComplete){
            this.updateCaseWithRequiredFields(fieldValues);
         }else{
            this.showToast('Error', 'Se deben completar los campos obligatorios.','error');
            return;
         }
      }catch(error){
         console.error('Error guardando el caso: ', error);
         errorMessage = error.body.message;
         this.showToast('Error', error.body.message,'error');
      } 
    }


   async updateCaseWithRequiredFields(fieldValues) {
      try {
         await updateCaseRequiredFields({
            caseId: this.recordId,
            fieldValues: fieldValues,
            recordTypeNameAndReason: this.reasonValue,
            type: this.tipoValue,
            company: this.companySelect,
            subject: this.subjectValue,
            description: this.descriptionValue
         });
         this.showToast('Exito', 'Se actualizo correctamente.', 'success');
         this.showTipificadorRot = false;
         this.refreshPage();
      } catch (error) {
         console.error('Error guardando el caso: ', error);
         this.showToast('Error', this.getTriggerError(error.body.message), 'error');
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
         const metadata = await getTipificadores({ companyName: company });
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
      this.queue = '';
   }

   handleCompanySelect(event) {
      this.tipoOptions = [];
      this.tipoValue = '';
      this.reasonOptions = [];
      this.reasonValue = '';
      this.requiredFields = [];
      this.companySelect = event.detail.value;
      this.loadMetadataRecords(this.companySelect);
   }

   async fetchReasonOptions() {
      const metadataByType = await getTipificadoresByType({ type: this.tipoValue });
      const setReason = [...new Set(metadataByType.map(record => `${record.Reason__c} | ${record.RecordType__c}`))];
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
      this.queue = '';
   }

   async fetchRequiredFieldsOptions() {
      const metadataRequiredFields = await getRequiredFields({ type: this.tipoValue, reasonAndRecordType: this.reasonValue });
      if (metadataRequiredFields[0] != null){
         if (metadataRequiredFields[0].CaseOwnerQueue__c != null){
            this.queue = this.replace_(metadataRequiredFields[0].CaseOwnerQueue__c);
         }
         if(metadataRequiredFields[0].RequiredFields__c) {
            this.requiredFields = metadataRequiredFields[0].RequiredFields__c
               .split(';')
               .map(field => field.trim());
         } else {
            this.requiredFields = [];
         }
      }   
   }

   handleTipoBlur() {
      this.tipoFilteredOptions = [];
   }
   handleReasonBlur() {
      this.reasonFilteredOptions = [];
   }

   handleSubject(event){
      this.subjectValue = event.detail.value;
   }

   handleDescription(event){
      this.descriptionValue = event.detail.value;
   }

   refreshPage() {
      this.dispatchEvent(new RefreshEvent());
   }

   async isFirstAssign() {
      this.secondAssignment = await checkIfIsFirstAssign({ caseId: this.recordId });
   }

   normOptions(label) {
      return label.normalize('NFD').replace(/[\u0300-\u036f]/g, '');
   }

   normCompaniesOptions(label) {
      if (label == 'UENO_BANK') {
         return 'Ueno Bank';
      } else if (label == 'UPAY') {
         return 'Upay';
      } else if (label == 'WEPA') {
         return 'Wepa';
      }else if (label == 'TUTI') {
         return 'Tuti';
      }
      else{
         return label
      } 
   }

   getTriggerError(errorTrigger) {
      var mess = errorTrigger.split(',');
      var messFinal = mess[1].includes(": []") ? mess[1].replace(": []", "") : mess[1];
      return messFinal ? messFinal : 'Error al actualizar el caso.';
   }

   async getConsoleTabsInfo() {
      const currentTabInfo = await getFocusedTabInfo();
      if (currentTabInfo.isSubtab) {
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

   async closeTab() {
      if (!this.isConsoleNavigation) {
         return;
      }
      await closeTab(this.subTabId);
   }

   async handleTipificador() {
      this.showSecondTipificador = true;
      this.shouldShowButton = false;
      try {
         this.loadMetadataCompaniesRecords();
         if (this.companySelect != null) {
            if (this.companySelect.startsWith("001")) {
               const companyName = await getAccountCompanyKey({ idCompanyName: this.companySelect });
               this.loadMetadataRecords(companyName);
            } else {
               this.loadMetadataRecords(this.companySelect);
            }
         }
      } catch (error) {
         console.log('ERROR ' + error.body.message);
      }
   }

   async getValuesTipificacion() {
      try {
         this.loadMetadataCompaniesRecords();
         if (this.companySelect != null) {
            if (this.companySelect.startsWith("001")) {
               const companyName = await getAccountCompanyKey({ idCompanyName: this.companySelect });
               this.loadMetadataRecords(companyName);
            } else {
               this.loadMetadataRecords(this.companySelect);
            }
         }
      } catch (error) {
         console.log('ERROR ' + error.body.message);
      }
   }

   replace_(queue) {
      return queue.replace(/_/g, ' ');
   }
}