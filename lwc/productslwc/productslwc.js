import { LightningElement, track, api } from 'lwc';
import getAccount from '@salesforce/apex/ProductsController.getAccount';
import getProductJsonSavingsCallout from '@salesforce/apexContinuation/ProductsCalloutsServicesUtil.productJsonSavingsCallout';
import {showSuccessMessage, showErrorMessage} from 'c/utils';


export default class Productslwc extends LightningElement {
    @api recordId;
    @api producttype;
    @api personCode;
    @api isEmployee;

    @track showMovimientos = false;
    @track personCode = false;

    @api savingsResponse = [];
    @api checkingsResponse = [];
    @api cardsResponse = [];
    @api loansResponse = [];

    @track filteredSavings = [];
    @track filteredCheckings = [];
    @track filteredCards = [];
    @track filteredLoans = [];

    @track mockupData = true;

    @track isLoading = false;

    @track activeValues = ['normal', 'abierto', 'abierta', 'activo', 'activa', 'vigente'];
    @track neutralValues = ['bloqueado', 'bloqueada', 'proceso', 'bloqueado - usuario', 'recibida de adm.', 'bloqueado - adminis.'];
    @track errorValues = ['inactivo', 'inactiva', 'cancelado', 'cancelada', 'pendiente', 'baja', 'bajo'];

    @track errorMessage = null;
    @track hasErrors = false;

    @track checked = true;

    @track noResults = false;
    @track noResultsMessage = '';
    @track dataLoaded = false;

    @track isSavings = false;
    @track isCheckings = false;
    @track isCards = false;
    @track isLoans = false;

    async fetchData() {

        this.dataLoaded = false;
        this.isLoading = true;
        const accResult = await (getAccount({ recordId: this.recordId }));
        this.personCode = accResult?.PersonCode__c;
        this.isEmployee = accResult?.IsEmployee__c;
        const prodResult = await (getProductJsonSavingsCallout({ personCode: this.personCode, productType: this.producttype }))
        .catch(error =>{
            showErrorMessage('Error', error?.body?.message);
        });


        if (prodResult != null && JSON.parse(prodResult).length > 0 ) {
           switch (this.producttype) {
                       case 'SAVINGS':
                           this.savingsResponse = JSON.parse(prodResult);

                           if(this.savingsResponse != null){

                               this.savingsResponse.forEach(saving => {
                                   let statusLowerCase = saving.status.trim().toLowerCase();

                                   let isActive = false;
                                   let isNeutral = false;
                                   let isError = false;

                                   if(this.activeValues.includes(statusLowerCase)) isActive = true;
                                   if(this.neutralValues.includes(statusLowerCase)) isNeutral = true;
                                   if(this.errorValues.includes(statusLowerCase)) isError = true;

                                   saving.isActive = isActive;
                                   saving.isNeutral = isNeutral;
                                   saving.isError = isError;

                                   saving.denominationShort = saving.denomination.slice(-4);
                               });

                               this.dataLoaded = true;
                           }
                           this.isSavings = true;
                           console.log(this.savingsResponse)
                           break;

                       case 'CHECKINGS':
                           this.checkingsResponse = JSON.parse(prodResult);

                           if(this.checkingsResponse != null){

                               this.checkingsResponse.forEach(checking => {

                               let statusLowerCase = checking.status.trim().toLowerCase();

                               let isActive = false;
                               let isNeutral = false;
                               let isError = false;
                               if(this.activeValues.includes(statusLowerCase)) isActive = true;
                               if(this.neutralValues.includes(statusLowerCase)) isNeutral = true;
                               if(this.errorValues.includes(statusLowerCase)) isError = true;
                               checking.isActive = isActive;
                               checking.isNeutral = isNeutral;
                               checking.isError = isError;

                               checking.denominationShort = checking.denomination.slice(-4);
                               });

                               this.dataLoaded = true;
                           }
                           this.isCheckings = true;
                           break;

                       case 'CREDIT_CARDS,DEBIT_CARDS':
                           let cards = JSON.parse(prodResult).sort((a, b) => b.isCredit - a.isCredit);
                           let cardGroups = {
                               active: { credit: [], debit: [] },
                               neutral: { credit: [], debit: [] },
                               error: { credit: [], debit: [] }
                           };

                           if(cards != null){
                               cards.forEach(card => {
                                   let statusLowerCase = card.status.trim().toLowerCase();

                                   let group = 'active';
                                   let cardType = card.isCredit ? 'credit' : 'debit';

                                   card.isActive = false;
                                   card.isNeutral = false;
                                   card.isError = false;

                                   if (this.activeValues.includes(statusLowerCase)) {
                                       card.isActive = true;
                                   } else if (this.neutralValues.includes(statusLowerCase)) {
                                       card.isNeutral = true;
                                       group = 'neutral'
                                   } else if (this.errorValues.includes(statusLowerCase)) {
                                       card.isError = true;
                                       group = 'error'
                                   } else {
                                       card.isActive = true;
                                   }

                                   cardGroups[group][cardType].push(card);
                                   card.cardNumberShort = card.cardNumber.slice(-4);
                               });

                               this.cardsResponse = [...cardGroups.active.credit,
                                                   ...cardGroups.neutral.credit,
                                                   ...cardGroups.error.credit,
                                                   ...cardGroups.active.debit,
                                                   ...cardGroups.neutral.debit,
                                                   ...cardGroups.error.debit
                                                   ];
                               this.dataLoaded = true;
                           }
                           this.isCards = true;
                           break;

                       case 'LOANS':
                           this.loansResponse = JSON.parse(prodResult);

                           if(this.loansResponse != null){
                               this.loansResponse.forEach(loan => {

                                   let statusLowerCase = loan.status.trim().toLowerCase();

                                   let isActive = false;
                                   let isNeutral = false;
                                   let isError = false;
                                   if(this.activeValues.includes(statusLowerCase)) isActive = true;
                                   if(this.neutralValues.includes(statusLowerCase)) isNeutral = true;
                                   if(this.errorValues.includes(statusLowerCase)) isError = true;
                                   loan.isActive = isActive;
                                   loan.isNeutral = isNeutral;
                                   loan.isError = isError;
                               });

                               this.dataLoaded = true;
                           }

                           this.isLoans = true;

                           break;
                   }

                   if(this.dataLoaded){
                       this.onToggleChange();
                   }

                   this.isLoading = false;

        } else {

            this.isLoading = false;
            this.noResults = true;
            this.setNoResultMessage(this.producttype);

        }

    }

