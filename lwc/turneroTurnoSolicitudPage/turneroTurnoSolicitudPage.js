/**
 * @name               : turneroTurnoSolicitudPage
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 
 * @modification date  : 30-01-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : 
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   20-11-2024   Alvaro Gonzales Lapponi   Initial Version
**/
import { LightningElement, track } from 'lwc';

export default class TurneroTurnoSolicitudPage extends LightningElement {
    @track showElement = { back: false, home: true }

    displayElements(event){
        this.showElement = event.detail;
    }

    handleBack(){
        const child = this.template.querySelector('[data-id="detailElement"]');
        if (child) {
            child.handleBack();
        }
    }
}