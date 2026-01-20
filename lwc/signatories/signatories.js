import { LightningElement, api, track } from 'lwc';

const signatoriesColumns = [
    { label: 'Mostrar', fieldName: '', initialWidth: 70, type: 'button-icon',
    typeAttributes: { iconName: 'action:preview', title: 'View', variant: 'bare', alternativeText: 'View'}
    },
    { label: 'Cliente', fieldName: 'personCode', hideDefaultActions: true },
    { label: 'Nombre del cliente', fieldName: 'fullName', hideDefaultActions: true},
    { label: 'Relación', fieldName: 'relationship', hideDefaultActions: true},
    ];

export default class Signatories extends LightningElement {

 @api signatoriesList;
 @api requiredSignaturesQty;
 @api registeredSignatureQty;
 @api registeredSignature;

 @track showSignatureDetails = false;
 @track clickedSignature;

 signatoriesColumns = signatoriesColumns;


handleShowSignatureDetails(event){
    let dataRow = event.detail.row;
    this.showSignatureDetails = true
    this.clickedSignature = {...dataRow};
}

toggleSignatureDetailsPanel(){
    this.showSignatureDetails = !this.showSignatureDetails;
}


}