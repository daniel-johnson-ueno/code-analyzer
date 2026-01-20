/**
 * @name               : turneroTurnoSolicitudDetail
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 11-11-2024
 * @modification date  : 27-03-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Componente de detalle de la Página Solicitud de Turno - Turnero
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   20-11-2024   Alvaro Gonzales Lapponi   Initial Version
**/
import { LightningElement, api, track } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import fetchCliente from '@salesforce/apex/turneroTurnoSolicitudController.fetchCliente';
import getAppointmentConditions from '@salesforce/apex/procedureAssignmentUtils.getAppointmentConditions';
import getTramites from '@salesforce/apex/procedureAssignmentUtils.getTramites';
import checkIn from '@salesforce/apex/turneroTurnoSolicitudController.checkIn';
import sendSMS from '@salesforce/apex/turneroTurnoSolicitudController.sendSMS';
import ICONS from '@salesforce/resourceUrl/turneroIcons';

const STATUSCODE_SUCCESS = '0';

const PATH_CONSULTA = '/turno/consulta';

const TIPO_DOCUMENTO_CEDULA     = { id:'cedula', labelMayus:'Cédula', labelMinus:'cédula de identidad', api:'1', inputType:'numerico' };
const TIPO_DOCUMENTO_RUC        = { id:'ruc', labelMayus:'RUC', labelMinus:'Registro Único del Contribuyente', api: '6', inputType:'numerico' };
const TIPO_DOCUMENTO_PASAPORTE  = { id:'pasaporte', labelMayus:'Pasaporte', labelMinus:'pasaporte', api: '2', inputType:'alfanumerico' };

const QUERY_PARAMS_CLIENTE = [
    'tipo-documento',
    'numero-documento'
];

const MENSAJESCONFIRMACION = [
    { name: 'queueableWithPhone', icon:'check', title: 'Por favor, revisá tu celular para seguir tu turno', subtitle: 'Tomá asiento, en unos instantes estamos con vos.'},
    { name: 'queueableWithoutPhone', icon:'check', title: '¡Turno correctamente creado!', subtitle: 'Tomá asiento, en unos instantes estamos con vos.'},
    { name: 'TED', icon:'ted', title: 'Pasá por una Terminal de Experiencia Digital para realizar una operación', subtitle: 'Si necesitás ayuda, podés consultar con alguien del equipo de atención.' },
    { name: 'generic', icon:'hourglass', title: 'La caja ya está cerrada por hoy', subtitle: 'Podés depositar o sacar dinero desde una TED.', additionalInfo: 'Por otras operaciones, te esperamos a partir de las 08:00 h.' }
];

const TRAMITES_PRIORITARIO = [
    { name: 'Tarjetas', icon: 'tarjetas'},
    { name: 'Cuentas y transferencias', icon: 'cuentas'}
]

export default class TurneroTurnoSolicitudDetail extends NavigationMixin(LightningElement) {

    /** ICONOS */
    icons = {
        phone:      `${ICONS}/turneroIcons/phone.png`,
        applause:   `${ICONS}/turneroIcons/appaluse.png`,
        check:      `${ICONS}/turneroIcons/check.png`,
        person:     `${ICONS}/turneroIcons/person.png`,
        persona:    `${ICONS}/turneroIcons/persona.png`,
        empresas:   `${ICONS}/turneroIcons/empresas.png`,
        send:       `${ICONS}/turneroIcons/send.png`,
        cuentas:    `${ICONS}/turneroIcons/cuentas.png`,
        tarjetas:   `${ICONS}/turneroIcons/tarjetas.png`,
        ted:        `${ICONS}/turneroIcons/ted.png`,
        hourglass:  `${ICONS}/turneroIcons/hourglass.png`,
        prioritary: `${ICONS}/turneroIcons/prioritary.png`,
    };
    
