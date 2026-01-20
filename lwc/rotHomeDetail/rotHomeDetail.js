/**
 * @name               : rotHomeDetail
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 08-01-2025
 * @modification date  : 22-03-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : 
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   13-01-2025   Alvaro Gonzales Lapponi   Initial Version
**/
import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import recognizeClient from '@salesforce/apex/rotHomeController.recognizeClient';
import ICONS from '@salesforce/resourceUrl/rotIcons';

const QUERY_PARAMS_HOME = []; //Se agregan todos los query params a analizar como elementos

export default class RotHomeDetail extends NavigationMixin(LightningElement) {

    icons = {
        headphones: `${ICONS}/rotIcons/headphones.png`
    };
    queryParamsResult;
    @track queryParams = {};

    queryParams = QUERY_PARAMS_HOME;

    @track pantallas = {
        advertisementCall: true,
        requireClearFace: false
    };

    /**
     * @description 
     * @param {*} event 
     */
    handleUrlAnalized(event){
        this.queryParamsResult = event.detail.params;
    }

    /**
     * @description
     */
    handleAskCall(){
        this.chooseScreen('requireClearFace');
        this.displayHeaderElements(true,false);
    }

    async handleClientInfo(event){
        localStorage.setItem('tempImage', event.detail.base64Image);
        const queryParams = await this.fetchClientInformation(event.detail.base64Image.split('base64,')[1]);

        if(queryParams){
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    name: 'videollamadaSolicitud__c'
                },
                state: queryParams
            });
        } else{
            console.log('no se encontró cliente');
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    name: 'videollamadaSolicitud__c'
                }
            });
        }
    }

    async fetchClientInformation(base64Image){
        this.isLoading = true;
        let queryParams;
        try {
            const result = await recognizeClient({ base64Image: base64Image });
            if (result.statusCode === '0') {
                if(result.identified === true){
                    queryParams = {'tipo-documento':'1', 'numero-documento':result.documentNumber, ...this.queryParamsResult};
                }
            } else {
                console.error(result.message);
            }
        } catch (error) {
            console.error(error);
        } finally {
            this.isLoading = false;
        }
        return queryParams;
    }

    displayHeaderElements(back, home){
        const selectedEvent = new CustomEvent('displayelements',{
            detail: { back: back, home: home }
        });
        this.dispatchEvent(selectedEvent);
    }

    @api
    handleBack(){
        this.chooseScreen('advertisementCall');
        this.displayHeaderElements(false,false);
    }

    handleTimeout(){
        if(this.pantallas.advertisementCall !== true){
            location.reload();
        }
    }

    /**
     * @description Elige la pantalla a mostrar
     * @param {*} screen 
     */
    chooseScreen(screen) {
        if (this.pantallas.hasOwnProperty(screen)) {
            for (let key in this.pantallas) {
                this.pantallas[key] = (key === screen);
            }
        }
    }

}