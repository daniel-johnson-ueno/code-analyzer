import { LightningElement, api, track } from 'lwc';
import createLeadAndCloseCase from '@salesforce/apex/OnboardingController.createLeadAndCloseCase';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RefreshEvent } from 'lightning/refresh';

export default class OnboardingForm extends LightningElement {
    @api recordId; 
    @track companyName = '';  
    @track ruc = '';  
    @track documentNumber = '';  
    @track documentType = '';  
    @track preferenceExperienceCenter = '';  
    @track emailVal = '';  
    @track isLoading = false; 

    // Bandera para asegurarse de que el componente sigue activo
    isComponentActive = true;

    handleInputChange(event) {
        const fieldName = event.target.name;
        if (fieldName === 'Preference_experience_center__c') {
            this.preferenceExperienceCenter = event.target.value;
        } else if (fieldName === 'CompanyName__c') {
            this.companyName = event.target.value;
        } else if (fieldName === 'ruc__c') {
            this.ruc = event.target.value;
        } else if (fieldName === 'DocumentNumber__c') {
            this.documentNumber = event.target.value;
        } else if (fieldName === 'DocumentType__c') {
            this.documentType = event.target.value;
        }else if (fieldName === 'Email__c') {
            this.emailVal = event.target.value;
        }
    }

    handleSubmit(event) {
        event.preventDefault(); 
        
        if (this.recordId && this.preferenceExperienceCenter && this.companyName && this.ruc && this.documentNumber && this.documentType && this.emailVal) {
            this.isLoading = true; // Muestra el spinner
            this.createLeadAndCloseCase();
        } else {
            this.showToast('Error', 'Faltan campos obligatorios', 'error');
        }
    }

    createLeadAndCloseCase() {
        createLeadAndCloseCase({
            caseId: this.recordId, 
            preferenceExperienceCenter: this.preferenceExperienceCenter,
            companyName: this.companyName,
            ruc: this.ruc,
            documentNumber: this.documentNumber,
            documentType: this.documentType,
            email: this.emailVal
        })
        .then(() => {
            if (this.isComponentActive) {
                this.showToast('Éxito', 'Su caso ha sido escalado a Ventas.', 'success');
                this.dispatchEvent(new RefreshEvent());
            }
        })
        .catch((error) => {
            if (this.isComponentActive) {
                this.showToast('Error', error.body.message, 'error');
            }
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }

    disconnectedCallback() {
        this.isComponentActive = false; 
    }
}