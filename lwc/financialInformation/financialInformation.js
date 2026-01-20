import { LightningElement, api, track } from 'lwc';
import getCompanyFinancialInfo from '@salesforce/apex/FinancialInformationController.getCompanyFinancialInfo';
import {onHandleSort, showSuccessMessage, showErrorMessage} from 'c/utils';


const columns = [
    { label: 'Concepto', fieldName: 'Concepto__c', type: 'string', hideDefaultActions: true},
    {label: 'Moneda',fieldName: 'Moneda__c',type: 'string', hideDefaultActions: true},
    { label: 'Monto', fieldName: 'Monto__c', type: 'number', hideDefaultActions: true, sortable: true, typeAttributes: { minimumFractionDigits: '2' }},
    { label: 'Fecha', fieldName: 'Fecha_de_la_Informacion__c', type: 'date', hideDefaultActions: true, sortable: true},
]

export default class FinancialInformation extends LightningElement {

    @track isLoading = false;
    @track showDetails = false;
    @track informationLoaded = false;
    @api recordId;
    financialInformation;
    numberOfRows = 4;
    columns = columns;
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy;

    connectedCallback(){
        this.isLoading = true;
        this.getCompanyFinancialInfoByAccountId();
    }


    getCompanyFinancialInfoByAccountId(){

        if(this.recordId != null && this.recordId != undefined && this.recordId != ''){

            getCompanyFinancialInfo({accountId : this.recordId})
            .then( result => {

                if(result != null && result.length > 0){

                    if(result.length <= this.numberOfRows){
                        this.financialInformation = result;

                    } else {
                        this.financialInformation = [ ...this.financialInformation, response ].slice(0,this.numberOfRows);
                    }
                 this.informationLoaded = true;
                }

                this.isLoading = false
            })
            .catch(error => {
                this.informationLoaded = false;
                this.isLoading = false;
                showErrorMessage('Error', error?.body?.message);
            })

        }
    }

    onHandleSort(event) {
            const { sortedData, sortDirection, sortedBy } = onHandleSort(event, this.financialInformation);
            this.financialInformation = sortedData;
            this.sortDirection = sortDirection;
            this.sortedBy = sortedBy;
    }

}