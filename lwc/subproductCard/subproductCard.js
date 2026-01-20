import { api, LightningElement, track, wire } from 'lwc';
import getProductMovementCallout from '@salesforce/apexContinuation/ProductsMovementsCalloutsServicesUtil.productMovementCallout';
import createRelatedMovementRecord from '@salesforce/apex/ProductsMovementsCalloutsServicesUtil.createRelatedMovementRecord';
import { showErrorMessage } from 'c/utils';
import { CurrentPageReference } from 'lightning/navigation';
import LightningAlert from "lightning/alert";
import { RefreshEvent } from 'lightning/refresh';


const todayDate = new Date();
const formatedTodayDate = getFormattedDate(todayDate);
const toDate = getFormattedDate(todayDate, 0);
const fromDate = getFormattedDate(todayDate, 30);

export default class SubproductCard extends LightningElement {
    @api personCode;
    @api isEmployee;
    @api cardsResponse;

    @track isLoading = false;
    @track currentPageLimit = 20;
    @track currentOffset = 0;
    @track totalResults = 0;
    @track showNext = false;
    @track showBack = false;

    // Cards
    @track selectedCard = null;
    @track selectedCardDetailNumber = null;
    @track selectedCardIsCredit = null;
    @track recentCardMovements = null;
    @track selectedCardMovement = null;
    @track showCardMovementDetails = false;
    @track previousSelectedCard = null;
    @track movementsFound = false;
    @track isCaseRecord = false;
    @track selectedCardCurrency = null;

    //Dates
    @track todayDate = formatedTodayDate;
    @track fromDate = fromDate;
    @track toDate = toDate;
    @track minDate = getFormattedDate(new Date(), 30);
    @track maxDate = getFormattedDate(new Date());


    genericMovementColumns = [
        { label: 'Mostrar', fieldName: '', initialWidth: 70, type: 'button-icon',
            typeAttributes: { iconName: 'action:preview', title: 'View', variant: 'bare', alternativeText: 'View'}
        },
        { label: 'Tipo Movimiento', fieldName: 'movementType', hideDefaultActions: true },
        { label: 'Fecha Movimiento', fieldName: 'movementDate', hideDefaultActions: true },
        { label: 'Monto', fieldName: 'amount', type:'decimal', hideDefaultActions: true, cellAttributes: { alignment: 'right' }},
    ];

    get isNotEmployee() {
        return !this.isEmployee;
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
            accountNumber : this.selectedCardDetailNumber,
            productType : 'CREDIT_CARDS',
            currencyDesc : this.selectedCardCurrency,
            wrapper: this.selectedCardMovement
        })
            .then(result => {
                this.toggleCardMovementDetailsPanel();
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


    handleCardClick(event) {
        this.addRemoveSelectedCustomBox(event);

        const selectedItem = event.currentTarget.dataset.cardNumber;
        this.recentCardMovements = null;

        this.selectedCardDetailNumber = selectedItem;

        for (const card of this.cardsResponse) {
            if (card.cardNumber === selectedItem) {
                this.selectedCardIsCredit = card.isCredit
                this.selectedCard = card.moreDetails;
                this.selectedCardCurrency = this.selectedCard.currencyDes;
                break;
            }
        }
    }

    handleMovementsCards() {

        if (this.recentCardMovements) {
            this.recentCardMovements = null;
            return;
        }

        this.previousSelectedCard = this.selectedCardDetailNumber;
        this.fetchMovements(this.selectedCard?.accountNumber, false, false);
        this.selectedCardDetailNumber = null;
    }



    handleShowCardMovementDetails(event){
        let dataRow = event.detail.row;
        this.selectedCardMovement = null;
        for (let currentMovement of this.recentCardMovements) {
            if(currentMovement.movementId === dataRow.movementId){
                this.selectedCardMovement = currentMovement;
                this.showCardMovementDetails = true;
                break;
            }
        }
    }

    toggleCardMovementDetailsPanel(event){
        this.showCardMovementDetails = !this.showCardMovementDetails;
    }


    handleReturnCards() {
        if (this.recentCardMovements) this.recentCardMovements = null;
        this.selectedCardDetailNumber = this.previousSelectedCard;
    }

    handlePrevioCards() {
        this.fetchMovements(this.selectedCard?.accountNumber, false, true);
    }

    handleSiguienteCards() {
        this.fetchMovements(this.selectedCard?.accountNumber, true, false);
    }

    addRemoveSelectedCustomBox(event) {
        const highlightedElement = this.template.querySelector('.custom-box-active');

        if (highlightedElement) highlightedElement.classList.remove('custom-box-active');
        const targetElement = event.currentTarget;
        targetElement.classList.add('custom-box-active');

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
                productType: 'CREDIT_CARDS',
                offset: this.currentOffSet,
                pageLimit: this.currentPageLimit,
                fromDate: this.fromDate,
                toDate: this.toDate,
                personCode: this.personCode
            });


            if (movementResult == null) {
                this.movementsFound = false;
                this.isLoading = false;
                this.showButtons();

                throw new Error('Return, no response');
            } else {


               let parsedResult = JSON.parse(movementResult);
               let mov = parsedResult?.movements || [];
               this.totalResults = mov.length;
               this.movementsFound = this.totalResults > 0 ? true : false;

               for (let movement of mov) {
                   if(movement.amount != null && movement.amount != undefined){
                       let decimalValue =  Number(movement.amount).toLocaleString('es-PY',{ minimumFractionDigits: 2 });
                       movement.amount = decimalValue;
                   }
               };

                this.recentCardMovements = null;
                this.recentCardMovements = mov;

            }

            this.isLoading = false;
            this.showButtons();
        }
        catch (error) {
            console.log('error');
            console.log(JSON.stringify(error));
            this.isLoading = false;
        }
    }

    //Date inputs
    onDateChange(event){
        if(event.target.name == 'fromDate'){
            if(event.detail.value < this.minDate){
                event.target.value = this.minDate;
            }else {
                this.fromDate = event.detail.value;
                this.maxDate = getFormattedDate(this.fromDate, -30) > this.todayDate ? this.todayDate : getFormattedDate(this.fromDate, -30);
            }
        } else if (event.target.name == 'toDate'){
                this.toDate = event.detail.value;
                this.minDate = getFormattedDate(this.toDate, 30);
        }

        this.currentOffSet = 0;
        this.fetchMovements(this.selectedCard?.accountNumber, false, false);
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
    let tempDate = (date instanceof Date) ? date : new Date(date);

    if (daysToSubtract) tempDate.setDate(tempDate.getDate() - daysToSubtract);
    if (monthsToSubtract) tempDate.setMonth(tempDate.getMonth() - monthsToSubtract);
    if (yearsToSubtract) tempDate.setFullYear(tempDate.getFullYear() - yearsToSubtract);

    return tempDate.toISOString().split('T')[0];
}