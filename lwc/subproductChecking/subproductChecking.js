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

export default class SubproductChecking extends LightningElement {
    @api personCode;
    @api isEmployee;
    @api checkingsResponse;

    @track isLoading = false;
    @track currentPageLimit = 20;
    @track currentOffset = 0;
    @track totalResults = 0;
    @track showNext = false;
    @track showBack = false;

    // Checking
    @track selectedChecking = null;
    @track selectedCheckingDetailNumber = null;
    @track recentCheckingMovements = null;
    @track detailsCheckingSelected = false;
    @track signatoriesCheckingSelected = false;
    @track recentCheckingMovementsSelected = false;
    @track selectedCheckingMovement = null;
    @track showCheckingMovementDetails = false;
    @track previousSelectedChecking = null;
    @track movementsFound = false;
    @track isCaseRecord = false;
    @track selectedCheckingCurrency = null;

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
        { label: 'Tipo Movimiento', fieldName: 'rowMovementType', hideDefaultActions: true},
        { label: 'Fecha Movimiento', fieldName: 'movementDate', initialWidth: 160, hideDefaultActions: true},
        { label: 'Monto', fieldName: 'amount', initialWidth: 160, type:'decimal', hideDefaultActions: true, cellAttributes: { alignment: 'right' }},
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
            accountNumber : this.selectedCheckingDetailNumber,
            productType : 'CHECKINGS',
            currencyDesc : this.selectedCheckingCurrency,
            wrapper: this.selectedCheckingMovement
        })
            .then(result => {
                this.toggleCheckingMovementDetailsPanel();
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

    handleCheckingClick(event) {
        this.addRemoveSelectedCustomBox(event);
        const selectedItem = event.currentTarget.dataset.accountNumber;
        this.selectedCheckingDetailNumber = selectedItem;
        this.recentCheckingMovements = null;
        this.signatoriesCheckingSelected = false;
        this.recentCheckingMovementsSelected = false;

        for (const checking of this.checkingsResponse) {
            if (checking.accountNumber === selectedItem) {
                this.selectedChecking = checking.moreDetails;
                this.selectedCheckingCurrency = this.selectedChecking.currencyDes;
                break;
            }
        }
        this.detailsCheckingSelected = true;
    }

    handleShowCheckingMovementDetails(event){
        let dataRow = event.detail.row;

        this.selectedCheckingMovement = null;
        for (let currentMovement of this.recentCheckingMovements) {
            if(currentMovement.movementId == dataRow.movementId){
                this.selectedCheckingMovement = currentMovement;
                this.showCheckingMovementDetails = true;
                break;
            }
        }
    }

    toggleCheckingMovementDetailsPanel(event){
        this.showCheckingMovementDetails = !this.showCheckingMovementDetails;
    }

    handleMovementsChecking() {
        if (this.recentCheckingMovements) {
            this.recentCheckingMovements = null;
            return;
        }

        this.detailsCheckingSelected = false;
        this.signatoriesCheckingSelected = false;
        this.recentCheckingMovementsSelected = true;

        this.fetchMovements(this.selectedCheckingDetailNumber, false, false);
    }

    handleDetailsChecking() {
        if (this.recentCheckingMovements) this.recentCheckingMovements = null;

        this.detailsCheckingSelected = true;
        this.signatoriesCheckingSelected = false;
        this.recentCheckingMovementsSelected = false;

    }

    handlePrevioCheckings() {
        this.fetchMovements(this.selectedCheckingDetailNumber, false, true);

//        this.movementsFound = true;
    }

    handleSiguienteCheckings() {
        this.fetchMovements(this.selectedCheckingDetailNumber, true, false);

//        this.movementsFound = true;
    }

    handleSignatoriesChecking(){
        if (this.recentCheckingMovements) this.recentCheckingMovements = null;

        this.detailsCheckingSelected = false;
        this.signatoriesCheckingSelected = true;
        this.recentCheckingMovementsSelected = false;
        this.movementsFound = true;
    }

    addRemoveSelectedCustomBox(event) {
        const highlightedElement = this.template.querySelector('.custom-box-active');

        if (highlightedElement) highlightedElement.classList.remove('custom-box-active');
        const targetElement = event.currentTarget;
        targetElement.classList.add('custom-box-active');
        this.movementsFound = true;

    }

    async fetchMovements(accountNumber, nextPage, previousPage) {
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
                productType: 'CHECKINGS', 
                offset: this.currentOffSet, 
                pageLimit: this.currentPageLimit,
                fromDate: this.fromDate,
                toDate : this.toDate,
                movementType : this.movementValue
            });

            if (movementResult == null) {
                this.movementsFound = false;
                this.isLoading = false;
                this.showButtons();
                throw new Error('Return, no response');

            } else {
                let mov = JSON.parse(movementResult).movements;
                this.totalResults = mov.length;

                for (let movement of mov) {
                    if(movement.amount != null && movement.amount != undefined){
                        let decimalValue =  Number(movement.amount).toLocaleString('es-PY',{ minimumFractionDigits: 2 });
                        movement.amount = decimalValue;
                    }
                }

                this.movementsFound = this.totalResults > 0 ? true : false;
                this.recentCheckingMovements = null;
                this.recentCheckingMovements = mov;

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
        this.fetchMovements(this.selectedCheckingDetailNumber, false, false);
        this.showButtons();

    }

    showButtons(){
        if(this.movementsFound){
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
    return tempDate.toISOString().split('T')[0];
}