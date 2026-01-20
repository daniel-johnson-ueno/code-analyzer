import { LightningElement, api } from 'lwc';

export default class DefaultForm extends LightningElement {

@api caseStructure;

    handleInputChange(event) {
    // Trigger the parent's change handler with field name and value
    const fieldName = event.target.dataset.field;
    console.log('fieldName '+fieldName);
    const value = event.target.value;
    console.log('value '+value);
    const selectedEvent = new CustomEvent('defaultformchange', {
        detail: { fieldName, value }
    });

    this.dispatchEvent(selectedEvent);
}

}