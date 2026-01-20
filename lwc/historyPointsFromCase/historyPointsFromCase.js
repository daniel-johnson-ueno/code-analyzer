import { LightningElement, api, track, wire } from 'lwc';
import createRelatedMovementRecord from '@salesforce/apex/ProductsMovementsCalloutsServicesUtil.createRelatedhistoryPointsMovementRecord';
import { CurrentPageReference } from 'lightning/navigation';
import LightningAlert from "lightning/alert";
import { RefreshEvent } from 'lightning/refresh';

const columns = [
    { label: 'Asociar a Caso', fieldName: 'Asociar', fixedWidth: 120, type: 'button-icon',
        typeAttributes: { iconName: 'utility:case', title: 'asociar', variant: 'bare', alternativeText: 'Asociar'}
    },
    { label: 'Razón Movimiento', fieldName: 'movementReason', hideDefaultActions: true },
    {
        label: 'Puntos',
        fieldName: 'points',
        hideDefaultActions: true,
        cellAttributes: {
            class: { fieldName: 'pointsClass' }
        }
    },
    { label: 'Fecha Movimiento', fieldName: 'recordDate', hideDefaultActions: true }
];
          
export default class HistoryPointsFromCase extends LightningElement {
    @api historyPoints;
    @track columns = columns;
    @track selectedHistoryMovement = null;
    @track showHistoryMovementDetails = false;
    @track isCaseRecord = false;

    connectedCallback() {
    }

    handleShowHistoryMovementDetails(event){
        let dataRow = event.detail.row;
        this.selectedHistoryMovement = null;
        for (let currentMovement of this.historyPoints) {
            if(currentMovement.movementId === dataRow.movementId){
                this.selectedHistoryMovement = currentMovement;
                this.showHistoryMovementDetails = true;
                break;
            }
        }
    }

    toggleHistoryMovementDetailsPanel(event){
        this.showHistoryMovementDetails = !this.showHistoryMovementDetails;
    }

    @wire(CurrentPageReference)
    getPageReferenceParameters(currentPageReference) {
       if (currentPageReference) {
          this.recordId = currentPageReference.attributes.recordId;
          let recordObject = this.recordId;
          if(recordObject.startsWith('500')){
            this.isCaseRecord = true;
          }

       }
    }

    onButtonAsocChange(event){
        this.createRecordInfo();
    }

    createRecordInfo(){
        createRelatedMovementRecord({
            caseId: this.recordId,
            productType : 'History Points',
            wrapper: this.selectedHistoryMovement
        })
            .then(result => {
                this.toggleHistoryMovementDetailsPanel();
                LightningAlert.open({
                    message: result,
                    theme: "success",
                    label: 'Correcto'
                  });
                  this.dispatchEvent(new RefreshEvent());
            })
            .catch((error) => {
                showErrorMessage('Error', error?.body?.message);
            });
    }

}