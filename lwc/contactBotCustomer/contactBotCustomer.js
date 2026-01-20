import { LightningElement, api, track } from 'lwc';
import { showToastMessage } from 'c/utils';
import execute from '@salesforce/apex/ContactBotCustomerController.execute';


export default class ContactBotCustomer extends LightningElement {
    @api recordId;

    handleClick() {
        execute({ caseId: this.recordId })
            .then(result => {
                if(result.isError) {
                    showToastMessage('Error', result.eventType, 'Error', 'dismissable', this);
                } else {
                    showToastMessage('Cliente contactado', 'Se iniciara una sesion de chat', 'Success', 'dismissable', this);
                }
            })
            .catch(error => {
                showToastMessage('Error', 'No se pudo contactar al client', 'Error', 'dismissable', this);
            });
    }
}