    /** ESTADOS GENERALES Y VARIABLES DE CONTROL */
    isLoading               = false;
    baseUrl;
    queryParams             = QUERY_PARAMS_CLIENTE;
    queryParamsResult;
    tipoDocumento1          = {};
    tipoDocumento2          = {};
    @track selectedDocument = {};
    endsWith                = '/turno/solicitud';

    /** SECCIÓN PARA VARIABLES DE CONFIGURACIÓN DE COMPONENTES */
    currentScreen;
    inputValidado = false;
    disabledButton = false;
    selectedTramiteContainer = {};

    /** DATOS PARA DATA PARA CREACIÓN CITA */
    @track tramites             = [];
    @track clientOwn            = {};
    @track clientOther          = {};
    get cliente() {
        const hasClientOther = this.clientOther && Object.keys(this.clientOther).length > 0;
        return hasClientOther ? this.clientOther : this.clientOwn;
    }
    profilePicture;
    numeroTelefonoSecundario    = '';
    numeroDocumentoSecundario   = '';
    requierePrioridad           = false;
    selectedTramite             = '';
    selectedSubtramite          = '';
    tipoRepresentante           = '';

    @track dataCita             = {};
    @track tipoCitaRequest      = {};
    mensajeConfirmacion         = {};
    appointmentConditions       = {};
    followUp = true;
    withSecondaryPhone = false;

    /** DATOS DE CITA CREADA */
    numeroCita          = '';
    urlTurno            = '';
    tipoConfirmacion    = '';

    /** ORQUESTADOR DE PANTALLAS */
    @track pantallas = {
        validacionParaTi: true,
        sinQueryParams: false,
        ingresarDocumento: false,
        motivoVisita: false,
        tipoCita: false,
        atencionPrioritaria: false,
        celularNoEncontrado: false,
        validacionTelefono: false,
        telefonoSecundario: false,
        confirmacionFila: false,
        enviandoMensaje: false,
        instruccionesFinales: false,
        qr: false
    };

    /** Pantalla previa a cada una en caso de seleccionar botón Back */
    pantallasPrevias = {
        ingresarDocumento: 'validacionParaTi',
        motivoVisita: 'validacionParaTi',
        tipoCita: 'motivoVisita',
        atencionPrioritaria: 'motivoVisita',
        celularNoEncontrado: 'atencionPrioritaria',
        validacionTelefono: 'atencionPrioritaria',
        telefonoSecundario: 'atencionPrioritaria',
        qr: 'instruccionesFinales'
    }

    /** Habilitación de botones back y home por pantalla */
    botonesHabilitados = {
        validacionParaTi: { back: false, home: true},
        sinQueryParams: { back: false, home: true},
        ingresarDocumento: { back: true, home: true },
        motivoVisita: { back: true, home: true },
        tipoCita: { back: true, home: true },
        atencionPrioritaria: { back: true, home: true },
        celularNoEncontrado: { back: true, home: true },
        validacionTelefono: { back: true, home: true },
        telefonoSecundario: { back: true, home: true},
        confirmacionFila: { back: false, home: false},
        enviandoMensaje: { back: false, home: false},
        instruccionesFinales: { back: false, home: true},
        qr: { back: true, home: true}
    }

    /**
     * @description Va a la pantalla anterior
     */
    @api
    handleBack(){
        if(this.currentScreen){
            this.clientOther = {};
        }
        this.chooseScreen(this.pantallasPrevias[this.currentScreen]);
    }

