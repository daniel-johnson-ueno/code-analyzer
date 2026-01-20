import { api, LightningElement, track, wire } from 'lwc';
import getProductMovementCallout from '@salesforce/apexContinuation/ProductsMovementsCalloutsServicesUtil.productMovementCallout';
import createRelatedMovementRecord from '@salesforce/apex/ProductsMovementsCalloutsServicesUtil.createRelatedMovementRecord';
import {onHandleSort, showSuccessMessage, showErrorMessage, filterHandler} from 'c/utils';
import { CurrentPageReference } from 'lightning/navigation';
import LightningAlert from "lightning/alert";
import { RefreshEvent } from 'lightning/refresh';

const todayDate = new Date();
todayDate.toLocaleDateString('en-CA', { timeZone: 'America/Asuncion' });
const formatedTodayDate = getFormattedDate(todayDate);
const fromDate = getFormattedDate(todayDate, 0, 1);

export default class SubproductSaving extends LightningElement {

    @api personCode;
    @api isEmployee;
    @api savingsResponse;

    @track isLoading = false;
    @track currentPageLimit = 20;
    @track currentOffset = 0;
    @track totalResults = 0;
    @track showNext = false;
    @track showBack = false;

    @track selectedSaving = null;
    @track selectedSavingDetailNumber = null;
    @track recentSavingMovements = null;
    @track detailsSavingSelected = false;
    @track signatoriesSavingSelected = false;
    @track recentSavingMovementsSelected = false;
    @track selectedSavingMovement = null;
    @track showSavingMovementDetails = false;
    @track previousSelectedSaving = null;
    @track movementsFound = false;
    @track selectedSavingCurrency = null;

    //Dates
    @track todayDate = formatedTodayDate;
    @track fromDate = fromDate;
    @track toDate = formatedTodayDate;

    //Tipo de Movimiento
    @track movementValue = 'todos';


    movementColumns = [
        { label: '', fieldName: '', fixedWidth: 36, type: 'button-icon',
            typeAttributes: { iconName: 'action:preview', title: 'View', variant: 'bare', alternativeText: 'View'}
        },
        { label: 'Número de comprobante', fieldName: 'receiptNumber', hideDefaultActions: true},
        { label: 'Tipo Movimiento', fieldName: 'rowMovementType', hideDefaultActions: true},
        { label: 'Fecha Movimiento', fieldName: 'movementDate', initialWidth: 160, hideDefaultActions: true},
        { label: 'Monto', fieldName: 'amount', initialWidth: 160, type:'decimal', hideDefaultActions: true, cellAttributes: { alignment: 'right' }},
        { label: 'Moneda', fieldName: 'currencyCode', initialWidth: 80, hideDefaultActions: true},
    ];

    get isNotEmployee() {
        return !this.isEmployee;
    }

