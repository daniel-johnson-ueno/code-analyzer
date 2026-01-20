/**
 * @name               : 
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 
 * @modification date  : 30-01-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : 
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   30-01-2025   Alvaro Gonzales Lapponi   Initial Version
**/
import { LightningElement } from 'lwc';
export default class TurneroTurnoConsultaPage extends LightningElement {
    showElement = { back: false, home: false }

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