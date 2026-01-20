import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import updateAccountCallout from '@salesforce/apex/UpdateAccountController.updateAccountCallout';
import { showSuccessMessage, showErrorMessage } from 'c/utils';

const LAST_MODIFIED_DATE_FIELD = 'Account.LastModifiedDate';
const DOCUMENT_NUMBER_FIELD = 'Account.DocumentNumber__c';
const DOCUMENT_TYPE_FIELD = 'Account.DocumentType__c';
const FIELDS = [LAST_MODIFIED_DATE_FIELD, DOCUMENT_NUMBER_FIELD, DOCUMENT_TYPE_FIELD];
const DATE_OPTIONS = { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' };
const DATE_LOCALES = 'es-ES';
const COLON_DATE_SEPARATOR = ',';
const DATE_TIME_SEPARATOR = ' - ';
const TIME_SUFFIX = 'hs';
const SUCCESS_TITLE = '¡Listo! Cuenta actualizada';
const SUCCESS_MESSAGE = 'Revisá los detalles en el panel..';
const DEFAULT_ERROR_TITLE = 'Hubo un error al actualizar';
const DEFAULT_ERROR_MESSAGE = 'Por favor, intentá de nuevamente.';
const NOT_FOUND_ERROR_TITLE = 'La cuenta no existe';
const NOT_FOUND_ERROR_MESSAGE = 'La cuenta que estás actualizando no existe o no se encuentra disponible en este momento. Por favor, contacta al administrador de Salesforce.';

export default class UpdateAccount extends LightningElement {
    @api recordId;
    account;
    @track isLoading = false
    @track hasError = false
    @track errorMessage = DEFAULT_ERROR_MESSAGE;
    @track errorTitle = DEFAULT_ERROR_TITLE;


    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredAccount({ error, data }) {
        if (data) {
            this.account = data;
        } else if (error) {
            console.error(error);
        }
    }

    get lastModifiedDate() {
        if (this.account) {
            const fieldDate = getFieldValue(this.account, LAST_MODIFIED_DATE_FIELD);
            return this.getUpdatedDate(fieldDate);
        }
        return '';
    }

    get shouldBeDisabled() {
        return this.isLoading;
    }

    handleUpdate() {
        this.isLoading = true;
        const documentNumber = getFieldValue(this.account, DOCUMENT_NUMBER_FIELD);
        const documentType = getFieldValue(this.account, DOCUMENT_TYPE_FIELD);
        
        updateAccountCallout({ documentNumber: documentNumber, documentType: documentType, accountId: this.recordId })
            .then(response => {
                this.isLoading = false;
                if (response.hasError) {
                    this.errorMessage = response.errorMessage;
                    this.hasError = true;
                    this.solveErrorMessage(response.errorCode);
                    showErrorMessage(this.errorTitle, this.errorMessage);
                } else {
                    showSuccessMessage(SUCCESS_TITLE, SUCCESS_MESSAGE, this);
                    setTimeout(() => {
                        window.location.reload();
                    }, "2000");
                }                
            })
            .catch(error => {
                console.log('error: ' + error);
                this.isLoading = false;
                this.hasError = true;
                showErrorMessage(this.errorTitle, this.errorMessage);
            });
    }

    getUpdatedDate(fieldDate) {
        if (!fieldDate) {
            return '';
        }

        const date = new Date(fieldDate);

        return date.toLocaleString(DATE_LOCALES, DATE_OPTIONS).replace(COLON_DATE_SEPARATOR, DATE_TIME_SEPARATOR) + TIME_SUFFIX;;
    }
    
    solveErrorMessage(statusCode) {
        if(statusCode === '404'){
            this.errorTitle = NOT_FOUND_ERROR_TITLE;
            this.errorMessage = NOT_FOUND_ERROR_MESSAGE;
        }
    }
}