    get movementOptions() {
        return [
            { label: 'Ver Todos', value: 'todos' },
            { label: 'Crédito', value: 'C' },
            { label: 'Débito', value: 'D' },
            { label: 'Cambio de Estado', value: 'E' }
        ];
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

    handleChangeMovement(event) {
        this.movementValue = event.detail.value;
    }

    onButtonAsocChange(event){
        this.createRecordInfo();
    }

    createRecordInfo(){
        createRelatedMovementRecord({
            caseId: this.recordId,
            accountNumber : this.selectedSavingDetailNumber,
            productType : 'SAVINGS',
            currencyDesc : this.selectedSavingCurrency,
            wrapper: this.selectedSavingMovement
        })
            .then(result => {
                this.toggleSavingMovementDetailsPanel();
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

    handleSavingClick(event) {
        this.addRemoveSelectedCustomBox(event);
        const selectedItem = event.currentTarget.dataset.accountNumber;
        this.selectedSavingDetailNumber = selectedItem;
        this.recentSavingMovements = null;
        this.signatoriesSavingSelected = false;
        this.recentSavingMovementsSelected = false;

        for (const saving of this.savingsResponse) {
            if (saving.accountNumber === selectedItem) {
                this.selectedSaving = saving.moreDetails;
                this.selectedSavingCurrency = this.selectedSaving.currencyDes;
                break;
            }
        }
        this.detailsSavingSelected = true;
    }

    handleShowSavingMovementDetails(event){
        let dataRow = event.detail.row;

        this.selectedSavingMovement = null;
        for (let currentMovement of this.recentSavingMovements) {
            if(currentMovement.movementId === dataRow.movementId){
                this.selectedSavingMovement = currentMovement;
                this.showSavingMovementDetails = true;
                break;
            }
        }
    }

    toggleSavingMovementDetailsPanel(event){
        this.showSavingMovementDetails = !this.showSavingMovementDetails;
    }


    handleMovementsSavings() {
        if (this.recentSavingMovements) {
            this.recentSavingMovements = null;
            return;
        }
        this.detailsSavingSelected = false
        this.recentSavingMovementsSelected = true;
        this.signatoriesSavingSelected = false;
        this.fetchMovements(this.selectedSavingDetailNumber, false, false);
    }

    handleDetailsSavings() {
        if (this.recentSavingMovements) this.recentSavingMovements = null;
        this.recentSavingMovementsSelected = false;
        this.signatoriesSavingSelected = false;
        this.detailsSavingSelected = true
    }


    handlePrevioSavings() {
        this.fetchMovements(this.selectedSavingDetailNumber, false, true);
    }

    handleSiguienteSavings() {
        this.fetchMovements(this.selectedSavingDetailNumber, true, false);
    }

    handleSignatoriesSavings(){
        if (this.recentSavingMovements) this.recentSavingMovements = null;
        this.detailsSavingSelected = false;
        this.recentSavingMovementsSelected = false;
        this.signatoriesSavingSelected = true;
    }

    addRemoveSelectedCustomBox(event) {
        const highlightedElement = this.template.querySelector('.custom-box-active');

        if (highlightedElement) highlightedElement.classList.remove('custom-box-active');
        const targetElement = event.currentTarget;
        targetElement.classList.add('custom-box-active');
//        this.movementsFound = true;

    }

    async fetchMovements(accountNumber, nextPage, previousPage) { //Ademas tiene que enviar las fechas
        this.isLoading = true;
        this.movementsFound = false;

        try {
            // First load
            if (!nextPage && !previousPage) {
                this.currentOffSet = 0;
            }
            else {
                if (nextPage && this.currentOffSet == null) {
                    this.currentOffSet = 0;
                }
                else if (nextPage) {
                    this.currentOffSet += this.currentPageLimit;
                }

                if (previousPage && this.currentOffSet == null) {
                    this.currentOffSet = 0;
                }
                else if (previousPage && this.currentOffSet - this.currentPageLimit >= 0) {
                    this.currentOffSet -= this.currentPageLimit;
                }
            }

            let movementResult = await getProductMovementCallout({ 
                accountNumber: accountNumber, 
                productType: 'SAVINGS', 
                offset: this.currentOffSet, 
                pageLimit: this.currentPageLimit,
                fromDate: this.fromDate,
                toDate : this.toDate,
                movementType : this.movementValue

            });


            if (movementResult == null) {
                console.log('null')
                this.movementsFound = false;
                this.isLoading = false;
                this.showButtons();
                throw new Error('Return, no response');

            } else {
                let mov = JSON.parse(movementResult).movements;
                this.totalResults = mov.length;
                this.movementsFound = this.totalResults > 0 ? true : false;

                for (let movement of mov) {
                    if(movement.amount != null && movement.amount != undefined){
                        let decimalValue =  Number(movement.amount).toLocaleString('es-PY',{ minimumFractionDigits: 2 });
                        movement.amount = decimalValue;
                    }
                };

                this.recentSavingMovements = null;
                this.recentSavingMovements = mov;
            }
            this.isLoading = false;
            this.showButtons();
        }
        catch (error) {
            console.log(JSON.stringify(error));
            this.isLoading = false;
        }
    }

    //Date inputs
    onDateChange(event){

        if(event.target.name == 'fromDate'){
            this.fromDate = event.detail.value;
        } else if (event.target.name == 'toDate'){
            this.toDate = event.detail.value;
        }
    }

    onButtonChange(event){
        this.currentOffSet = 0;
        this.fetchMovements(this.selectedSavingDetailNumber, false, false);
        this.showButtons();

    }

    showButtons(){

        if(this.movementsFound == true){
            this.showNext = this.totalResults >= this.currentPageLimit ? true : false;
            this.showBack = this.currentOffSet != 0 ? true : false;

        } else {
            this.showNext = false;
            this.showBack = this.currentOffSet != 0 ? true : false;
        }

    }


}

function getFormattedDate(date, daysToSubtract = 0, monthsToSubtract = 0, yearsToSubtract = 0) {
    let tempDate = new Date(date);
    tempDate.setDate(tempDate.getDate() - daysToSubtract);
    tempDate.setMonth(tempDate.getMonth() - monthsToSubtract);
    tempDate.setFullYear(tempDate.getFullYear() - yearsToSubtract);
    console.log(tempDate);
    return tempDate.toISOString().split('T')[0];
}