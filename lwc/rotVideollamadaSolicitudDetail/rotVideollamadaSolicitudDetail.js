/**
 * @name               : rotVideollamadaSolicitudDetail
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 02-01-2025
 * @modification date  : 26-03-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Componente detalle para solicitar videollamadas ROT
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   13-01-2025   Alvaro Gonzales Lapponi   Initial Version
**/
import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import fetchCliente from '@salesforce/apex/rotVideollamadaSolicitudController.fetchCliente';
import fetchTurneroOpenCases from '@salesforce/apex/rotVideollamadaSolicitudController.fetchTurneroOpenCases';

import ICONS from '@salesforce/resourceUrl/rotIcons';

const TIPO_DOCUMENTO_CEDULA     = { id:'cedula', labelMayus:'Cédula', labelMinus:'cédula de identidad', api:'1', inputType:'numerico' };
const TIPO_DOCUMENTO_RUC        = { id:'ruc', labelMayus:'RUC', labelMinus:'Registro Único del Contribuyente', api: '6', inputType:'numerico' };
const TIPO_DOCUMENTO_PASAPORTE  = { id:'pasaporte', labelMayus:'Pasaporte', labelMinus:'pasaporte', api: '2', inputType:'alfanumerico' };

const QUERY_PARAMS_CLIENTE = [
    'tipo-documento',
    'numero-documento'
];

const STATUSCODE_SUCCESS = '0';

export default class RotVideollamadaSolicitudDetail extends NavigationMixin(LightningElement) {


    @track casos = [];

    icons = {
        person:     `${ICONS}/rotIcons/person.png`,
        persona:    `${ICONS}/rotIcons/persona.png`,
        empresas:   `${ICONS}/rotIcons/empresas.png`,
        coffe:      `${ICONS}/rotIcons/coffe.png`,
        caso:       `${ICONS}/rotIcons/case.svg`
    };

    showModal = false;

    nombreSucursal = '';
    tipoDocumento1 = {};
    tipoDocumento2 = {};
    @track selectedDocument = {};
    
    isLoading = false;
    endsWith = '/videollamada/solicitud';
    queryParams = QUERY_PARAMS_CLIENTE;

    /**SECCIÓN PARA VARIABLES DE CONFIGURACIÓN DE COMPONENTES */
    currentScreen;
    inputValidado = false;
    disabledButton = false;

    caseId;
    @track clientOwn            = {};
    @track clientOther          = {};
    get cliente() {
        const hasClientOther = this.clientOther && Object.keys(this.clientOther).length > 0;
        return hasClientOther ? this.clientOther : this.clientOwn;
    }

    @track pantallas = {
        validacionParaTi: true,
        sinQueryParams: false,
        ingresarDocumento: false,
        casosAbiertos: false,
        espera: false
    };

    pantallasPrevias = {
        ingresarDocumento: 'validacionParaTi',
        casosAbiertos: 'validacionParaTi'
    }

    botonesHabilitados = {
        validacionParaTi: { back: false, home: true},
        sinQueryParams: { back: false, home: true},
        ingresarDocumento: { back: true, home: true },
        casosAbiertos: { back: true, home: true },
        espera: { back: false, home: false }
    }

    @track disabledBotones = {
        numeroDocumento: true
    }

    /**
     * @description Obtiene un cliente
     * @param {String} tipoDocumento 
     * @param {String} numeroDocumento 
     * @returns 
     */
    async getCliente(tipoDocumento, numeroDocumento) {
        this.isLoading = true;
        let cliente;
        try {
            const result = await fetchCliente({ tipoDocumento, numeroDocumento });
            if (result.statusCode === STATUSCODE_SUCCESS) {
                cliente = result.cliente;
                this.nombreSucursal = result.nombreSucursal;
            }
        } catch (error) {
            console.error(error);
        } finally {
            this.isLoading = false;
        }
        return cliente;
    }

    /**
     * @description  Obtiene los casos abiertos del cliente seleccionado provenientes de Turnero, derivados a ROT
     */
    async getTurneroOpenCases() {
        this.isLoading = true;
        const tipoDocumento = this.cliente.tipoDocumento;
        const numeroDocumento = this.cliente.numeroDocumento;
        try {
            const result = await fetchTurneroOpenCases({ tipoDocumento: tipoDocumento, numeroDocumento: numeroDocumento });
            if (result.statusCode === STATUSCODE_SUCCESS) {
                this.casos = result.casos;
                this.formatCaseData();
                if(this.casos.length > 0){

                    this.chooseScreen('casosAbiertos');
                } else{
                    this.requestVideocall();
                }
            }
        } catch (error) {
            console.error(error);
        } finally {
            this.isLoading = false;
        }
    }

    async requestVideocall() {
        this.chooseScreen('espera');
        const auviousWidget = this.template.querySelector('c-auvious-widget');
        if (auviousWidget) {
            await auviousWidget.requestVideocall();
        }
    }

    formatCaseData() {
        this.casos = this.casos.map(caso => {
            return { ...caso, numeroCaso: 'Caso: ' + caso.numeroCaso };
        });
    }

