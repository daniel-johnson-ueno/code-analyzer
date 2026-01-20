import { LightningElement, api, track } from 'lwc';
import retrieveVoteCount from '@salesforce/apex/KnowledgeArticleCalificationController.retrieveVoteCount';
import {showSuccessMessage, showErrorMessage} from 'c/utils';

export default class KnowledgeArticleCalification extends LightningElement {
    @api recordId;
    @api producttype;
    @api personCode;
    @api isEmployee;

    @track voteUp = 0;
    @track voteDown = 0;

    connectedCallback() {
        this.fetchData();
    }

    fetchData(){
        retrieveVoteCount({
            recordId: this.recordId,
        })
            .then(result => {
                this.voteUp = result.voteUp;
                this.voteDown = result.voteDown;
            })
            .catch((error) => {
                showErrorMessage('Error', error?.body?.message);
            });
    }


}