import { LightningElement, track, api, wire } from 'lwc';
//Standard
import { IsConsoleNavigation, getFocusedTabInfo, closeTab, getTabInfo, openSubtab, EnclosingTabId} from 'lightning/platformWorkspaceApi';
import { NavigationMixin } from 'lightning/navigation';
import { createRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CASE_OBJECT from "@salesforce/schema/Case";
import Id from "@salesforce/user/Id";
//Custom
import {showToastMessage, showErrorMessage} from 'c/utils';
import getExistingQueues from '@salesforce/apex/CaseManagerController.getExistingQueues';
import getTipificadores from '@salesforce/apex/CaseManagerController.getTipificadores';
import getPersonAccountContact from '@salesforce/apex/CaseManagerController.getPersonAccountContact';


const DELAY = 500;
const productList = ['Cuentas', 'NFC', 'Onboarding', 'Pago de servicios', 'Préstamos', 'Transferencias', 'QR', 'Seguridad', 'Tarjetas'];

export default class CaseManager extends NavigationMixin(LightningElement) {

//@track objectApiName;
@track parentTabId;
@track subTabId;
@track recordId;
@track contact;
//Conditional status
@track isLoading = false;
@track valueSelected = false;
@track showClaimAmount = false;
//Forms
@track productList = productList;
@track showOnboardingForm = false;
@track showTransferenciasForm = false;
@track showDefaultForm = false;
@track productSelected = false;
@track selectedProduct = '';
//Records
@track selectedRecord;
//Buttons
@track firstStep = false;
@track secondStep = false;
//Other Data Needed
caseRecordTypes;
@track userId = Id;
@track existingQueues;
@track recordList;
@track showMessage = false;
//Case Object
@track newCase = {
    AccountId: '',
    Subject: '',
    RecordTypeId: '',
    Description: '',
    Origin: 'Teléfono',
    Status:'',
    CurrencyIsoCode: 'PYG',
    ClaimAmount__c: 0.00,
    SubProduct__c: '',
    Product__c: '',
    Type: '',
    Casuistry__c: '',
    Reference_Number__c: '',
    Operation_date__c: '',
    Fee_type__c: '',
    Reception_Account__c: '',
    ContactId: '',
    OwnerId: ''
}
    connectedCallback(){
        this.getAccountInformation();
    }

    @wire(IsConsoleNavigation) isConsoleNavigation;


    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    function({error,data}){
        if(data){
            this.caseRecordTypes = data.recordTypeInfos;
        }else if(error){
            console.log(error)
            showErrorMessage('Error', error?.body?.message)
        }
    };

    getAccountInformation(){
        this.isLoading = true;
        this.getConsoleTabsInfo();

        setTimeout(() => {

            if(this.recordId && this.recordId.startsWith('001')){
                getExistingQueues()
                .then( result => {
                    if(result.length > 0){
                        this.existingQueues = result;
                    }
                })
                .catch(error => {
                    console.log(error);
                    showErrorMessage('Error', error?.body?.message)
                })

                getPersonAccountContact({accountId: this.recordId})
                .then( result => {
                    if(result != null){
                        this.contact = result;
                    }
                })
                .catch(error =>{
                    console.log(error)
                    showErrorMessage('Error', error?.body?.message)
                })

                this.isLoading = false;
                this.firstStep = true;
            } else {
                this.isLoading = false;
                this.showMessage = true;
            }

        }, "2000");
    }

    handleValueSelectedTipificadores(event) {
        this.selectedRecord = event.detail;
        this.valueSelected = true;

        for (const key in this.selectedRecord) {
              switch(key){
                  case 'CaseStatus__c':
                    this.newCase.Status = this.selectedRecord[key];
                  case 'Reason__c':
                    this.newCase.Casuistry__c = this.selectedRecord[key];
                  case 'Product__c':
                    this.newCase.Product__c = this.selectedRecord[key];
                  case 'Type__c':
                    this.newCase.SubProduct__c = this.selectedRecord[key].trim();
                  case 'RecordType__c':
                    this.newCase.Type = this.selectedRecord[key];
              }
        }

        for (const [key, value] of Object.entries(this.caseRecordTypes)) {
            const formattedContactType = this.newCase.Type.includes('_') ? this.newCase.Type.replace(/_/g, " ") : this.newCase.Type;

            if (this.caseRecordTypes[key].name == formattedContactType) {
                this.newCase.RecordTypeId = this.caseRecordTypes[key].recordTypeId;
                break;
            }

        }

        if(this.selectedRecord.CaseOwnerQueue__c != '' && this.selectedRecord.CaseOwnerQueue__c != undefined && this.selectedRecord.CaseOwnerQueue__c != null){

            for(const key in this.existingQueues){
                if(this.existingQueues[key].DeveloperName == this.selectedRecord.CaseOwnerQueue__c){
                    this.newCase.OwnerId = this.existingQueues[key].Id;
                    break;
                }
            }

        }else {

            this.newCase.OwnerId = this.userId;
        }

        if(this.recordId){
            this.newCase.AccountId = this.recordId;
        }

        if(this.contact){
             this.newCase.ContactId = this.contact.Id;
        }

        if(this.newCase.Product__c == 'Transferencias'){
            this.showDefaultForm = false;
            this.showOnboardingForm = false;
            this.showTransferenciasForm = true;
        } else {
          this.showDefaultForm = true;
          this.showOnboardingForm = false;
          this.showTransferenciasForm = false;
       }
//        else if (this.newCase.Product__c == 'Transferencias'){
//            this.showDefaultForm = false;
//            this.showOnboardingForm = false;
//            this.showTransferenciasForm = true;
//        }


    }

    handleValueDeleted(event){
        this.selectedRecord = event.detail;
        this.valueSelected = false;
    }

    handleChange(event){
       const fieldChanged = event.detail.fieldName
       const newFieldValue = event.detail.value
       this.newCase[fieldChanged] = newFieldValue;

    }

    onNext(){
        this.isLoading = true;
        this.firstStep = false;

        setTimeout(() => {
          this.secondStep = true;
          this.isLoading = false;
        }, "1000");

    }

    onBack(){
        this.isLoading = true;
        this.secondStep = false;
        this.selectedProduct = '';
        for(const key in this.newCase){
                switch(key){
                    case 'ClaimAmount__c':
                        this.newCase[key] = 0.00;
                    case 'CurrencyIsoCode':
                        this.newCase[key] = 'PYG';
                    case 'Origin':
                        this.newCase[key] = 'Teléfono';
                   default:
                        this.newCase[key] = '';
                }
        }

        setTimeout(() => {
            this.firstStep = true;
            this.isLoading = false;
            this.valueSelected = false;
            this.selectedRecord = null
        }, "1000");
    }

    onSave() {

    this.isLoading = true;
    let hasError = false;
    const fields = this.newCase;
    const recordInput = { apiName: CASE_OBJECT.objectApiName, fields };

    for (const key in fields) {
        const fieldValue = fields[key];

        if (!fieldValue) {
            switch (key) {
                case 'ClaimAmount__c':
                    if (['Reclamo', 'Reclamo_Fraude'].includes(fields.Type) && fields.Product__c != 'Onboarding') {
                        hasError = true;
                    }
                    console.log(key)
                    break;
                case 'ContactId':
                    if (this.contact?.IsPersonAccount) {
                        hasError = true;
                    }
                    break;
                case 'Reference_Number__c':
                    if (fields.Product__c === 'Transferencias') {
                        hasError = true;
                    }
                case 'Operation_date__c':
                    if (fields.Product__c === 'Transferencias') {
                        hasError = true;
                    }
                case 'Fee_type__c':
                    if (fields.Product__c === 'Transferencias') {
                        hasError = true;
                    }
                case 'Reception_Account__c':
                    if (fields.Product__c === 'Transferencias') {
                        hasError = true;
                    }
                    break;
                default:
                    break;
            }

            if (hasError) break;
        }
    }


        // Create the case record
        if(hasError){
            showToastMessage('Error', 'Todos los campos obligatorios (*) deben ser completados.', 'Error', 'dismissable', this);
            this.isLoading = false;
        } else {
            createRecord(recordInput)
            .then(caseRecord => {
                this.isLoading = false;

                showToastMessage('Caso Creado', 'El caso se ha creado exitosamente.', 'Success', 'dismissable', this);
                this.navigateToSubtab(caseRecord.id);

//                setTimeout(() => {
//
//                    this.closeTab();
//                }, "2000");

            })
            .catch(error => {
                console.log(error)
                this.isLoading = false;
                showErrorMessage('Error', error?.body?.message)
            });
        }
    }

    get options() {
        return [
            { label: 'Cuentas', value: 'Cuentas' },
            { label: 'NFC', value: 'NFC' },
            { label: 'Onboarding', value: 'Onboarding' },
            { label: 'Pago de Servicios', value: 'Pago de servicios' },
            { label: 'Préstamos', value: 'Préstamos' },
            { label: 'Transferencias', value: 'Transferencias' },
            { label: 'QR', value: 'QR' },
            { label: 'Seguridad', value: 'Seguridad' },
            { label: 'Tarjetas', value: 'Tarjetas' }
        ].sort((a, b) => a.label.localeCompare(b.label));
    }

    handleProductChange(event) {
        this.selectedProduct = event.detail.value;

        getTipificadores({product: this.selectedProduct})
        .then( result => {
            this.recordList = result;
        })
        .catch( error => {
            console.log(error)
            showErrorMessage('Error', error?.body?.message)

        })

    }

     async closeTab() {
        if (!this.isConsoleNavigation) {
            return;
        }
        await closeTab(this.subTabId);
     }

     async getConsoleTabsInfo() {
        const currentTabInfo =  await getFocusedTabInfo();

        if(currentTabInfo.isSubtab){
            const primaryTabInfo = await getTabInfo(currentTabInfo.parentTabId);
            this.parentTabId = primaryTabInfo.tabId;
        } else {
            this.parentTabId = currentTabInfo.tabId;
        }

        this.recordId = currentTabInfo.pageReference.attributes.recordId;
        this.subTabId = currentTabInfo.tabId;

     }

     async navigateToSubtab(caseId) {
         await openSubtab(this.parentTabId, { recordId: caseId, focus: true });
     }

}