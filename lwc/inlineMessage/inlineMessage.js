import { LightningElement, api } from 'lwc';
export default class InlineMessage extends LightningElement {
    @api title;
    @api subtitle;
    @api icon;

    handleClose(){
        this.dispatchEvent( new CustomEvent('close') );
    }
}