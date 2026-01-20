import { LightningElement } from 'lwc';
export default class RotHomePage extends LightningElement {
    showElement = { back: false, home: false }

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