/**
 * @name               : customKeyboard
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 23-01-2025
 * @modification date  : 07-02-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Teclado reusable con validación de inputs
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   22-01-2025   Alvaro Gonzales Lapponi   Initial Version
**/
import { LightningElement, api, track } from 'lwc';

const MENSAJES_ERROR = {
    cedula: 'Debés ingresar entre 6 y 9 dígitos',
    ruc: 'Debés ingresar entre 6 y 9 dígitos',
    pasaporte: 'Debés ingresar más de 6 dígitos',
    celular: 'Ingresa un número de celular válido'
}

export default class CustomKeyboard extends LightningElement {

    @api tipoInput;
    @api showMensajeError;

    @api
    clearInput(){
        this.valueInput = '';
        this.valueInputChanged();
    }

    _tipoTeclado;
    @api tipoTeclado;
    set tipoTeclado(value) {
        this._tipoTeclado = value;
        this.chooseKeyboard(value);
    }
    get tipoTeclado() {
        return this._tipoTeclado;
    }

    valueInput = '';
    
    @track teclados = {
        numerico: false,
        alfanumerico: false
    }

    @track mensajeError = '';
    get divClass() {
        return this.showMensajeError ? 'error-div' : 'no-error-div';
    }
    get inputClass() {
        return this.showMensajeError ? 'error-input' : 'no-error-input';
    }

    connectedCallback(){
        this.valueInputChanged();
    }


    addChar(event){
        const value = event.target.value;
        this.valueInput += value;
        this.valueInputChanged();
    }

    @api
    valueInputChanged(){
        const validacionObj = this.validateInput(this.tipoInput,this.valueInput);
        const cadenaValidada = validacionObj.validado;
        this.mensajeError = validacionObj.mensajeError;
        const selectedEvent = new CustomEvent('inputchanged',{
            detail: {cadenaCompleta: this.valueInput, cadenaValidada: cadenaValidada }
        });
        this.dispatchEvent(selectedEvent);
    }

    /**
     * @description Valida el input mediante regex
     * @param {String} type 
     * @param {String} value 
     * @return Boolean
     */
    validateInput(type, value) {
        let validado = false;
        let mensajeError = '';
        const validationRules = {
            celular: (val) => {
                const nacional1 = /^09\d{8}$/; // celular nacional que comienza con 09 (10 dígitos)
                const nacional2 = /^9\d{8}$/; // celular nacional que comienza con 9 (9 dígitos)
                const internacional = /^[1-9]\d{8,}$/; // Código internacional (mínimo 9 dígitos)

                return nacional1.test(val) || nacional2.test(val) || internacional.test(val);
            },
            pasaporte: (val) => /^[a-zA-Z0-9]{7,}$/.test(val), // Alfanumérico, más de 6 caracteres
            cedula: (val) => /^\d{6,9}$|^\d{5,8}-[a-zA-Z0-9]$/.test(val), // Numérico, entre 6 y 9 caracteres. Admite - al penúltimo
            ruc: (val) =>  /^\d{6,9}$|^\d{5,8}-[a-zA-Z0-9]$/.test(val), // Numérico, entre 6 y 9 caracteres. Admite - al penúltimo
        };

        if (!validationRules[type]) {
            console.error(`Tipo de validación desconocido: ${type}`);
            return { validado: false, mensajeError: 'Tipo de validación desconocido' };
        }
        validado = validationRules[type](value);
        mensajeError = validado === false ? MENSAJES_ERROR[type] : '';
        return {validado: validado, mensajeError: mensajeError};
    }

    chooseKeyboard(keyboard) {
        if(keyboard){
            if (this.teclados.hasOwnProperty(keyboard)) {
                for (let key in this.teclados) {
                    this.teclados[key] = (key === keyboard);
                }
            }
        }
        
    }
}