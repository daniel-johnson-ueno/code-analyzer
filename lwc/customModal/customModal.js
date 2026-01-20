/**
 * @name               : customModal
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 24-01-2025
 * @modification date  : 05-02-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : 
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   24-01-2025   Alvaro Gonzales Lapponi   Initial Version
**/
import { LightningElement, track, api } from 'lwc';
export default class CustomModal extends LightningElement {
    @api title;
    @api subtitle;
    @api primaryButtonText;
    @api secondaryButtonText;

    primaryButtonClicked(){
        const selectedEvent = new CustomEvent('primarybuttonclicked',{});
        this.dispatchEvent(selectedEvent);
    }

    secondaryButtonClicked(){
        const selectedEvent = new CustomEvent('secondarybuttonclicked',{});
        this.dispatchEvent(selectedEvent);
    }

}