/**
 * @description       : 
 * @author            : marco.casanova@vurpix.com
 * @TKs               : 
 * @group             : 
 * @last modified on  : 06-13-2024
 * @last modified by  : marco.casanova@vurpix.com
**/
import { LightningElement, api, track } from 'lwc';
import getProductMovementCallout from '@salesforce/apexContinuation/ProductsMovementsCalloutsServicesUtil.productMovementCallout';

export default class SubproductsLWC extends LightningElement {
    @api producttype;
    @api personcode;
    @api isemployee;

    @api savingsresponse;
    @api checkingsresponse;
    @api cardsresponse;
    @api loansresponse;

    @track isSavings = false;
    @track isCheckings = false;
    @track isCards = false;
    @track isLoans = false;

    @track isloading = false;

    @track currentPageLimit = 20;
    @track currentOffset = 0;

    renderedCallback() {
        this.isloading = true;
        switch (this.producttype) {
            case 'SAVINGS':
                this.isSavings = true;
                console.log(this.savingsresponse);
                if (this.savingsresponse == null) {
                    return;
                }

                try {
                    this.savingsresponse = JSON.parse(this.savingsresponse);
                }
                catch (error) {
                    console.error('error', error);
                }
                break;
            case 'CHECKINGS':
                this.isCheckings = true;
                console.log(this.checkingsresponse);
                if (this.checkingsresponse == null) {
                    this.isloading = false;
                    return;
                }
                try {
                    this.checkingsresponse = JSON.parse(this.checkingsresponse);
                    this.isloading = false;

                }
                catch (error) {
                    console.error('error', error);
                }
                break;
            case 'CREDIT_CARDS,DEBIT_CARDS':
                this.isCards = true;
                console.log(this.cardsresponse);
                if (this.cardsresponse == null) {
                    this.isloading = false;
                    return;
                }
                try {
                    this.cardsresponse = JSON.parse(this.cardsresponse);
                    this.isloading = false;
                }
                catch (error) {
                    console.error('error', error);
                }
                break;
            case 'LOANS':
                this.isLoans = true;
                console.log(this.loansresponse);
                if (this.loansresponse == null) {
                    this.isloading = false;
                    return;
                }
                try {
                    this.loansresponse = JSON.parse(this.loansresponse);
                    this.isloading = false;
                }
                catch (error) {
                    console.error('error', error);
                }
                break;
        }
    }

    connectedCallback() {
        switch (this.producttype) {
            case 'SAVINGS':
                this.isSavings = true;
                break;
            case 'CHECKINGS':
                this.isCheckings = true;
                break;
            case 'CREDIT_CARDS,DEBIT_CARDS':
                this.isCards = true;
                break;
            case 'LOANS':
                this.isLoans = true;
                break;
        }
    }

    addRemoveSelectedCustomBox(event) {
        const highlightedElement = this.template.querySelector('.custom-box-active');

        if (highlightedElement) highlightedElement.classList.remove('custom-box-active');
        const targetElement = event.currentTarget;
        targetElement.classList.add('custom-box-active');
        this.movementsFound = true;

    }