    displayHeaderElements(back, home){
        const selectedEvent = new CustomEvent('displayelements',{
            detail: { back: back, home: home }
        });
        this.dispatchEvent(selectedEvent);
    }


    @api
    handleBack(){
        this.chooseScreen(this.pantallasPrevias[this.currentScreen]);
    }

    handleTimeout(){
        if(this.pantallas.espera !== true){
             this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    name: 'Home'
                }
            });
        }
    }

    async handlePressKey(event){
        const actionType = event.target.dataset.actionType;
        const value = event.target.dataset.value;
        if(actionType === 'choose_forWhom'){
            if(value === 'himself'){
                await this.getTurneroOpenCases();
            } else if(value === 'other_person'){
                this.chooseScreen('ingresarDocumento');
                this.tipoDocumento1 = TIPO_DOCUMENTO_CEDULA;
                this.tipoDocumento2 = TIPO_DOCUMENTO_PASAPORTE;
                this.selectedDocument = this.tipoDocumento1;
                this.displayHeaderElements(true,true);
            } else if(value === 'other_company'){
                this.chooseScreen('ingresarDocumento');
                this.tipoDocumento1 = TIPO_DOCUMENTO_CEDULA;
                this.tipoDocumento2 = TIPO_DOCUMENTO_RUC;
                this.selectedDocument = this.tipoDocumento1;
                this.displayHeaderElements(true,true);
            }
        }
    }

    async handleUrlAnalized(event){
        this.queryParamsResult = event.detail.params;
        if(this.queryParamsResult['tipo-documento'] && this.queryParamsResult['numero-documento']){
            this.clientOwn = await this.getCliente(this.queryParamsResult['tipo-documento'], this.queryParamsResult['numero-documento']);
        } else{
            this.chooseScreen('sinQueryParams');
            this.tipoRepresentante = 'Persona';
            this.tipoDocumento1 = TIPO_DOCUMENTO_CEDULA;
            this.tipoDocumento2 = TIPO_DOCUMENTO_PASAPORTE;
            this.selectedDocument = this.tipoDocumento1;
        }
    }
    
    async getClienteSinReconocer(){
        const cadenaValidada = this.validateInput();
        if(cadenaValidada){
            this.clientOwn = await this.getCliente(this.selectedDocument.api,this.numeroDocumentoSecundario);
            this.chooseScreen('validacionParaTi');
        }
    }

    handleChooseCase(event){
        this.caseId = event.target.dataset.id;
        this.requestVideocall();
    }

    async handleEndSession(){
        this.showModal = false;
        const widget = document.querySelector('app-auvious-widget');
        if (widget) {
            try {
                await widget.terminate(false);
            } catch (error) {
                console.error('Error during widget termination:', error);
            }
            if (document.querySelector('app-auvious-widget')) {
                widget.remove();
            }
        }
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Home'
            }
        });
    }

    async getAlternativeClient(){
        const cadenaValidada = this.validateInput();
        if(cadenaValidada){
            this.clientOther = await this.getCliente(this.selectedDocument.api,this.numeroDocumentoSecundario);
            await this.getTurneroOpenCases();
        }
    }

    handleChangeNumeroDocumento(event){
        const value = event.detail.cadenaCompleta;
        this.inputValidado = event.detail.cadenaValidada;
        if(this.disabledButton){
            this.validateInput();
        }
        this.numeroDocumentoSecundario = value;
    }

    handleCancel(){
        this.showModal = true;
    }

    handleKeepWaiting(){
        this.showModal = false;
    }


    /***SELECTOR DE TIPO DOCUMENTO ***/
    get sliderStyle() {
        return `transform: translateX(${this.selectedDocument.id === this.tipoDocumento1.id ? '0' : '100%'});`;
      }
    
    // Condición para estilos en los botones
    get isDocument1Selected() {
        return this.selectedDocument.id === this.tipoDocumento1.id ? 'true' : 'false';
    }

    get isDocument2Selected() {
        return this.selectedDocument.id === this.tipoDocumento2.id ? 'true' : 'false';
    }

    // Método para seleccionar Documento2
    selectDocument1() {
        this.selectedDocument = this.tipoDocumento1;
        this.clearInput();
        this.disabledButton = false;
    }

    // Método para seleccionar Documento1
    selectDocument2() {
        this.selectedDocument = this.tipoDocumento2;
        this.clearInput();
        this.disabledButton = false;
    }

    clearInput(){
        const customKeyboard = this.template.querySelector('c-custom-keyboard');
        if (customKeyboard) {
            customKeyboard.clearInput();
            customKeyboard.valueInputChanged();
        }
    }

    chooseScreen(screen) {
        if (this.pantallas.hasOwnProperty(screen)) {
            for (let key in this.pantallas) {
                this.pantallas[key] = (key === screen);
            }
            this.currentScreen = screen;
            this.displayHeaderElements(this.botonesHabilitados[screen].back, this.botonesHabilitados[screen].home)
        }
    }

    validateInput(){
        this.disabledButton = !this.inputValidado;
        return this.inputValidado;
    }
}