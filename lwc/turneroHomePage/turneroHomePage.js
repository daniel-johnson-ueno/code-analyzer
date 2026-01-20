/**
 * @name               : 
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 
 * @modification date  : 16-12-2024
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : 
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   19-11-2024   Alvaro Gonzales Lapponi   Initial Version
**/
import { LightningElement, track } from 'lwc';

export default class TurneroHomePage extends LightningElement {
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