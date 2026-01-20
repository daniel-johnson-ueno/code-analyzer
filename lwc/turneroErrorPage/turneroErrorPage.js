/**
 * @name               : 
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 
 * @modification date  : 11-02-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : 
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   11-02-2025   Alvaro Gonzales Lapponi   Initial Version
**/
import { LightningElement, track } from 'lwc';

export default class TurneroErrorPage extends LightningElement {
    @track showElement = { back: false, home: false }

    handleBack(){
        const child = this.template.querySelector('[data-id="detailElement"]');
        if (child) {
            child.handleBack();
        }
    }

    displayElements(event){
        this.showElement = event.detail;
    }
}