import { LightningElement, track, api } from 'lwc';
import getRefundHistory from '@salesforce/apex/RefundHistoryController.getRefundHistory';

export default class RefundHistory extends LightningElement {

    isLoading = false;
    @api recordId;
    @track refundHistory;
    @track searchString = "";
    @track filterRecords = [];
    @track dataLoaded = false;
    @track hideIconName = 'utility:down';
    @track isCardExpanded = false;
    @track showingInfoApi = false;


    connectedCallback() {
    }

    getRefundHistoryData() {
        getRefundHistory({accountId: this.recordId})
            .then(result => {

                if(result && result.length > 0){

                    this.refundHistory = result;
                    this.isLoading = false;
                    this.dataLoaded = true;

                } else {
                    this.dataLoaded = false;
                    this.isLoading = false;
                }

                this.filterHandler();
            })
            .catch(error => {
                this.error = error;
                this.isLoading = false;
            });

    }

    handleChange(event) {
        this.searchString = event.target.value;
        this.filterHandler();
    }

    filterHandler() {
        let normalizedSearchString;

        if (!isNaN(this.searchString)) {
            normalizedSearchString = this.searchString.toString().toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");
        } else {
            normalizedSearchString = this.searchString.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");
        }

        let records = this.refundHistory.filter(v => {
            const normalizedStore = v.store.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f"]/g, "");
            const normalizedAmount = v.amount.toString();

            return normalizedStore.includes(normalizedSearchString) || normalizedAmount.includes(normalizedSearchString);
        });

        this.filterRecords = records.length > 0 ? records : [];
    }

    handleClick(){
        if (this.isCardExpanded) {
            this.template.querySelector('.card-body').classList.add('slds-hide');
        } else {
            this.template.querySelector('.card-body').classList.remove('slds-hide');
            if(!this.showingInfoApi){
                this.isLoading = true;
                this.getRefundHistoryData();
                this.showingInfoApi = true;
            }
        }
        this.isCardExpanded = !this.isCardExpanded;

        if (this.isCardExpanded) {
            this.hideIconName = 'utility:up'
        } else {
            this.hideIconName = 'utility:down';
        }
    }


}