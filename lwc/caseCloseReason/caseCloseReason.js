import { LightningElement, track, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RefreshEvent } from 'lightning/refresh';
import { NavigationMixin } from 'lightning/navigation';
import getPicklistValues from '@salesforce/apex/CaseCloseReasonController.getCloseReason';
import savePreferredCloseReason from '@salesforce/apex/CaseCloseReasonController.savePreferredCloseReason';
import cleanCloseReason from '@salesforce/apex/CaseCloseReasonController.cleanCloseReason'
import getCloseReasonDescription from '@salesforce/apex/CaseCloseReasonController.getCloseReasonDescription'
import getAccountCompanyKey from '@salesforce/apex/TipificadorController.getAccountCompanyKey';
import errorMsg from '@salesforce/label/c.permissionErrorMsg';

const CASE_FIELDS = [
   'Case.Status',
   'Case.RecordTypeId',
   'Case.Type',
   'Case.Reason',
   'Case.Origin',
   'Case.Subject',
   'Case.CloseReason__c',
   'Case.Vazquez_Group_Company__c',
   'Case.Resolution__c'
]

export default class CaseCloseReason extends NavigationMixin(LightningElement) {
   @api recordId;
   @track status;
   @track type = '';
   @track reason = '';
   @track options = [];
   @track selectedValue;
   @track saved = false;
   @track pendingValue;
   @track selectedLabel;
   @track selectedDescription;
   @track showModal = false;
   @track showSaveButton = false;
   @track showOptions = false;
   @track recordValue;
   @track showRecordValue = false;
   @track isLoading = false;
   @track companyNameRecord;
   @track hasError = false;
   @track showResolutionField = false;
   @track resolution = '';
   @track hasErrorRecord = false;
   @track hasErrorMsg = '';
   @track showReadOnly = false;
   
   //variable para mostrar el tipificador completo
   @track showCloseTipificador = false;
   
   @wire(getRecord, { recordId: '$recordId', fields: CASE_FIELDS })
   wiredCase({ error, data }) {
      this.isLoading = true;
      if (data) {
         const currentStatus = getFieldValue(data, 'Case.Status');
         const type = getFieldValue(data, 'Case.Type');
         const reason = getFieldValue(data, 'Case.Reason');
         const closeReason = getFieldValue(data, 'Case.CloseReason__c');
         const accountCompany = getFieldValue(data, 'Case.Vazquez_Group_Company__c');
         const resolution = getFieldValue(data, 'Case.Resolution__c');
         setTimeout(() => {
            if ((type == null || reason == null) || (accountCompany == '' || accountCompany == null)) {
               this.showCloseTipificador = false;
               return;
            } else {
                this.status = currentStatus;
                this.reason = reason;
                this.type = type;
                this.resolution = resolution;
                this.showCloseTipificador = true;
               if (closeReason != null) {
                  this.showRecordValue = true;
                  this.recordValue = closeReason.toLowerCase();
                }
            }
            
            this.companySelect = accountCompany;
            this.getValuesTipificacion();

            this.showReadOnly = ['Cerrado'].includes(currentStatus);
            this.showCloseTipificador = !['Nuevo'].includes(currentStatus);
         }, "1000");
      } else if (error) {
         console.error('Error al cargar el caso: ', error);
      }
      this.isLoading = false;
   }

   label = {
      errorMsg
   }

   connectedCallback() {
   }

   showToast(title, message, variant) {
      const event = new ShowToastEvent({
         title: title,
         message: message,
         variant: variant
      });
      this.dispatchEvent(event);
   }

   handleResolutionChange(event) {
      this.resolution = event.detail.value;
      this.showSaveButton = true;
   }

   handleStatusChange(event) {
      this.showSaveButton = true;
   }

   handleSave(){
      if(this.resolution != null && this.resolution != ''){
         this.showModal = true;
      } else {
         this.showToast('Error', 'Se deben completar los campos obligatorios.','error');
      }
   }

   handleChange(event) {
      this.showResolutionField = true;
      this.pendingValue = event.detail.value;

      // Buscar el label correspondiente al value
      const selectedOption = this.options.find(
         option => option.value === this.pendingValue
      );
      this.selectedLabel = selectedOption ? selectedOption.label : '';
      this.getCloseReasonDescription(this.pendingValue);
      this.showSaveButton = true;
   }

   getCloseReasonDescription(pendingValue) {
      getCloseReasonDescription({companyName: this.companyNameRecord, typeName:this.type, reasonName:this.reason, valuePicklist: pendingValue })
         .then((result) => {
            if(result != null){
               this.selectedDescription = result;
            }
         })
         .catch(error => {
               console.error('Error al guardar:', error);
         });        
   }

   cancelSave() {
      this.showModal = false;
   }

   confirmSave() {
        this.selectedValue = this.pendingValue;
        this.showModal = false;
        if((this.selectedValue != null && this.selectedValue != '') || (this.resolution != null && this.resolution != '')){
            this.saveCloseReason();
        }else{
            this.showToast('Error', 'Se deben completar los campos obligatorios.','error');
            return;
         }
    }

   saveCloseReason() {
      this.isLoading = true;
         savePreferredCloseReason({ recordId: this.recordId, closeReason: this.selectedValue, description: this.selectedDescription, resolution:this.resolution })
            .then((result) => {
               if(result == 'OK'){
                this.saved = true;
                setTimeout(() => this.saved = false, 3000);
                this.isLoading = false;
                this.showResolutionField = false;
                this.refreshPage();
                this.showToast('Completado', 'Caso cerrado correctamente.','success');
               } else if (result == 'KO'){
                  this.hasError = true;
                  this.showToast('Error', 'Ocurrió un error desconocido al cerrar el caso. Contáctese con el Administrador.','error');
               } else {
                  this.hasErrorRecord = true;
                  this.hasErrorMsg = result;
                  this.showToast('Error', 'Error al cerrar el caso: ' + result ,'error');
               }
               this.isLoading = false;
            })
            .catch(error => {
                console.error('Error al guardar saveCloseReason:', error);
                this.hasError = true;
                setTimeout(() => this.hasError = false, 3000);
                this.isLoading = false;
            });        
    }

   cleanCloseReason() {
      cleanCloseReason({ recordId: this.recordId })
         .then(() => {
         })
         .catch(error => {
               console.error('Error al guardar:', error);
         });        
    }

   async loadMetadataRecords(company,type,reason){
          await getPicklistValues({
               companyName: company,
               typeName : type,
               reasonName : reason,
               recordId: this.recordId
           })
               .then(result => {
                  if(result.length > 0){
                     this.showOptions = true;
                     this.options = result.map(opt => ({
                     label: opt.label,
                     value: opt.value.toLowerCase()
                   }))
                  } else {
                     this.recordValue = '';
                     this.cleanCloseReason();
                  }
               })
               .catch((error) => {
                  console.log('catch error' + error?.body?.message);
               });
       }

   refreshPage() {
      this.dispatchEvent(new RefreshEvent());
   }

   normOptions(label) {
      return label.normalize('NFD').replace(/[\u0300-\u036f]/g, '');
   }

   async getValuesTipificacion() {
      try {
         if (this.companySelect != null) {
            if (this.companySelect.startsWith("001")) {
               const companyName = await getAccountCompanyKey({ idCompanyName: this.companySelect });
               this.companyNameRecord = companyName;
               this.loadMetadataRecords(companyName, this.type, this.reason);
            } else {
               this.loadMetadataRecords(this.companySelect, this.type, this.reason);
            }
         }
      } catch (error) {
         console.log('ERROR ' + error.body.message);
      }
   }

}