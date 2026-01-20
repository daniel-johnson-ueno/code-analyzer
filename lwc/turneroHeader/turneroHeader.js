/**
 * @name               : 
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 
 * @modification date  : 25-02-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : 
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   19-11-2024   Alvaro Gonzales Lapponi   Initial Version
**/
import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import ICONS from '@salesforce/resourceUrl/turneroIcons';

const QUERY_PARAMS_HOME = [
    'sucursal'
];

export default class TurneroHeader extends NavigationMixin(LightningElement) {
    @api showElement;
    queryParams = QUERY_PARAMS_HOME;
    @track queryParamsResult;

    icons = {
        back:   `${ICONS}/turneroIcons/Chevrone - Left.png`,
        home:   `${ICONS}/turneroIcons/Home - Solid.png`,
        logo:   `${ICONS}/turneroIcons/Logo Horizontal.png`
    };

    handleBack(){
        const selectedEvent = new CustomEvent('back');
        this.dispatchEvent(selectedEvent);
    }

    handleHome(){
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Home'
            }
        });
    }

    handleUrlAnalized(event){
        this.queryParamsResult = event.detail.params;
    }

}