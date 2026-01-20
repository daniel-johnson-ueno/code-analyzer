import { LightningElement, api } from 'lwc';

export default class TransferForm extends LightningElement {

@api caseStructure;

    handleInputChange(event) {
        const fieldName = event.target.dataset.field;
        const value = event.target.value;

        const selectedEvent = new CustomEvent('formchange', {
            detail: { fieldName, value }
        });

        this.dispatchEvent(selectedEvent);
    }
}