    handleTimeout(){
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Home'
            }
        });
    }

    /**
     * @description Método que se ejecuta al renderizar el componente
     */
    connectedCallback() {
        this.getCommunityUrl();
    }
    
    /**
     * @description Recibe información de query params en la URL
     * @param {*} event 
     */
    async handleUrlAnalized(event){
        this.queryParamsResult = event.detail.params;
        this.profilePicture = localStorage.getItem('tempImage') ?  localStorage.getItem('tempImage') : this.icons.person;
        localStorage.removeItem('tempImage');
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

    /**
     * @description Opción alternativa cuando no se identifica a cliente por query params
     */
    async getClienteSinReconocer(){
        const cadenaValidada = this.validateInput();
        if(cadenaValidada){
            this.clientOwn = await this.getCliente(this.selectedDocument.api,this.numeroDocumentoSecundario);
            this.chooseScreen('validacionParaTi');
        }    
    }

    /**
     * @description 
     * @param {String} tipoDocumento 
     * @param {String} numeroDocumento 
     */
    async getCliente(tipoDocumento, numeroDocumento) {
        this.isLoading = true;
        let cliente;
        try {
            const result = await fetchCliente({ tipoDocumento, numeroDocumento });
            console.log(JSON.stringify(result,null,2))
            if (result.statusCode === STATUSCODE_SUCCESS) {
                cliente = result.cliente;
            } else{
                this.handleError();
            }
        } catch (error) {
            console.error(error);
            this.handleError();
        } finally {
            this.isLoading = false;
        }
        return cliente;
    }

    /**
     * @description
     */
    async getTramitesSubtramites() {
        this.isLoading = true;
        try{
            this.buildTipoCitaRequest();
            const result = await getTramites({ representativeType: this.tipoCitaRequest.representativeType, isClient: this.tipoCitaRequest.isClient });
            if (result && Object.keys(result).length > 0) {
                this.tramites = Object.entries(result).map(([key, value]) => {
                    const prioritario = TRAMITES_PRIORITARIO.find(item => item.name === key);
                    return {
                        name: key,
                        detalles: value,
                        ...(prioritario && { prioritary: true, iconSource: this.icons[prioritario.icon] })
                    };
                });
            } else {
                console.error("No se encontraron trámites.");
            }
        } catch (error){
            console.error(error);
            this.handleError();
        } finally{
            this.isLoading = false;
        }
    }

    /**
     * @description
     */
    async validateTypeOfProcess(){
        this.isLoading = true;
        try{
            this.buildTipoCitaRequest();
            const result = await getAppointmentConditions({ structure: this.tipoCitaRequest });
            if(result.existingRecord === true){
                this.appointmentConditions = result.appointmentConditions;
                if(this.appointmentConditions.queueable === true){
                    if(this.cliente.telefono){
                        this.telefonoCensurado = this.censorData(this.cliente.telefono, 2, 3);
                        this.chooseScreen('validacionTelefono');
                    } else{
                        this.chooseScreen('celularNoEncontrado');
                    }
                    
                } else{
                    const tipoConfirmacion = this.appointmentConditions.queue ? this.appointmentConditions.queue : 'generic';
                    this.mensajeConfirmacion = MENSAJESCONFIRMACION.find(mensaje => mensaje.name === tipoConfirmacion);
                    this.mensajeConfirmacion.icon = this.icons[this.mensajeConfirmacion.icon];
                    this.chooseScreen('instruccionesFinales');
                    await this.createAppointment();
                }
            } else{
                console.error('No hay registros para esta metadata');
            }
        } catch (error){
            console.error(error);
            this.handleError();
        } finally{
            this.isLoading = false;
        }
    }
    
    /**
     * @description Crea cita y/o caso
     */
    async createAppointment(){

        const cadenaValidada = this.withSecondaryPhone == true ? this.validateInput() : true;
        
        if(cadenaValidada){
            this.buildAppointmentData();
            this.isLoading = true;
            try {
                const result = await checkIn({ data: this.dataCita, conditions: this.appointmentConditions });
                if (result.statusCode === STATUSCODE_SUCCESS) {
                    if(result.appointmentId){
                        this.numeroCita = result.appointmentId; 

                        const tipoConfirmacion = this.followUp === true ? 'queueableWithPhone' : 'queueableWithoutPhone';
                        this.mensajeConfirmacion = MENSAJESCONFIRMACION.find(mensaje => mensaje.name === tipoConfirmacion);
                        this.mensajeConfirmacion.icon = this.icons[this.mensajeConfirmacion.icon];
                        await this.confirmationProcess(this.followUp);
                    }
                    
                } else {
                    console.error(result.message);
                    this.handleError();
                }
            } catch (error) {
                console.error(error);
                this.handleError();
            } finally {
                this.isLoading = false;
            }
        }
    }

    /**
     * @description Notifica cliente mediante SMS
     */
    async sendSMSLink(){
        this.isLoading = true;
        sendSMS({ phone: this.dataCita.telefono, message: 'Podes seguir tu turno desde ' + this.urlTurno })
        .then(result => {
            if(result.statusCode === STATUSCODE_SUCCESS){
                console.log('mensaje enviado correctamente');
            }           
        })
        .catch(error => {
            console.error(error);
            this.handleError();
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    /**
     * @description 
     * @param {*} event 
     */
    handleForWhom(event){
        const actionType = event.target.dataset.actionType;
        const value = event.target.dataset.value;
        if(actionType === 'choose_forWhom'){
            if(value === 'himself'){
                this.chooseScreen('motivoVisita');                
                this.tipoRepresentante = 'Persona';
                this.getTramitesSubtramites();
            } else if(value === 'other_person'){
                this.chooseScreen('ingresarDocumento');
                this.tipoRepresentante = 'Persona';
                this.tipoDocumento1 = TIPO_DOCUMENTO_CEDULA;
                this.tipoDocumento2 = TIPO_DOCUMENTO_PASAPORTE;
                this.selectedDocument = this.tipoDocumento1;
            } else if(value === 'other_company'){
                this.tipoRepresentante = 'Empresa';
                this.chooseScreen('ingresarDocumento');
                this.tipoDocumento1 = TIPO_DOCUMENTO_CEDULA;
                this.tipoDocumento2 = TIPO_DOCUMENTO_RUC;
                this.selectedDocument = this.tipoDocumento1;
            }
        }
    }

    /**
     * @description
     * @param {*} event 
     */
    handleSelectTramite(event){
        const name  = event.target.dataset.name;
        this.selectedTramite = name;
        this.selectedTramiteContainer = this.tramites.find(tramite => tramite.name === name);
        if(this.selectedTramiteContainer.detalles.length > 0){
            this.chooseScreen('tipoCita');
        } else{
            this.chooseScreen('atencionPrioritaria');
        }
        
    }

    /**
     * @description
     */
    async confirmClient(){
        //validacion de input
        const cadenaValidada = this.validateInput();
        if(cadenaValidada){
            this.clientOther = await this.getCliente(this.selectedDocument.api,this.numeroDocumentoSecundario);
            await this.getTramitesSubtramites();
            this.chooseScreen('motivoVisita');
        }
    }

    /**
     * @description
     * @param {*} event 
     */
    handleChangeNumeroDocumento(event){
        const value = event.detail.cadenaCompleta;
        this.inputValidado = event.detail.cadenaValidada;
        if(this.disabledButton){
            this.validateInput();
        }
        this.numeroDocumentoSecundario = value;
    }

    handleChangeNumeroTelefono(event){
        const value = event.detail.cadenaCompleta;
        this.inputValidado = event.detail.cadenaValidada;
        if(this.disabledButton){
            this.validateInput();
        }
        this.numeroTelefonoSecundario = value;
    }

    handleSelectNewMobilePhone(){
        this.chooseScreen('telefonoSecundario');
    }

    handleSelectSubtramite(event){
        const value = event.target.dataset.value;
        this.motivoTramite = value;
        this.selectedSubtramite = value;
        this.chooseScreen('atencionPrioritaria');
    }

    handleChangePriority(event) {
        const value = event.target.value;
        this.requierePrioridad = value === 'yes';
    }

    handleRequestAppointmentWithSecondaryPhone(){
        this.withSecondaryPhone = true;
        this.createAppointment();
    }

    handleOmitFollow(){
        this.followUp = false;
        this.createAppointment();
    }

    displayHeaderElements(back, home){
        const selectedEvent = new CustomEvent('displayelements',{
            detail: { back: back, home: home }
        });
        this.dispatchEvent(selectedEvent);
    }

    /**
     * @description Ir a la pantalla Home
     */
    handleHome(){
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Home'
            }
        });
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


    handleNoLllegoSMS(){
        this.chooseScreen('qr');
    }

    async confirmationProcess(followTurn){
        if(followTurn === true){
            this.chooseScreen('enviandoMensaje');
            this.urlTurno = this.baseUrl + PATH_CONSULTA + '?numero-cita=' + this.numeroCita;
            await this.sendSMSLink();
        } 
        this.chooseScreen('confirmacionFila');
        this.chooseScreen('instruccionesFinales');
    }
    
    buildTipoCitaRequest(){
        this.tipoCitaRequest.representativeType = this.tipoRepresentante;
        this.tipoCitaRequest.isClient           = this.cliente.esCliente;
        this.tipoCitaRequest.product            = this.selectedTramite;
        this.tipoCitaRequest.subproduct         = this.selectedSubtramite;
    }

    /**
     * @description
     */
    buildAppointmentData(){
        this.dataCita.requierePrioridad = this.requierePrioridad;
        this.dataCita.accountId         = this.cliente.accountId;
        this.dataCita.tipoDocumento     = this.cliente.tipoDocumento;
        this.dataCita.numeroDocumento   = this.cliente.numeroDocumento;
        this.dataCita.nombreCliente     = this.cliente.nombre ? this.cliente.nombre : '';
        this.dataCita.apellidoCliente   = this.cliente.apellido ? this.cliente.apellido : '';
        this.dataCita.tipoRepresentante = this.tipoRepresentante;
        this.dataCita.tramite           = this.selectedTramite;
        this.dataCita.subtramite        = this.selectedSubtramite;
        this.dataCita.foto              = this.profilePicture;
        this.dataCita.telefono          = this.numeroTelefonoSecundario !== '' ? this.numeroTelefonoSecundario : this.cliente.telefono;
    }
   
    clearInput(){
        const customKeyboard = this.template.querySelector('c-custom-keyboard');
        if (customKeyboard) {
            customKeyboard.clearInput();
            customKeyboard.valueInputChanged();
        }
    }

    /**
     * @description Censura textos para mostrar en pantalla
     * @param {*} str 
     * @param {*} charStart 
     * @param {*} chartEnd 
     * @returns 
     */
    censorData(str, charStart, chartEnd){
        const start = str.slice(0, charStart);
        const end = str.slice(-chartEnd);
        const censor = '*'.repeat(str.length - ( charStart + chartEnd ));
        return `${start}${censor}${end}`;
    }

    /**
     * @description Trae información de la URL de la comunidad
     */
    getCommunityUrl(){
        const fullPath = window.location.pathname;
        const parts = fullPath.split('/');
        const siteName = parts.length > 1 ? `/${parts[1]}` : '';
        this.baseUrl = `${window.location.origin}${siteName}`;
    }

    /***SELECTOR DE TIPO DOCUMENTO ***/
    get sliderStyle() {
        return `transform: translateX(${this.selectedDocument.id === this.tipoDocumento1.id ? '0' : '100%'});`;
    }

    // Método para seleccionar Documento1
    selectDocument1() {
        this.selectedDocument = this.tipoDocumento1;
        this.clearInput();
        this.disabledButton = false;
    }

    // Método para seleccionar Documento2
    selectDocument2() {
        this.selectedDocument = this.tipoDocumento2;
        this.clearInput();
        this.disabledButton = false;
    }
    
    convertStringToList(commaSeparatedString) {
        if (!commaSeparatedString) {
            return [];
        }
        return commaSeparatedString.split(',').map(item => item.trim());
    }

    /**
     * @description Selecciona la pantalla a mostrar
     * @param {String} screen 
     */
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