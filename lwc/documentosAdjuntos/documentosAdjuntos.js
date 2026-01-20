import { LightningElement, track, api } from 'lwc';
import getClientDocuments from '@salesforce/apexContinuation/DocumentosAdjuntosController.getCustomerDocuments';
import {showSuccessMessage, showErrorMessage} from 'c/utils';

export default class DocumentosAdjuntos extends LightningElement {

    @track isLoading = false;
    @track showDetails = false;
    @track documentsLoaded = false;
    @api recordId;
    customerDocuments;

    handleShowDetails(event){
        this.showDetails = !this.showDetails;

        if(!this.documentsLoaded){
            this.isLoading = true;
            this.getDocumentsByAccountId();
        }
    }

    async getDocumentsByAccountId(){

        if(this.recordId != null && this.recordId != undefined && this.recordId != ''){
            try {
                const result = await (getClientDocuments({accountId: this.recordId}))
                if (result != null) this.customerDocuments = result;

                this.documentsLoaded = true;
                this.isLoading = false;

            } catch (error) {
                this.isLoading = false;
                this.documentsLoaded = false;
                showErrorMessage('Error', error?.body?.message);

                console.log('There was a problem retrieving the Documents data.');
            }
        }
    }

}