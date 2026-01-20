import { LightningElement, track, api, wire } from 'lwc';
import calculateSecondsDifferenceInStage from '@salesforce/apex/CalculateHoursByState.calculateSecondsDifferenceInStage';
import itIsWorkingHours from '@salesforce/apex/CalculateHoursByState.itIsWorkingHours';

export default class StatusSla extends LightningElement {
    @api state;
    radius = 40;
    circumference = 2 * Math.PI * this.radius;
    loadingData = false;
    errorDataRequest = false;
    slaPercentageElapsed = 60;
    minutes = 0;
    hours = 0;
    isItWorkingHours = false;

    @api actualSavedTimeInTheStatus;
    @api caseStatus;
    @api dateTimeLastStatusChange;
    @api establishedSlaInHours;
    @api establishedSlaInSeconds;

    @track formattedTime = '00:00';
    @track showComponent = false;
    @track totalSecondsInTheStatus = 0;

    get circleProgressEscalated() {
        let percentageToShow = this.slaPercentageToShow;
        const offset = this.circumference - (this.circumference * percentageToShow) / 100;
        let circleStyle = `stroke-dashoffset: ${offset};`;
        if (percentageToShow < 80) circleStyle += `stroke:#196944;`
        else {
            if (percentageToShow == 100) circleStyle += `stroke:#ff2f2f`;
            else circleStyle += `stroke:#b09429;`
        }
        return circleStyle;
    }

    get haveToRequestDifferenceInStatus() {
        return this.state == this.caseStatus;
    }

    get slaPercentageToShow() {
        return this.slaPercentageElapsed >= 100 ? 100 : this.slaPercentageElapsed;
    }

    get getColorClassSwitchPercentage() {
        let percentageToShow = this.slaPercentageToShow;
        if (percentageToShow < 80) return "correct-sla"
        else {
            if (percentageToShow == 100) return "incorrect-sla";
            else return "hurry-sla";
        }
    }

    get elapsedTimeIsOnTime() {
        return this.totalSecondsInTheStatus < this.establishedSlaInSeconds;
    }

    get loadingOrError(){
        return this.loadingData || this.errorDataRequest;
    }

    get loadedAndError(){
        return !this.loadingData&&this.errorDataRequest;
    }

    connectedCallback() {
    }

    disconnectedCallback(){
        this.stopTimer();
    }

    calculatePercentagesAndPrepareTimeToShow() {
        this.slaPercentageElapsed = (this.totalSecondsInTheStatus / this.establishedSlaInSeconds) * 100 || 1;
        this.hours = Math.floor(this.totalSecondsInTheStatus / 3600);
        this.minutes = Math.floor((this.totalSecondsInTheStatus % 3600) / 60);
        this.formattedTime = `${this.pad(this.hours)} h ${this.pad(this.minutes)} min`;
    }


    handleStatusChange() {
        this.loadingData = false;
        this.showComponent = true;
        this.updateTimer();
    }

    async updateTimer() {
        let secondsDifferenceBetweenLastModificationAndToday = 0;
        this.isItWorkingHours = false;
        if (this.haveToRequestDifferenceInStatus) {
            this.loadingData=true;
            try {
                secondsDifferenceBetweenLastModificationAndToday = await calculateSecondsDifferenceInStage({ caseDateTimeLastStatusChange: this.dateTimeLastStatusChange });
                this.isItWorkingHours = await itIsWorkingHours();
                this.formatTime(secondsDifferenceBetweenLastModificationAndToday);
            }
            catch (exception) {
                this.errorDataRequest = true;
                console.log("ERROR", exception.message);
            }
            finally {
                this.loadingData = false;
            }
        }
        else {
            this.formatTime(secondsDifferenceBetweenLastModificationAndToday);
        }
    }

    formatTime(diffSecondsHours) {
        this.totalSecondsInTheStatus = this.actualSavedTimeInTheStatus;
        this.totalSecondsInTheStatus += diffSecondsHours;
        this.calculatePercentagesAndPrepareTimeToShow();
        if (this.isItWorkingHours) {
            this.startTimer();
        }
    }

    startTimer() {
        this.intervalId = setInterval(() => {
            this.incrementTime();
        }, 60000);
    }

    stopTimer() {
        clearInterval(this.intervalId);
    }

    incrementTime() {
        this.totalSecondsInTheStatus += 60;
        this.calculatePercentagesAndPrepareTimeToShow();
    }

    pad(num) {
        return num < 10 ? `0${num}` : num;
    }

    handleRefresh() {
        this.handleStatusChange();
    }

    @api
    set updateStatus(newStatus) {
        this.stopTimer();
        this.handleStatusChange();
    }

    get updateStatus() {
        console.log("getter");
    }
}