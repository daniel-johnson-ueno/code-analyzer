/**
 * @name               : turneroTurnoConsultaDetail
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 17-02-2025
 * @modification date  : 20-03-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Componente para visualizar monitorear la espera de cita
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   09-01-2025   Alvaro Gonzales Lapponi   Initial Version
**/
import { LightningElement, track, wire } from 'lwc';
import getPosition from '@salesforce/apex/turneroTurnoConsultaController.getPosition';
import cancelAppointment from '@salesforce/apex/turneroTurnoConsultaController.cancelAppointment';
import getRefreshPeriod from '@salesforce/apex/turneroTurnoConsultaController.getRefreshPeriod';
import TurneroSeguimientoIndicacion from '@salesforce/label/c.TurneroSeguimientoIndicacion';
import ICONS from '@salesforce/resourceUrl/turneroIcons';


const LIMITE_ESPERA_VISIBLE = 45;
const ENDED_APPOINTMENTS = ['Cancelado', 'Finalizado','Abandonado'];
const STATUSCODE_SUCCESS = '0';
const QUERY_PARAMS_TURNO = [
    'numero-cita'
];

export default class TurneroTurnoConsultaDetail extends LightningElement {

    showCancelModal = false;
    showInlineMessage = true;
    @track turno = {
        personasAntes: 0,
        tiempoRestanteMinutos: 0
    };

    icons = {
        check:      `${ICONS}/turneroIcons/check.png`,
        info:      `${ICONS}/turneroIcons/info.png`,
        reloj:      `${ICONS}/turneroIcons/reloj.svg`,
        personas:   `${ICONS}/turneroIcons/personas.svg`,
        relojArena: `${ICONS}/turneroIcons/hourglass.png`,
        infoBadge:  `${ICONS}/turneroIcons/info badge.svg`
    };

    isLoading = false;
    endsWith = '/turno/consulta';
    queryParams = QUERY_PARAMS_TURNO;
    refreshPeriod = 60000;
    @track queryParamsResult = {};
    @track queuePosition;

    @track pantallas = {
        enColaDefault: false,
        enColaDetallado: false,
        siguienteEnFila: false,
        enTurno: false,
        turnoFinalizado: false,
        sinQueryParams: false
    };
    currentPageReference = null;

    labels = {
        TurneroSeguimientoIndicacion: TurneroSeguimientoIndicacion
    }

    get tiempoEspera(){
        if(this.turno.tiempoRestanteMinutos){
            return this.turno.tiempoRestanteMinutos > LIMITE_ESPERA_VISIBLE ? `+${LIMITE_ESPERA_VISIBLE}` : this.turno.tiempoRestanteMinutos;
        } else{
            return 0;
        }        
    }

    /**
     * Obtiene el periodo de refresco 
     */
    @wire(getRefreshPeriod)
    wiredPeriod({ error, data }){
        if(data) {
            this.refreshPeriod = data;
        } 
    } 

    /**
     * Consulta en la base de datos la posición actual y el tiempo de espera
     */
    getPositionInfo(){
        this.isLoading = true;
        getPosition({ appointmentId: this.queryParamsResult['numero-cita'] })
        .then(result => {
            if(result.statusCode === STATUSCODE_SUCCESS ){
                this.turno = result.positionData;
                this.turno.tiempoRestanteMinutos = Math.ceil(this.turno.tiempoRestanteMinutos);
                if( this.turno.estado === 'Ingreso' ){
                    this.ingresoProcess();
                }else if( this.turno.estado === 'Llamada' ){
                    this.chooseScreen('enTurno');
                } else if( ENDED_APPOINTMENTS.includes( this.turno.estado ) ){
                    this.chooseScreen('turnoFinalizado');
                }
                
                // Iniciar la actualización periódica
                this.startAutoRefresh();

            } else{
                this.chooseScreen('sinQueryParams');
            }            
        })
        .catch(error => {
            console.error(error);
        })
        .finally(() => {
            this.isLoading = false;
        });
    }    

    confirmCancellation(){
        this.isLoading = true;
        cancelAppointment({ appointmentId: this.queryParamsResult['numero-cita'] })
        .then(result => {
            if(result.statusCode === STATUSCODE_SUCCESS){
                this.showCancelModal = false;
                this.chooseScreen('turnoFinalizado');
            }          
        })
        .catch(error => {
            console.error(error);
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    ingresoProcess() {
        if (this.turno.asesoresDisponibles === false) {
            this.chooseScreen('enColaDefault');
            return;
        }
        if (this.turno.personasAntes > 0) {
            this.chooseScreen('enColaDetallado');
        } else {
            this.chooseScreen('siguienteEnFila');
        }
    }

    /**
     * @description Si no es estado finalizado o en atención se refresaca la data cada n segundos si sigue en espera
     */
    startAutoRefresh() {
        if (this.turno.estado === 'Ingreso') {
            if (this.refreshTimer) {
                clearTimeout(this.refreshTimer); // Cancela el timeout anterior
            }
    
            this.refreshTimer = setTimeout(() => {
                this.getPositionInfo();
            }, this.refreshPeriod);
        }
    }

    /**
     * @description Analiza la los query params de la URL
     * @param {*} event 
     */
    async handleUrlAnalized(event) {
        this.queryParamsResult = event.detail.params;
        if(this.queryParamsResult['numero-cita']){
            this.getPositionInfo();
        } else{
            this.chooseScreen('sinQueryParams');
        }
        
    }

    /**
     * @description Maneja el botón de "Cancelar turno"
     */
    handleCancelarTurno(){
        this.showCancelModal = true;
    }

    /**
     * @descripción Seguir esperando caso de no cancelar turno
     */
    keepWaiting(){
        this.showCancelModal = false;
    }

    /**
     * @description Cierra inline message
     */
    handleCloseInlineMessage(){
        this.showInlineMessage = false;
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
        }
    }
    

}