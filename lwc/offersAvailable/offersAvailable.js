import { LightningElement, track, api } from 'lwc';
import offersAvailableCallout from '@salesforce/apex/OffersAvailableController.offersAvailableCallout';
export default class OffersAvailable extends LightningElement {

    @api recordId;
    @track isLoading = false;
    @track dataLoaded = false;
    @track selectedProduct = 'LOAN';
    @track offersAvailableProducts = [];
    @track hideIconName = 'utility:down';
    @track isCardExpanded = false;
    @track showingInfoApi = false;


    connectedCallback() {
    }

    getData(){

        offersAvailableCallout({accountId: this.recordId})
        .then( result => {
            if(result != null){

                this.offersAvailableProducts = result;

                this.dataLoaded = this.offersAvailableProducts.length > 0 ? true : false;

            } else {
                console.log('else')
                this.dataLoaded = false;
            }
        })
        .catch(error => {
            console.log(error);
            this.dataLoaded = false;
        })
        .finally(() => {
            this.isLoading = false;
        })


    }

    handleClick(){
        if (this.isCardExpanded) {
            this.template.querySelector('.card-body').classList.add('slds-hide');
        } else {
            this.template.querySelector('.card-body').classList.remove('slds-hide');
            if(!this.showingInfoApi){
                this.isLoading = true;
                this.getData();
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