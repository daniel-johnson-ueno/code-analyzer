import { LightningElement, api, track } from 'lwc';
import findLoanOffers from '@salesforce/apex/LoanOffersController.findLoanOffers';
import findLoanRequests from '@salesforce/apex/LoanRequestsController.findLoanRequests';

export default class Acquisition extends LightningElement {
    @api recordId;

    // loan offers
    @track isLoandOffersLoading = false;
    @track loanOffersLoaded = false;
    @track loanOffers = [];

    // loan requests
    @track isLoandRequestsLoading = false;
    @track loanRequestsLoaded = false;
    @track loanRequests = [];

    @track hideIconName = 'utility:down';
    @track isCardExpanded = false;
    @track showingInfoApi = false;

    connectedCallback() {
    }

    getLoanOffers() {
        this.isLoandOffersLoading = true;

        findLoanOffers({ accountId: this.recordId })
            .then(result => {
                this.loanOffers = result;
                this.loanOffersLoaded = result && result.length > 0 ? true : false;
            })
            .catch(error => {
                console.log(error);
                this.loanOffersLoaded = false;
            })
            .finally(() => {
                this.isLoandOffersLoading = false;
            });
    }

    getLoanRequests() {
        this.isLoandRequestsLoading = true;

        findLoanRequests({ accountId: this.recordId })
            .then(result => {
                this.loanRequests = result;
                this.loanRequestsLoaded = result && result.length > 0 ? true : false;
            })
            .catch(error => {
                console.log(error);
                this.loanRequestsLoaded = false;
            })
            .finally(() => {
                this.isLoandRequestsLoading = false;
            });
    }

    get isLoading() {
        return this.isLoandOffersLoading || this.isLoandRequestsLoading;
    }

    handleClick(){
        if (this.isCardExpanded) {
            this.template.querySelector('.card-body').classList.add('slds-hide');
        } else {
            this.template.querySelector('.card-body').classList.remove('slds-hide');
            if(!this.showingInfoApi){
                this.getLoanOffers();
                this.getLoanRequests();
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