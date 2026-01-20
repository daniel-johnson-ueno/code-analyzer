import { LightningElement, track, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

import calculateSecondsDifferenceInStage from '@salesforce/apex/CalculateHoursByState.calculateSecondsDifferenceInStage';

const FIELDS = ['Case.SLA_Escalado__c','Case.SLA_Derivado__c','Case.Status', 'Case.DateTimeLastStatusChange__c', 'Case.TimeInEscaladoSLA__c', 'Case.TimeInDerivadoSLA__c'];

export default class CaseStatusSLA extends LightningElement {
    
    caseStatus;
    loadingCase=true;
    @api recordId;

    @track actualSavedTimeInDerivated;
    @track actualSavedTimeInEscalated;
    @track dateTimeLastStatusChange;
    @track showComponent = false;
    @track slaDerivatedInHours;
    @track slaDerivatedInSeconds;
    @track slaEscalatedInHours;
    @track slaEscalatedInSeconds;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS})
    wiredCase({ error,data}) {
        if(data) {
            this.slaEscalatedInSeconds = data.fields.SLA_Escalado__c.value; // 43200
            this.slaDerivatedInSeconds =  data.fields.SLA_Derivado__c.value;
            this.caseStatus = data.fields.Status.value;
            this.dateTimeLastStatusChange = data.fields.DateTimeLastStatusChange__c.value;
            this.actualSavedTimeInEscalated = data.fields.TimeInEscaladoSLA__c.value;
            this.actualSavedTimeInDerivated =  data.fields.TimeInDerivadoSLA__c.value;
            this.slaDerivatedInHours= this.slaDerivatedInSeconds / 3600;
            this.slaEscalatedInHours= this.slaEscalatedInSeconds / 3600;
            this.loadingCase=false;
            this.showComponent=true;
        }else if(error){
            console.error('Error al cargar los datos del caso', error);
        }
    }

    get thereIsDerivatedSLAEstablished(){
        return this.slaDerivatedInSeconds>0;
    }

    get thereIsEscalatedSLAEstablished(){
        return this.slaEscalatedInSeconds>0;
    }

    get thereIsSLAEstablished(){
        return this.thereIsEscalatedSLAEstablished || this.thereIsDerivatedSLAEstablished;
    }

    connectedCallback() {
    }

    get reverseOrderStyle(){
        return this.caseStatus=="Derivado"?`flex-direction:column-reverse;`:`flex-direction:column`;
    }

    @api
    updateStatus(newStatus){
        this.caseStatus = newStatus;
    }
}