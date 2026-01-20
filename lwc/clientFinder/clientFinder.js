import { LightningElement, api, wire } from 'lwc';
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import { NavigationMixin } from "lightning/navigation";
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";

import getAccountId from '@salesforce/apex/AccountMappingServiceLWC.getAccountId';

import DOC_TYPE from "@salesforce/schema/Lead.Document_Type__c";

export default class ClientFinder extends NavigationMixin(LightningElement) {

    @api isLoading = false;
    disabled = true;
    clientRecType;
    docTypeOptions;
    docTypeValue = '';
    docNumValue = '';
    phoneValue;
    accountId;
    booleanDoc = false;
    booleanPhone = false;
    booleanPageStart = true;
    booleanPageError = false;
    
    @wire(getPicklistValues, { recordTypeId: "012000000000000AAA", fieldApiName: DOC_TYPE })
    wiredPicklistValues({ error, data }) {      
        if (data) {             
            this.docTypeOptions = data.values;         
        } else if (error) {   
            console.error('Error retrieving picklist values: ', error);  
        }     
    }
    
    get documentTypeOptions(){
        return this.docTypeOptions;
    }
    get options() {
        return [
            { label: 'Documento', value: 'optionDoc' },
            { label: 'Teléfono', value: 'optionPhone' },
        ];
    }
    handleValidationDocType() {
        let docType = this.template.querySelector('.docType');
        if (!docType.value) {
            docType.setCustomValidity('Por favor, complete este campo.');
        } else {
            docType.setCustomValidity('');
        }
        docType.reportValidity();
    }
    handleValidationDocNum() {
        let docNum = this.template.querySelector('.docNum');        
        if (!docNum.value) {
            docNum.setCustomValidity('Por favor, complete este campo.');
        } else {
            docNum.setCustomValidity('');
        }
        docNum.reportValidity();
    }
    handleValidationPhone() {
        let phoneNum = this.template.querySelector('.phoneNum');        
        if (!phoneNum.value) {
            phoneNum.setCustomValidity('Por favor, complete este campo.');
        } else {
            phoneNum.setCustomValidity('');
        }
        phoneNum.reportValidity();
    }
    handleRadioButtonChange(event){
        const selectedOption = event.detail.value;
        if (selectedOption=='optionDoc') {
            this.booleanDoc=true;
            this.booleanPhone=false;
        }
        if (selectedOption=='optionPhone') {
            this.booleanPhone=true;
            this.booleanDoc=false;
        }
    }
    handleDocTypeChange(event){
        this.handleValidationDocType();
        this.docTypeValue = event.detail.value;
        if (this.docTypeValue.length === 0 || this.docNumValue.length === 0) {
            this.disabled=true;
        }else{
            this.disabled=false;
        }
    }
    handleDocNumInputChange(event){
        this.handleValidationDocNum();
        if (/\S/.test(event.detail.value)) {
            this.docNumValue = event.detail.value;
            if (this.docTypeValue.length === 0) {
                this.disabled=true;
            }else{
                this.disabled=false;
            }
        }else{
            this.disabled=true;
        }
    }
    handlePhoneInputChange(event){
        this.handleValidationPhone();
        if (/\S/.test(event.detail.value)) {
            this.phoneValue = event.detail.value;
            this.disabled=false;
        }else{
            this.disabled=true;
        }
    }
    handleClick(){
        this.isLoading = true;
        if (this.booleanDoc) {
            getAccountId({documentNumber: this.docNumValue, documentType: this.docTypeValue})
            .then((result) => {
                this.accountId = result;
                this.error = undefined;
                this.navigateToRecord();
            })
            .catch((error) => {
                this.error = error;
                this.accountId = undefined;
            })
        }
        if (this.booleanPhone) {
            getAccountId({documentNumber: this.phoneValue, documentType: '99'})
            .then((result) => {
                this.accountId = result;
                this.error = undefined;
                this.navigateToRecord();
            })
            .catch((error) => {
                this.error = error;
                this.accountId = undefined;
            })
        }
    }
    navigateToRecord() {
        this.isLoading = false;
        if ( typeof(this.accountId) == "undefined" || this.accountId == null ) {
            this.booleanPageError = true;
            this.booleanPageStart = false;
            this.disabled = true;
        }else {
            const url = window.location.origin + '/lightning/r/Account/' + this.accountId + '/view';
            window.open( url, '_self' );
        }
    }
    handleClickBack(){
        this.booleanPageStart = true;
        this.booleanPageError = false;
        this.booleanDoc = false;
        this.booleanPhone = false;
    }
    handleClickSearchAccount(){
        let searchQuery;
        if (this.booleanDoc) {
            searchQuery = this.docNumValue;
        }
        if (this.booleanPhone) {
            searchQuery = this.phoneValue;
        }
        let stringToEncode = '{"componentDef":"forceSearch:search","attributes":{"term":"'+searchQuery + '","scopeMap":{"type":"TOP_RESULTS"},"context": {"disableSpellCorrection":false,"SEARCH_ACTIVITY":{"term":"'+ searchQuery + '"}}}}';
        let encodedString = btoa(stringToEncode);
        let globalSearchUrl ="/one/one.app?source=alohaHeader#" +encodedString
        const url = window.location.origin + globalSearchUrl;
        window.open( url, '_self' );
    }
    handleClickCreateLead(){
        const defaultValues = encodeDefaultFieldValues({
            recordTypeId: this.clientRecType,
            Document_Type__c: this.docTypeValue,
            DocumentNumber__c: this.docNumValue,
            Document_Number__c: this.docNumValue,
            Phone:this.phoneValue
        });
        this.isLoading = false;
        this[NavigationMixin.Navigate](
            {
                type: "standard__objectPage",
                attributes: {
                    objectApiName: "Lead",
                    actionName: "new"
                },
                state: {
                    defaultFieldValues : defaultValues,
                    nooverride: '1'
                }
            }
        );
    }
}