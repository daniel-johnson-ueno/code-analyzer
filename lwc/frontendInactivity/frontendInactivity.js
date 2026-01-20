/**
 * @name               : frontendInactivity
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 04-03-2025
 * @modification date  : 04-03-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Componente para lanzar un custom event por inactividad frontend
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   04-03-2025   Alvaro Gonzales Lapponi   Initial Version
**/
import { LightningElement, api } from 'lwc';

export default class FrontendInactivity extends LightningElement {
    @api timeoutInSeconds = 90; // default 90 segundos
    @api checkInterval = 10; // comprobación de inactividad default 30 segundos
    timer;
    elapsedTime = 0;

    // Mantener track de la última vez que hubo actividad
    lastActivityTime = Date.now();

    /**
     * @description Método que se ejecuta al iniciar el componente
     */
    connectedCallback() {
        this.startTimer();
        this.addEventListeners();
    }

    /**
     * @description Método que inicia el temporizador
     */
    startTimer() {
        this.elapsedTime = 0;
        if (this.timer) {
            clearInterval(this.timer);
        }
        this.timer = setInterval(() => {
            this.checkInactivity();
        }, (this.checkInterval * 1000) ); // Verificar cada 30 segundos (o el intervalo que configures)
    }

    /**
     * @description Método que verifica la inactividad
     */
    checkInactivity() {
        const currentTime = Date.now();
        const timeDifference = (currentTime - this.lastActivityTime) / 1000;
        if (timeDifference >= this.timeoutInSeconds) {
            this.handleTimeout();
        }
    }

    /**
     * @description Método que resetea el temporizador
     */
    resetTimer() {
        this.lastActivityTime = Date.now();
    }

    /**
     * @description Llama a un evento cuando se alcanza el tiempo de inactividad
     */ 
    handleTimeout() {
        this.dispatchEvent( new CustomEvent('timeout') ); // Lanza el evento al padre
    }

    /**
     * @description Eventos que mantienen activa la interacción
     */
    addEventListeners() {
        window.addEventListener('click', this.resetTimer.bind(this));
        window.addEventListener('keydown', this.resetTimer.bind(this));
        window.addEventListener('touchstart', this.resetTimer.bind(this));
        window.addEventListener('touchmove', this.resetTimer.bind(this));
        window.addEventListener('mousemove', this.resetTimer.bind(this));
        window.addEventListener('scroll', this.resetTimer.bind(this));
    }

    /**
     * @description Método que se ejecuta al finalizar ciclo de vida
     */
    disconnectedCallback() {
        if (this.timer) {
            clearInterval(this.timer);
        }
    }
}