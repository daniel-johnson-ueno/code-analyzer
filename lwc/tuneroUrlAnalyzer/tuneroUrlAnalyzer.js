/**
 * @name               : turneroUrlAnalyzer
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 16-12-2024
 * @modification date  : 25-01-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : 
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   18-11-2024   Alvaro Gonzales Lapponi   Initial Version
**/
import { LightningElement, api } from 'lwc';

export default class TuneroUrlAnalyzer extends LightningElement {

    @api queryParams;
    @api endsWith;

    connectedCallback(){
        let params = this.getQueryParams(this.queryParams);
        let endsWithParam = false;
        if (window.location.pathname.endsWith(this.endsWith)) {
            endsWithParam = true;
        }
        let data = { params: params, endsWithParam: endsWithParam };

        const selectedEvent = new CustomEvent('urlanalized', { detail: data });
        this.dispatchEvent(selectedEvent);
    }

    getQueryParams(paramsArray) {
        const urlParams = new URLSearchParams(window.location.search);
        const result = {};
        paramsArray.forEach(param => {
            result[param] = urlParams.get(param);
        });
        return result;
    }

}