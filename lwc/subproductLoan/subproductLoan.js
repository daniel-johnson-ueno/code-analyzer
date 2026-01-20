import { api, LightningElement, track, wire } from 'lwc';
import getProductMovementCallout from '@salesforce/apexContinuation/ProductsMovementsCalloutsServicesUtil.productMovementCallout';
import createRelatedMovementRecord from '@salesforce/apex/ProductsMovementsCalloutsServicesUtil.createRelatedLoanMovementRecord';
import {onHandleSort, showSuccessMessage, showErrorMessage, filterHandler} from 'c/utils';
import { CurrentPageReference } from 'lightning/navigation';
import LightningAlert from "lightning/alert";
import { RefreshEvent } from 'lightning/refresh';

/**
 * 
 * @author Alexis Castellano (alexis.castellano@itti.digital)
 * 
 */
export default class SubproductLoan extends LightningElement {
    @api personcode;
    @api isemployee;
    @api loansresponse;

    @track isloading = false;
    @track currentPageLimit = 20;
    @track currentOffset = 0;

    // Loans
    @track selectedLoan = null;
    @track selectedLoanDetailNumber = null;
    @track recentLoanMovements = null;
    @track selectedLoanMovement = null;
    @track showLoanMovementDetails = false;
    @track previousSelectedLoan = null;
    @track movementsFound = true;
    @track isCaseRecord = false;
    @track selectedLoanCurrency = null;

    movementsColumns = [
        { label: 'Mostrar', fieldName: '', initialWidth: 70, type: 'button-icon',
            typeAttributes: { iconName: 'action:preview', title: 'View', variant: 'bare', alternativeText: 'View'}
        },
        { label: 'Numero de Cuota', fieldName: 'installmentNumber', hideDefaultActions: true},
        { label: 'Fecha Expiracion', fieldName: 'expirationDate', hideDefaultActions: true},
        { label: 'Cantidad', fieldName: 'amount', type:'decimal', hideDefaultActions: true},
    ];

    get isNotEmployee() {
        return !this.isemployee;
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
            accountNumber : this.previousSelectedLoan,
            productType : 'LOANS',
            wrapper: this.selectedLoanMovement
        })
            .then(result => {
                this.toggleLoanMovementDetailsPanel();
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

    handleLoanClick(event) {
        this.addRemoveSelectedCustomBox(event);
        const selectedItem = event.currentTarget.dataset.accountNumber;
        this.selectedLoanDetailNumber = selectedItem;
        this.recentLoanMovements = null;

        for (const loan of this.loansresponse) {
            if (loan.accountNumber === selectedItem) {
                this.selectedLoan = loan.moreDetails;
                this.selectedLoanCurrency = this.selectedLoan.currencyDes;
                break;
            }
        }
    }

    handleShowLoanMovementDetails(event){
        let dataRow = event.detail.row;

        this.selectedLoanMovement = null;
        for (let currentMovement of this.recentLoanMovements) {
            if(currentMovement.installmentId === dataRow.installmentId){
                console.log('currentMovement ' + currentMovement);
                console.log('currentMovement.installmentNumber ' + currentMovement.installmentNumber);
                this.selectedLoanMovement = currentMovement;
                this.showLoanMovementDetails = true;
                break;
            }
        }
    }

    toggleLoanMovementDetailsPanel(event){
        this.showLoanMovementDetails = !this.showLoanMovementDetails;
    }

    handleMovementsLoans() {
        if (this.recentLoanMovements) {
            this.recentLoanMovements = null;
            return;
        }

        this.previousSelectedLoan = this.selectedLoanDetailNumber;
        this.fetchMovements(this.previousSelectedLoan, false, false);
        this.selectedLoanDetailNumber = null;
    }

    handleReturnLoans() {
        if (this.recentLoanMovements) this.recentLoanMovements = null;
        this.selectedLoanDetailNumber = this.previousSelectedLoan;
    }

    handlePrevioLoans() {
        this.fetchMovements(this.previousSelectedLoan, false, true);
    }

    handleSiguienteLoans() {
        this.fetchMovements(this.previousSelectedLoan, true, false);
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
        this.movementsFound = true;

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
                productType: 'LOANS', 
                offset: this.currentOffSet, 
                pageLimit: this.currentPageLimit 
            });

            let mov = JSON.parse(movementResult).installments;

            if (mov == null){
                console.log('NO MORE RESULTS');
                this.movementsFound = false;
                this.isLoading = false;
                this.currentOffSet -= this.currentPageLimit;
                console.log('return');
                throw new Error('Return, no response');
            }
            
            if (movementResult == null) {
                this.movementsFound = false;
                this.isLoading = false;
                throw new Error('Return, no response');

            } else {
                for (let movement of mov) {
                    if(movement.amount != null && movement.amount != undefined){
                        let decimalValue =  Number(movement.amount).toLocaleString('es-PY',{ minimumFractionDigits: 2 });
                        movement.amount = decimalValue;
                    }
                }
                this.recentLoanMovements = null;
                this.recentLoanMovements = mov;
            }
            this.isLoading = false;
        }
        catch (error) {
            console.log(JSON.stringify(error));
            this.isLoading = false;
        }
    }
}