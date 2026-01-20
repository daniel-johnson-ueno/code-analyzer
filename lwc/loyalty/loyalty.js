import { LightningElement, track, api } from 'lwc';
import ChartJS from '@salesforce/resourceUrl/ChartJs';
import {loadScript} from 'lightning/platformResourceLoader';
import loyaltyCallout from '@salesforce/apex/LoyaltyController.loyaltyCallout';
import {showSuccessMessage, showErrorMessage} from 'c/utils';


export default class Loyalty extends LightningElement {

@api recordId;
@track isChartJsInitialized = false;
@track loyaltyData;
@track userLevel;
@track userPoints;
@track loyaltyLoaded = false;
@track isLoading = false;
@track hasError = false;
@track errorMessage = '';

connectedCallback(){
    this.initializeChart();
    this.getLoyaltyData();

    console.log('Conected')
}

renderedCallback(){
    if(this.loyaltyLoaded && this.isChartJsInitialized){
        console.log('renderizado')
        this.initializePieChart();
    }

}



    initializeChart() {

        Promise.all([loadScript(this, ChartJS)])
        .then(() => {
            this.isChartJsInitialized = true;
        })
        .catch(error => {
            showErrorMessage('Error', error?.body?.message);
        });
    }

    getLoyaltyData(){
        this.isLoading = true
        loyaltyCallout({accountId : this.recordId})
        .then( response => {

            this.loyaltyData = response;

            if(this.loyaltyData.hasError){
                this.hasError = true;
                this.errorMessage = this.loyaltyData.errorMessage;
            } else {
                this.hasError = false;
                this.errorMessage = '';

                this.userPoints = this.loyaltyData.balance;
                this.userLevel = this.loyaltyData.tier.level;
                this.loyaltyLoaded = true;
            }

            this.isLoading = false

        })
        .catch( error => {

            showErrorMessage('Error', error?.body?.message);
            this.loyaltyLoaded = false;
            this.isLoading = false
        })

    }

    initializePieChart() {
            console.log('cargando chart')
            const ctx = this.template.querySelector('canvas.barChart').getContext('2d');
            let points = this.loyaltyData.balance - this.loyaltyData.tier.minimumPoints;
            let maximum = this.loyaltyData.tier.maximumPoints - this.loyaltyData.tier.minimumPoints;
            let level = String(this.loyaltyData.tier.level);

            new window.Chart(ctx, {
                type: 'doughnut',
                data: {
                    labels: ['', ''],
                    datasets: [{
                        label: '',
                        backgroundColor: ['#0059BF'],
                        data: [points , (maximum - points)],
                    }]
                },

                plugins: [{
                    beforeDraw: function(chart) {
                        var width = chart.chart.width,
                        height = chart.chart.height,
                        ctx = chart.chart.ctx;

                        ctx.restore();
                        var fontSize = (height / 30).toFixed(2);
                        ctx.font = fontSize + "em Helvetica";
                        ctx.fillStyle = "#252529";
                        ctx.textBaseline = "middle";

                        var text = level,
                        textX = Math.round((width - ctx.measureText(text).width) / 2),
                        textY = height / 2;

                        ctx.fillText(text, textX, textY);
                        ctx.save();
                    }
                }],

                options: {
                    maintainAspectRatio: false,
                    cutoutPercentage: 75,
                    legend: {
                        display: false,
                    },
                    tooltips: {
                        enabled: false,

                    }
                }


            });

    }
}