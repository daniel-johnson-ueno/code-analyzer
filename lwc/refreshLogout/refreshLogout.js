import { LightningElement } from 'lwc';
import callLog from '@salesforce/apex/LogoutExperience.generateDebugLog';
import refresh from '@salesforce/apex/LogoutExperience.getTimeCallApexLog';
export default class RefreshLogout extends LightningElement {
    refreshTime = 900000;
    connectedCallback() {

        refresh()
        .then(result => {
            console.log("refreshTime");
            this.refreshTime = parseInt(result)*60000;
            console.log(result);
        })
        .catch(error => {
            console.log(error);
        })
        .finally(() => {
                console.log("setInterval");
            setInterval(() => {
                this.callLogApex();
            }, this.refreshTime);
        })
    }
    callLogApex() {
        console.log('callLogApex INIT');
        callLog()
            .then(result => {
                console.log("callLog");
            })
            .catch(error => {
                console.log(error);
            })
    }
}