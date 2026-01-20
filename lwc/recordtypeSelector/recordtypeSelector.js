import { LightningElement, wire, track } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from 'lightning/navigation';
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';

export default class RecordtypeSelector extends NavigationMixin(LightningElement) {
    @track recordTypes = [];
    selectedRecordType;
    isButtonDisabled = true;

    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT })
    wiredObjectInfo({ data, error }) {
        try {
            if (data && data.recordTypeInfos) {
                this.recordTypes = Object.values(data.recordTypeInfos)
                    .filter(rt => rt.available && 
                        rt.name !== 'Onboarding' && 
                        rt.name !== 'Master' && 
                        rt.name !== 'Principal' )
                    .map(rt => ({
                        label: rt.name,
                        value: rt.recordTypeId
                    }));
            } else if (error) {
                console.error('Error al obtener los tipos de registro (detallado):', JSON.parse(JSON.stringify(error)));
            }
        } catch (err) {
            console.error('Error inesperado en wiredObjectInfo:', err);
        }
    }


    handleRecordTypeChange(event) {
        try {
            this.selectedRecordType = event.detail.value;
            this.isButtonDisabled = false;
        } catch (err) {
            console.error('Error en handleRecordTypeChange:', err);
        }
    }

    handleContinue() {
        try {
            if (this.selectedRecordType) {
                this[NavigationMixin.Navigate]({
                    type: 'standard__objectPage',
                    attributes: {
                        objectApiName: 'Opportunity',
                        actionName: 'new'
                    },
                    state: {
                        nooverride: '1',
                        useRecordTypeCheck: '1',
                        recordTypeId: this.selectedRecordType
                    }
                });
            } else {
                console.warn('No hay un recordType seleccionado al intentar continuar.');
            }
        } catch (err) {
            console.error('Error en handleContinue:', err);
        }
    }
}