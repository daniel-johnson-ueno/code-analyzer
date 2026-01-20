import { LightningElement, api, wire, track } from 'lwc';
import getActionPlansWithSLA from '@salesforce/apex/SLAActionPlanController.getActionPlansWithSLA';
import getOpportunitySLA from '@salesforce/apex/SLAActionPlanController.getOpportunitySLA';

export default class SlaActionPlan extends LightningElement {
    @api recordId;
    @track actionPlans = [];
    @track opportunitySLA;
    @track showComponent = false;
    @track loading = true;

    @wire(getActionPlansWithSLA, { opportunityId: '$recordId' })
    wiredActionPlans({ error, data }) {
        this.loading = false;
        if (data && data.length > 0) {
            this.showComponent = true;

            this.actionPlans = data.map(plan => {
                const isExpired = plan.isExpired;
                const timeElapsedStr = this.convertSecondsToTimeBHString(plan.elapsedSeconds);
                const slaTargetStr = this.convertSecondsToTimeString(plan.slaSeconds);
                const slaProgress = Math.min((plan.elapsedSeconds / plan.slaSeconds) * 100, 100);
                // const slaTargetHours = Math.floor(plan.slaSeconds / 86400) + 'd'; // convertimos a días
                const slaTargetHours = plan.slaDays + 'd';
                const slaStatus = isExpired ? 'Fuera de tiempo' : 'En tiempo';
                const slaStatusClass = isExpired ? 'sla-badge-expired' : 'sla-badge-on-time';

                // Estilos
                const progressCircleStyle = this.getProgressCircleStyle(isExpired, slaProgress);
                const timeElapsedStyle = this.getTimeElapsedStyle(isExpired);

                return {
                    ...plan,
                    slaStatus,
                    slaStatusClass,
                    badgeClass: isExpired ? 'slds-badge slds-theme_error' : 'slds-badge slds-theme_success',
                    badgeBorderClass: isExpired ? 'error-border' : 'success-border',
                    timeElapsedStr,
                    slaTargetStr,
                    slaProgress,
                    slaTargetHours,
                    progressCircleStyle, 
                    timeElapsedStyle,
                    isExpired
                };
            });
        } else {
            this.actionPlans = [];
            this.showComponent = false;
        }

        if (error) {
            console.error('Error al obtener el SLA:', error);
        }
    }

    @wire(getOpportunitySLA, { opportunityId: '$recordId' })
    wiredOpportunitySLA({ error, data }) {
        if (data) {
            const isExpired = data.isExpired;
            const timeElapsedStr = this.convertSecondsToTimeString(data.elapsedSeconds);
            const slaTargetStr = this.convertSecondsToTimeString(data.slaSeconds);
            const slaProgress = Math.min((data.elapsedSeconds / data.slaSeconds) * 100, 100);
            const slaTargetHours = Math.floor(data.slaSeconds / 86400) + 'd'; // convertimos a días
            const slaStatus = isExpired ? 'Fuera de tiempo' : 'En tiempo';
            const slaStatusClass = isExpired ? 'sla-badge-expired' : 'sla-badge-on-time';

            // Estilos
            const progressCircleStyle = this.getProgressCircleStyle(isExpired, slaProgress);
            const timeElapsedStyle = this.getTimeElapsedStyle(isExpired);

            this.opportunitySLA = {
                slaStatus,
                slaStatusClass,
                timeElapsedStr,
                slaTargetStr,
                slaProgress,
                slaTargetHours,
                progressCircleStyle, 
                timeElapsedStyle,
                isExpired
            };
        } else if (error) {
            console.error('Error al obtener SLA de oportunidad:', error);
        }
    }

    convertSecondsToTimeString(seconds) {
        const days = Math.floor(seconds / 86400);
        const hours = Math.floor((seconds % 86400) / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);

        if (days > 0) {
            return `${days} día(s) ${hours}h`;
        } else {
            return `${hours}h ${minutes}m`;
        }
    }

    convertSecondsToTimeBHString(seconds) {
        const days = Math.floor(seconds / 36000);
        const hours = Math.floor((seconds % 36000) / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);

        if (days > 0) {
            return `${days} día(s) ${hours}h`;
        } else {
            return `${hours}h ${minutes}m`;
        }
    }

    // Método para obtener el estilo de progreso del círculo
    getProgressCircleStyle(isExpired, progress) {
        const color = isExpired ? '#a5284d' : '#4caf50';
        const percentage = Math.min(progress, 100);
    
        return `background: conic-gradient(${color} ${percentage}%, #ccc ${percentage}%);`;
    }

    // Método para obtener el estilo del tiempo transcurrido
    getTimeElapsedStyle(isExpired) {
        const color = isExpired ? '#a5284d' : '#4caf50';
        return `color: ${color};`;
    }
}