import { LightningElement, api, track } from 'lwc';
import retrieveCluster from '@salesforce/apex/ClusterInformationController.clusterCallout';

export default class ClusterInformation extends LightningElement {
    @api recordId;
    @track isLoading = false;
    @track clusterInfo;
    @track dataExist = false;
    @track hasError = false;
    @track errorInfo = '';
    @track hideIconName = 'utility:down';
    @track isCardExpanded = false;
    @track showingInfoApi = false;

    connectedCallback() {
    }

    fetchData(){
        this.isLoading = true;
        retrieveCluster({
            recordId: this.recordId,
        })
            .then(result => {
                if(!result.hasError){
                    this.dataExist = true;
                    this.clusterInfo = result.cluster;
                } else {
                    this.dataExist = false;
                    this.errorInfo = result.errorMessage;
                }
                this.isLoading = false;
            })
            .catch((error) => {
                this.dataExist = false;
                this.errorInfo = error?.body?.message;
                this.isLoading = false;
            });
    }

    handleClick(){
        if (this.isCardExpanded) {
            this.template.querySelector('.card-body').classList.add('slds-hide');
        } else {
            this.template.querySelector('.card-body').classList.remove('slds-hide');
            if(!this.showingInfoApi){
                this.fetchData();
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