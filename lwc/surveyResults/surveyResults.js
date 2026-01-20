import { LightningElement, api, track, wire } from 'lwc';
import { IsConsoleNavigation, getFocusedTabInfo, closeTab, getTabInfo, openSubtab, EnclosingTabId} from 'lightning/platformWorkspaceApi';
import {showSuccessMessage, showErrorMessage} from 'c/utils';

import getSurveysResults from '@salesforce/apex/SurveyResultsController.getSurveysResults';

export default class SurveyResults extends LightningElement {

    @api recordId;
    @track isLoading = false;
    @track surveyResults;
    @track parentTabId;
    @track hideIconName = 'utility:down';
    @track isCardExpanded = false;
    @track showingInfoApi = false;

    @wire(IsConsoleNavigation) isConsoleNavigation;

    connectedCallback(){
    }

    retrieveSurveysData(){
        getSurveysResults({accountId: this.recordId})
        .then((result) => {
            if(result.length > 0){
                this.surveyResults = result;
            }
            console.log(result);
        })
        .catch(error => {
            console.log(error);
            showErrorMessage('Error', error?.body?.message);

        })
        .finally(() => {
            this.isLoading = false;
        })
    }



    handleRedirect(event) {

        const surveyId = event.target.dataset.id;

        this.navigateToSubtab(surveyId, null);

    }

    onClickShowAll(){

        const relatedSurvey = `/lightning/r/Account/${this.recordId}/related/Encuestas__r/view`;

        this.navigateToSubtab(null, relatedSurvey);
    }

    async getConsoleTabsInfo() {
            const currentTabInfo =  await getFocusedTabInfo();

            if(currentTabInfo.isSubtab){
                const primaryTabInfo = await getTabInfo(currentTabInfo.parentTabId);
                this.parentTabId = primaryTabInfo.tabId;
            } else {
                this.parentTabId = currentTabInfo.tabId;
            }

    }

     async navigateToSubtab(surveyId, url) {
         await openSubtab(this.parentTabId, { recordId: surveyId, focus: true, url: url });
     }

     handleClick(){
        if (this.isCardExpanded) {
            this.template.querySelector('.card-body').classList.add('slds-hide');
        } else {
            this.template.querySelector('.card-body').classList.remove('slds-hide');
            if(!this.showingInfoApi){
                this.isLoading = true;
                this.retrieveSurveysData();
                this.getConsoleTabsInfo();
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