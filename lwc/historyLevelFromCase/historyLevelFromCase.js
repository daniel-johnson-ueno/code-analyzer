import { LightningElement, api, track, wire } from 'lwc';
import createRelatedMovementRecord from '@salesforce/apex/ProductsMovementsCalloutsServicesUtil.createRelatedHistoryLevelMovementRecord';
import { CurrentPageReference } from 'lightning/navigation';
import LightningAlert from "lightning/alert";
import { RefreshEvent } from 'lightning/refresh';

const columns = [
                { label: 'Asociar a Caso', fieldName: 'Asociar', fixedWidth: 120, type: 'button-icon',
                    typeAttributes: { iconName: 'utility:case', title: 'asociar', variant: 'bare', alternativeText: 'Asociar'}
                },
              { label: 'Fecha', fieldName: 'recordDate', hideDefaultActions: true},
              { label: 'Nivel', fieldName: 'level', type: 'decimal', hideDefaultActions: true},
              { label: 'Mínimo', fieldName: 'minimumPoints', type: 'decimal', hideDefaultActions: true},
              { label: 'Máximo', fieldName: 'maximumPoints', type: 'decimal', hideDefaultActions: true},

          ];
          
export default class HistoryLevelFromCase extends LightningElement {

    @api historyLevel;
    @track columns = columns;
    @track selectedHistoryMovement = null;
    @track showHistoryMovementDetails = false;
    @track isCaseRecord = false;

    connectedCallback() {
    }

    handleShowHistoryMovementDetails(event){
        let dataRow = event.detail.row;
        this.selectedHistoryMovement = null;
        for (let currentMovement of this.historyLevel) {
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
            productType : 'History',
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