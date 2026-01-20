import { LightningElement, track, api, wire } from 'lwc';

import benefitsCallout from '@salesforce/apex/BenefitsController.benefitsCallout';
import benefitsCalloutFromCase from '@salesforce/apex/BenefitsController.benefitsCalloutFromCase';

import { CurrentPageReference } from 'lightning/navigation';
import {Paginator} from "c/paginator";
import {formatDateISO, formatDateReadble, showToastMessage, substractToDate} from "c/utils";

//fechas para hacer el callout y setear los inputs al comienzo.
const LIMIT_FROM_DATE_HISTORY_POINTS = formatDateISO(substractToDate(new Date(), 0, 0, 1));
const LIMIT_FROM_DATE_HISTORY_LEVEL = formatDateISO(substractToDate(new Date(), 0, 0, 1));

const PAGE_SIZE = 20;

export default class SubproductBenefits extends LightningElement {
    @api recordId;
    @track isLoading = false;
    @track inputFromDate = '';
    @track inputUntilDate = '';
    @track isDateFilterNeeded = true;
    @track loyaltyData = [];
    @track productSelected = '';
    @track showNext = false;
    @track showBack = false;
    @track showPaginator = false;
    @track isCaseRecord = false;
    @track paginator = null;
    @track columns = [];

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

    //Buttons
    get options() {
        return [
            { label: 'Historial nivel', value: 'historyLevel' },
            { label: 'Historial puntos', value: 'historyPoints' },
            { label: 'Resumen de Upys', value: 'upysSummary' }
        ];
    }

    get isHistoryLevelSelected() {
        return this.productSelected === 'historyLevel';
    }

    get isHistoryPointsSelected() {
        return this.productSelected === 'historyPoints';
    }

    get isUpysSummarySelected() {
        return this.productSelected === 'upysSummary';
    }

    get noProductsLoaded() {
        return this.loyaltyData.length === 0;
    }

    handleSelectionChange(event){
        this.isLoading = true;
        this.isDateFilterNeeded = true;
        this.productSelected = event.detail.value;
        this.inputUntilDate = formatDateISO(new Date());
        switch (this.productSelected) {
            case 'historyPoints':
                this.columns = this.getHisporyPointsColumns();
                this.inputFromDate = formatDateISO(substractToDate(new Date(), 0, 1));
                break;
            case 'historyLevel':
                this.inputFromDate = formatDateISO(substractToDate(new Date(), 0, 4));
                break;
            case 'upysSummary':
                this.isDateFilterNeeded = false;
                this.columns = this.getHisporyUpysColumns();
                this.inputFromDate = null;
                this.inputUntilDate = null;
                break;
            default:
                showToastMessage('Error','No se ha seleccionado un producto válido. Por favor contactese con el administrador.', 'error', 'dismissable', this);
        }        

        if(this.isCaseRecord){
            this.calloutLoyaltyServiceFromCase();
        } else {
            this.calloutLoyaltyService();
        }
    }

    //Handle button click
    calloutLoyaltyService(){
        this.isLoading = true;
        benefitsCallout({ accountId: this.recordId, selectedProduct: this.productSelected, fromDate: this.inputFromDate, untilDate: this.inputUntilDate })
          .then(result => {
              if (result) {
                  this.paginator = new Paginator(result.reverse(), PAGE_SIZE);
                  this.loyaltyData = this.paginator.getPage(1);
                  this.refreshPaginator();
              }
          })
          .catch(error => {
              console.error(error);
          })
          .finally(() => {
              this.isLoading = false;
          });
    }

    calloutLoyaltyServiceFromCase(){
        benefitsCalloutFromCase({ caseId: this.recordId, selectedProduct: this.productSelected, fromDate: this.inputFromDate, untilDate: this.inputUntilDate })
          .then(result => {
              if (result) {
                  this.paginator = new Paginator(result.reverse(), PAGE_SIZE);
                  this.loyaltyData = this.paginator.getPage(1);
                  this.refreshPaginator();
              }
          })
          .catch(error => {
              console.error(error);
          })
          .finally(() => {
              this.isLoading = false;
          });
    }

    //Date inputs
    onFromDateChange(event){
        switch (this.productSelected) {
            case 'historyPoints':
                if (event.detail.value < LIMIT_FROM_DATE_HISTORY_POINTS) {
                    showToastMessage('Atención','Fecha Inicio debe ser posterior a ' + formatDateReadble(new Date(LIMIT_FROM_DATE_HISTORY_POINTS)), 'warning', 'dismissable', this);
                    return;
                }

                break;
            case 'historyLevel':
                if (event.detail.value < LIMIT_FROM_DATE_HISTORY_LEVEL) {
                    showToastMessage('Atención','Fecha Inicio debe ser posterior a ' + formatDateReadble(new Date(LIMIT_FROM_DATE_HISTORY_LEVEL)), 'warning', 'dismissable', this);
                    return;
                }

                break;
            default:
                showToastMessage('Error','No se ha seleccionado un producto válido. Por favor contactese con el administrador.', 'error', 'dismissable', this);
                return;
        }

        this.inputFromDate = event.detail.value;
        this.calloutLoyaltyService();
    }

    onUntilDateChange(event){
        if (event.detail.value <= this.inputFromDate) {
            showToastMessage('Atención','Fecha Fin debe ser posterior a ' + formatDateReadble(new Date(this.inputFromDate)), 'warning', 'dismissable', this);
            return;
        }

        this.inputUntilDate = event.detail.value;

        this.calloutLoyaltyService();
    }

    //Pagination methods
    refreshPaginator() {
        if (this.paginator.getTotalPages() > 1) {
            this.showPaginator = true;
            this.showBack = this.paginator.hasPrevPage();
            this.showNext = this.paginator.hasNextPage();
        } else {
            this.showPaginator = false;
        }
    }

    onPreviousClick(event){
        this.loyaltyData = this.paginator.prevPage();
        this.refreshPaginator();
    }

    onNextClick(event){
        this.loyaltyData = this.paginator.nextPage();
        this.refreshPaginator();
    }

    getHisporyPointsColumns() {
        return [
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
    }

    getHisporyUpysColumns() {
        return [
            { label: 'Descripción del evento', fieldName: 'name', hideDefaultActions: true },
            { label: 'Última actualización de puntos', fieldName: 'lastEventDate', hideDefaultActions: true },
            {
                label: 'Puntos del usuario',
                fieldName: 'points',
                hideDefaultActions: true,
                cellAttributes: {
                    class: { fieldName: 'pointsClass' }
                }
            },
            {
                label: 'Puntos límite del evento',
                fieldName: 'pointsToLimitEvent',
                hideDefaultActions: true,
                cellAttributes: { alignment: 'left' }
            }
        ];
    }
}