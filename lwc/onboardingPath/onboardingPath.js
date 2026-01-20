import { LightningElement, wire, api, track } from 'lwc';
import {showErrorMessage} from 'c/utils';
import { getRecord } from 'lightning/uiRecordApi';
import ONBOARDING_STATUS_FIELD from '@salesforce/schema/Account.Onboarding_Status__c';

const defaultStagesPath = [
    { name: 'Validación Email', stageClass: 'slds-path__item slds-is-incomplete' },
    { name: 'Validación teléfono', stageClass: 'slds-path__item slds-is-incomplete' },
    { name: 'Términos y condiciones', stageClass: 'slds-path__item slds-is-incomplete' },
    { name: 'Creación contraseña', stageClass: 'slds-path__item slds-is-incomplete' },
    { name: 'Prueba de vida', stageClass: 'slds-path__item slds-is-incomplete' },
];

const defaultStagesPath2 = [
    { name: 'Cédula identidad', stageClass: 'slds-path__item slds-is-incomplete' },
    { name: 'Validación identidad', stageClass: 'slds-path__item slds-is-incomplete' },
    { name: 'Confirmación Datos', stageClass: 'slds-path__item slds-is-incomplete' },
    { name: 'Cuenta en revisión', stageClass: 'slds-path__item slds-is-incomplete' },
    { name: 'Onboarding completo', stageClass: 'slds-path__item slds-is-incomplete' }
];

export default class OnboardingPath extends LightningElement {

    @api recordId;
    @track isLoading = false;
    @track pathSuccessStages;
    @track stagesPath = [];
    @track stagesPath2 = [];
    selectedValues = [];

    connectedCallback() {
        this.resetStages();
    }

    // Restablece las etapas a su estado inicial
    resetStages() {
        this.stagesPath = defaultStagesPath.map(stage => ({ ...stage }));
        this.stagesPath2 = defaultStagesPath2.map(stage => ({ ...stage }));
    }

    @wire(getRecord, { recordId: '$recordId', fields: [ONBOARDING_STATUS_FIELD] })
    account({ error, data }) {
        if (data) {
            this.isLoading = true;

            if(data.fields.Onboarding_Status__c.value){
                this.pathSuccessStages = data.fields.Onboarding_Status__c.value.split(';');
                this.buildPathStages();
            } else {
                this.isLoading = false;
            }

        } else if (error) {
            console.error('Error fetching record:', error);
            showErrorMessage('Error', error?.body?.message)
        }
    }

    buildPathStages() {
        this.resetStages();

        this.pathSuccessStages.forEach(stage => {
            switch (stage) {
                case 'email':
                    this.stagesPath[0].stageClass = 'slds-path__item slds-is-complete';
                    break;
                case 'phone':
                    this.stagesPath[1].stageClass = 'slds-path__item slds-is-complete';
                    break;
                case 'termsConditions':
                    this.stagesPath[0].stageClass = 'slds-path__item slds-is-complete';
                    this.stagesPath[1].stageClass = 'slds-path__item slds-is-complete';
                    this.stagesPath[2].stageClass = 'slds-path__item slds-is-complete';
                    this.stagesPath[3].stageClass = 'slds-path__item slds-is-complete';
                    break;
                case 'liveness':
                    this.stagesPath[4].stageClass = 'slds-path__item slds-is-complete';
                    break;
                case 'ocr':
                    this.stagesPath2[0].stageClass = 'slds-path__item slds-is-complete';
                    break;
                case 'ocrValidation':
                    this.stagesPath2[1].stageClass = 'slds-path__item slds-is-complete';
                    break;
                case 'dataEnrichment':
                    this.stagesPath2[2].stageClass = 'slds-path__item slds-is-complete';
                    break;
                case 'onboardingReview':
                    this.stagesPath2[3].stageClass = 'slds-path__item slds-is-complete';
                    break;
                case 'successfulOnboarding':
                    this.stagesPath2[4].stageClass = 'slds-path__item slds-is-complete';
                    break;
            }
        });

        this.isLoading = false;
    }
}