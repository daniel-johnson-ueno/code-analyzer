/**
 * @name               : 
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 
 * @modification date  : 18-03-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : 
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   07-11-2024   Alvaro Gonzales Lapponi   Initial Version
**/
import { LightningElement, api } from 'lwc';

const DIMENSION_DEFAULT = "100px";

export default class TurneroButton extends LightningElement {
    @api title;
    @api label;
    @api icon;
    @api size;
    @api dimensionx;
    @api dimensiony;
    @api dimensions;
    @api position;
    @api iconSource;

    
    get classDimensions(){
        if(this.dimensions){
            return 'container ' + this.dimensions;
        }
    }

    get dim_style() {
        let style = '';
        const dimensionx = this.dimensionx || DIMENSION_DEFAULT;
        const dimensiony = this.dimensiony || DIMENSION_DEFAULT;
        style = `width: ${dimensionx}; height: ${dimensiony};`;

        if(this.position === 'center') {
            style += `text-align: center; text-align: center;`;
        }
        return style;
    }

    get showIcon(){
        return (this.iconSource || this.icon);
    }

    get headerVisibility(){
        return this.title || this.showIcon;
    }

}