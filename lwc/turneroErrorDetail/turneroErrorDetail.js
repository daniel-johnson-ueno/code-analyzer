/**
 * @name               : turneroErrorDetail
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 11-02-2025
 * @modification date  : 11-02-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : 
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   11-02-2025   Alvaro Gonzales Lapponi   Initial Version
**/
import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import ICONS from '@salesforce/resourceUrl/turneroIcons';

export default class TurneroErrorDetail extends NavigationMixin(LightningElement) {
    /** ICONOS */
    icons = {
        maintenance:      `${ICONS}/turneroIcons/maintenance.png`,
    };

    handleHome(){
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Home'
            }
        });
    }
}