    @track movementsFound = true;
    async fetchMovements(accountNumber, nextPage, previousPage) {
        this.isLoading = true;
        this.movementsFound = true;
        let productTypeCorrected = this.producttype;
        if (this.producttype == 'CREDIT_CARDS,DEBIT_CARDS') {
            productTypeCorrected = 'CREDIT_CARDS'
        }

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

            let movementResult = await getProductMovementCallout({ accountNumber: accountNumber, productType: productTypeCorrected, offset: this.currentOffSet, pageLimit: this.currentPageLimit });

            if (this.producttype == 'LOANS') {
                let mov = JSON.parse(movementResult).installments;

                if (mov == null){
                    console.log('NO MORE RESULTS');
                    this.movementsFound = false;
                    this.isLoading = false;
                    this.currentOffSet -= this.currentPageLimit;
                    console.log('return');
                    throw new Error('Return, no response');
                }
            }

            if (movementResult == null) {
                this.movementsFound = false;
                this.isLoading = false;
                throw new Error('Return, no response');

            } else {
                if (this.producttype == 'SAVINGS') {
                    let mov = JSON.parse(movementResult).movements;

                    for (let movement of mov) {
                        if(movement.amount != null && movement.amount != undefined){
                            let decimalValue =  Number(movement.amount).toLocaleString('es-PY',{ minimumFractionDigits: 2 });
                            movement.amount = decimalValue;
                        }
                    };

                    this.recentSavingMovements = null;
                    this.recentSavingMovements = mov;
                    console.log('SAVINGS:', this.recentSavingMovements);
                }

                if (this.producttype == 'LOANS') {
                    let mov = JSON.parse(movementResult).installments;

                    for (let movement of mov) {
                        if(movement.amount != null && movement.amount != undefined){
                            let decimalValue =  Number(movement.amount).toLocaleString('es-PY',{ minimumFractionDigits: 2 });
                            movement.amount = decimalValue;
                        }
                    };
                    this.recentLoanMovements = null;
                    this.recentLoanMovements = mov;
                    console.log('LOANS:', this.recentLoanMovements);
                }

                if (this.producttype == 'CHECKINGS') {
                    let mov = JSON.parse(movementResult).movements;

                    for (let movement of mov) {
                        if(movement.amount != null && movement.amount != undefined){
                            let decimalValue =  Number(movement.amount).toLocaleString('es-PY',{ minimumFractionDigits: 2 });
                            movement.amount = decimalValue;
                        }
                    };

                    this.recentCheckingMovements = null;
                    this.recentCheckingMovements = mov;
                    console.log('CHECKINGS:', this.recentCheckingMovements);
                }

                if (this.producttype == 'CREDIT_CARDS,DEBIT_CARDS') {
                    let mov = JSON.parse(movementResult).movements;
                    if (!mov) {
                        this.movementsFound = false;
                        this.isLoading = false;

                    } else {

                        for (let movement of mov) {
                            if(movement.amount != null && movement.amount != undefined){
                                let decimalValue =  Number(movement.amount).toLocaleString('es-PY',{ minimumFractionDigits: 2 });
                                movement.amount = decimalValue;
                            }
                        };
                        this.recentCardMovements = null;
                        this.recentCardMovements = mov;
                        console.log('CREDIT_CARDS:', this.recentCardMovements);
                    }
                }
            }
            this.isLoading = false;
        }
        catch (error) {
            console.log(JSON.stringify(error));
            this.isLoading = false;
        }
    }

    // Cards 
    @track selectedCard = null;
    @track selectedCardDetailNumber = null;
    @track selectedCardIsCredit = null;
    @track recentCardMovements = null;
    @track selectedCardMovement = null;
    @track showCardMovementDetails = false;

    handleCardClick(event) {
        this.addRemoveSelectedCustomBox(event);

        const selectedItem = event.currentTarget.dataset.cardNumber;
        this.recentCardMovements = null;
        this.movementsFound = true;
        this.selectedCardDetailNumber = selectedItem;

        for (const card of this.cardsresponse) {
            if (card.cardNumber === selectedItem) {
                this.selectedCardIsCredit = card.isCredit
                this.selectedCard = card.moreDetails;
                break;
            }
        }
    }

    @track previousSelectedCard = null;

    handleMovementsCards() {
        console.log(JSON.stringify(this.recentCardMovements));
        console.log(this.recentCardMovements == true);
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
            if(currentMovement.movementId == dataRow.movementId){
                console.log('see amount: ' + dataRow.amount);
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

    // Loans
    @track selectedLoan = null;
    @track selectedLoanDetailNumber = null;
    @track recentLoanMovements = null;
    @track selectedLoanMovement = null;
    @track showLoanMovementDetails = false;

    handleLoanClick(event) {
        this.addRemoveSelectedCustomBox(event);
        const selectedItem = event.currentTarget.dataset.accountNumber;
        this.selectedLoanDetailNumber = selectedItem;
        this.recentLoanMovements = null;

        for (const loan of this.loansresponse) {
            if (loan.accountNumber === selectedItem) {
                this.selectedLoan = loan.moreDetails;
                break;
            }
        }
    }
    @track previousSelectedLoan = null;

    handleShowLoanMovementDetails(event){
        let dataRow = event.detail.row;

        this.selectedLoanMovement = null;
        for (let currentMovement of this.recentLoanMovements) {
            if(currentMovement.installmentId == dataRow.installmentId){
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

    // Checking
    @track selectedChecking = null;
    @track selectedCheckingDetailNumber = null;
    @track recentCheckingMovements = null;
    @track detailsCheckingSelected = false;
    @track signatoriesCheckingSelected = false;
    @track recentCheckingMovementsSelected = false;
    @track selectedCheckingMovement = null;
    @track showCheckingMovementDetails = false;

    handleCheckingClick(event) {
        this.addRemoveSelectedCustomBox(event);
        const selectedItem = event.currentTarget.dataset.accountNumber;
        this.selectedCheckingDetailNumber = selectedItem;
        this.recentCheckingMovements = null;
        this.signatoriesCheckingSelected = false;
        this.recentCheckingMovementsSelected = false;

        for (const checking of this.checkingsresponse) {
            if (checking.accountNumber === selectedItem) {
                this.selectedChecking = checking.moreDetails;
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

    @track previousSelectedChecking = null;

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
        this.movementsFound = true;

    }

    handlePrevioCheckings() {
        this.fetchMovements(this.selectedCheckingDetailNumber, false, true);

        this.movementsFound = true;
    }

    handleSiguienteCheckings() {
        this.fetchMovements(this.selectedCheckingDetailNumber, true, false);

        this.movementsFound = true;
    }

    handleSignatoriesChecking(){
        if (this.recentCheckingMovements) this.recentCheckingMovements = null;

        this.detailsCheckingSelected = false;
        this.signatoriesCheckingSelected = true;
        this.recentCheckingMovementsSelected = false;
        this.movementsFound = true;
    }
    

    // Savings
    @track selectedSaving = null;
    @track selectedSavingDetailNumber = null;
    @track recentSavingMovements = null;
    @track detailsSavingSelected = false;
    @track signatoriesSavingSelected = false;
    @track recentSavingMovementsSelected = false;
    @track selectedSavingMovement = null;
    @track showSavingMovementDetails = false;

    handleSavingClick(event) {
        console.log('click');
        this.addRemoveSelectedCustomBox(event);
        const selectedItem = event.currentTarget.dataset.accountNumber;
        console.log('selectedItem');
        console.log(selectedItem);
        this.selectedSavingDetailNumber = selectedItem;
        this.recentSavingMovements = null;
        this.signatoriesSavingSelected = false;
        this.recentSavingMovementsSelected = false;

        for (const saving of this.savingsresponse) {
            if (saving.accountNumber == selectedItem) {
                this.selectedSaving = saving.moreDetails;
                break;
            }
        }

        this.detailsSavingSelected = true;
    }

    handleShowSavingMovementDetails(event){
        let dataRow = event.detail.row;

        this.selectedSavingMovement = null;
        for (let currentMovement of this.recentSavingMovements) {
            if(currentMovement.movementId == dataRow.movementId){
                console.log('see amount: ' + dataRow.amount);
                this.selectedSavingMovement = currentMovement;
                this.showSavingMovementDetails = true;
                break;
            }
        }
    }

    toggleSavingMovementDetailsPanel(event){
        this.showSavingMovementDetails = !this.showSavingMovementDetails;
    }

    genericMovementColumns = [
        { label: 'Mostrar', fieldName: '', initialWidth: 70, type: 'button-icon',
            typeAttributes: { iconName: 'action:preview', title: 'View', variant: 'bare', alternativeText: 'View'}
        },
        { label: 'Tipo Movimiento', fieldName: 'movementType', hideDefaultActions: true },
        { label: 'Fecha Movimiento', fieldName: 'movementDate', hideDefaultActions: true },
        { label: 'Monto', fieldName: 'amount', type:'decimal', hideDefaultActions: true, cellAttributes: { alignment: 'right' }},
    ];

//    genericMovementColumns = [
//        { label: 'Descripcion', fieldName: 'description',hideDefaultActions: true, initialWidth: 350 },,
//        { label: 'Monto', fieldName: 'amount', type:'decimal', hideDefaultActions: true, initialWidth: 150, cellAttributes: { alignment: 'right' }},
//    ];

    savingMovementColumns = [
        { label: 'Mostrar', fieldName: '', initialWidth: 70, type: 'button-icon',
            typeAttributes: { iconName: 'action:preview', title: 'View', variant: 'bare', alternativeText: 'View'}
        },
        { label: 'Tipo Movimiento', fieldName: 'movementType', hideDefaultActions: true},
        { label: 'Fecha Movimiento', fieldName: 'movementDate', hideDefaultActions: true},
        { label: 'Monto', fieldName: 'amount', type:'decimal', hideDefaultActions: true, cellAttributes: { alignment: 'right' }},
    ];

    loanColumns = [
        { label: 'Mostrar', fieldName: '', initialWidth: 70, type: 'button-icon',
            typeAttributes: { iconName: 'action:preview', title: 'View', variant: 'bare', alternativeText: 'View'}
        },
        { label: 'Numero de Cuota', fieldName: 'installmentNumber', hideDefaultActions: true},
        { label: 'Fecha Expiracion', fieldName: 'expirationDate', hideDefaultActions: true},
        { label: 'Cantidad', fieldName: 'amount', type:'decimal', hideDefaultActions: true},
    ];

    @track previousSelectedSaving = null;


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
        this.movementsFound = true; //se puede mejorar
    }


    handlePrevioSavings() {
        this.fetchMovements(this.selectedSavingDetailNumber, false, true);

        this.movementsFound = true;
    }

    handleSiguienteSavings() {
        this.fetchMovements(this.selectedSavingDetailNumber, true, false);
        this.movementsFound = true;
    }

    handleSignatoriesSavings(){
        if (this.recentSavingMovements) this.recentSavingMovements = null;
        this.detailsSavingSelected = false;
        this.recentSavingMovementsSelected = false;
        this.signatoriesSavingSelected = true;
    }


}