import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getActiveUsers from '@salesforce/apex/OpportunitiesListViewHelper.getActiveUsers';

export default class OpportunityEditForm extends LightningElement {
    @api showModal;
    @api selectedIds;
    @api recordId;

    newOwnerId = '';  
    isDisabled = false; 

    activeUserOptions = [];

    @wire(getActiveUsers)
    wiredUsers({ data, error }) {
        if (data) {
            this.activeUserOptions = data.map(user => ({
                label: user.Name,
                value: user.Id
            }));
        } else if (error) {
            console.error('Error al cargar usuarios activos:', error);
        }
    }
    
    handleOwnerChange(event) {
        this.newOwnerId = event.detail.value;
    }
    
    connectedCallback() {
        if (this.task && this.isOwnerAQueue) {
            this.newOwnerId = this.task.OwnerId;
        }
    }

    handleSubmit(event) {
        event.preventDefault();
        const fields = event.detail.fields;
    
        if (this.newOwnerId) {
            fields.OwnerId = this.newOwnerId;  
        }
    
        this.dispatchEvent(new CustomEvent('submit', {
            detail: {
                values: {
                    OwnerId: fields.OwnerId
                }
            }
        }));
        this.dispatchEvent(new CustomEvent('close'));
    }
    
    

    handleCancel() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    showSuccessToast(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: message,
            variant: 'success'
        }));
    }

    showErrorToast(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error'
        }));
    }
}