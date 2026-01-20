import { LightningElement, track, wire } from 'lwc';
import { enablePopout, EnclosingUtilityId } from 'lightning/platformUtilityBarApi';

export default class AuviousWidgetModal extends LightningElement{
    
    @track showWidget = true; 
    @track embedUrl = 'https://auvious.video/welcome?pcEnvironment=sae1.pure.cloud&lang=es&aid=6df5f492-48a6-4f3e-87d1-43a3eb4b6af2';

    @wire(EnclosingUtilityId) utilityId;

    renderedCallback() {
        if (this.utilityId) {
            enablePopout(this.utilityId, false, { disabledText: 'Popout deshabilitado' });
        }
    }

    closeWidget() {
        this.showWidget = false;
    }

    refreshIframe() {
        this.embedUrl = `https://auvious.video/welcome?pcEnvironment=sae1.pure.cloud&lang=es&aid=6df5f492-48a6-4f3e-87d1-43a3eb4b6af2&t=${Date.now()}`;
    }
}