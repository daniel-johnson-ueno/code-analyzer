/**
 * @name               : turneroHomeDetail
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 14-11-2024
 * @modification date  : 19-03-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : 
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   19-11-2024   Alvaro Gonzales Lapponi   Initial Version
**/
import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import recognizeClient from '@salesforce/apex/turneroHomeController.recognizeClient';
import ICONS from '@salesforce/resourceUrl/turneroIcons';

const QUERY_PARAMS_HOME = []; //Se agregan todos los query params a analizar como elementos

export default class TurneroHomeDetail extends NavigationMixin(LightningElement) {

    isLoading;
    queryParamsResult;
    @track queryParams = {};
    icons = {
        calendar: `${ICONS}/turneroIcons/calendar.png`
    };

    labels = {
        advertisementAppointment: 'Pedí un turno para recibir atención',
        requireClearFace: 'Despejá tu rostro y mirá a la cámara'
    };

    queryParams = QUERY_PARAMS_HOME;

    @track pantallas = {
        advertisementAppointment: true,
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
     * 
     */
    handleAskAppointment(){
        this.chooseScreen('requireClearFace');
        this.displayHeaderElements(false,false);
    }

    async handleClientInfo(event){
        localStorage.setItem('tempImage', event.detail.base64Image);
        const queryParams = await this.fetchClientInformation(event.detail.base64Image.split('base64,')[1]);

        if(queryParams){
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    name: 'turnoSolicitud__c'
                },
                state: queryParams
            });
        } else{
            console.log('no se encontró cliente');
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    name: 'turnoSolicitud__c'
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
            this.handleError();
        } finally {
            this.isLoading = false;
        }
        return queryParams;
    }

    /**
     * @description Controla la visibilidad de los botones de la cabecera
     * @param {Boolean} back 
     * @param {Boolean} home 
     */
    displayHeaderElements(back, home){
        const selectedEvent = new CustomEvent('displayelements',{
            detail: { back: back, home: home }
        });
        this.dispatchEvent(selectedEvent);
    }

    /**
     * @description Gestiona el botón back del header
     */
    @api
    handleBack(){
        this.chooseScreen('advertisementAppointment');
        this.displayHeaderElements(false,false);
    }

    handleTimeout(){
        if(this.pantallas.advertisementAppointment !== true){
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
    
    /**
     * @description Ir a la pantalla de errores
     */
    handleError(){
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Error'
            }
        });
    }

}