    connectedCallback() {
        this.fetchData();
    }

    handleToggleClicked(){
        this.checked = !this.checked;
        this.onToggleChange();
    }

    onToggleChange() {
        const currentProductType = this.producttype == 'CREDIT_CARDS,DEBIT_CARDS' ? 'CARDS' : this.producttype;

        const results = {
            SAVINGS: this.savingsResponse,
            CHECKINGS: this.checkingsResponse,
            CARDS: this.cardsResponse,
            LOANS: this.loansResponse
        };

        const isActiveFilter = result => result.isActive == true;

        if (this.checked) {
            this.updateFilteredProducts(currentProductType, results, isActiveFilter);
        } else {
            this.updateFilteredProducts(currentProductType, results);
        }
    }

    updateFilteredProducts(productType, results, filterFn) {
        const productMapping = {
            'SAVINGS': 'filteredSavings',
            'CHECKINGS': 'filteredCheckings',
            'CARDS': 'filteredCards',
            'LOANS': 'filteredLoans'
        };

        if (productMapping[productType]) {
            this[productMapping[productType]] = filterFn ? results[productType].filter(filterFn) : [...results[productType]];
        }
    }

    setNoResultMessage(productType){

        const noResultsMessagesMap = {
            'SAVINGS': 'No hay una caja de ahorro asociada a este cliente.',
            'CHECKINGS': 'No hay una cuenta corriente asociada a este cliente.',
            'CREDIT_CARDS,DEBIT_CARDS': 'No hay una tarjeta asociada a este cliente.',
            'DEBIT_CARDS,CREDIT_CARDS': 'No hay una tarjeta asociada a este cliente.',
            'LOANS': 'No hay un préstamo asociado a este cliente.'
        };

        this.noResultsMessage = noResultsMessagesMap[productType] || 'No se encontraron resultados';
    }
}