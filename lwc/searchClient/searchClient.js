import { LightningElement, api, wire, track } from 'lwc';
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getAccountId from '@salesforce/apex/SearchClientServiceController.getAccountId';
import createAccountSF from '@salesforce/apex/SearchClientServiceController.createAccountSF';
import getCompanies from '@salesforce/apex/SearchClientServiceController.getCompanies';
import updateCaseWithAccount from '@salesforce/apex/SearchClientServiceController.updateCaseWithAccount';
import getAccountById from '@salesforce/apex/SearchClientServiceController.getAccountById';
import DOC_TYPE from "@salesforce/schema/Lead.Document_Type__c";
import getAccountPermission from '@salesforce/apex/SearchClientServiceController.getPermission';

//labels
import searchClientHomeTitle from '@salesforce/label/c.searchClientHomeTitle';
import searchClientHomeSubTitle from '@salesforce/label/c.searchClientHomeSubTitle';
import searchClientFoundAccountHome from '@salesforce/label/c.searchClientFoundAccountHome';
import searchClientFoundAccountHomeDesc from '@salesforce/label/c.searchClientFoundAccountHomeDesc';
import searchClientNotFound from '@salesforce/label/c.searchClientNotFound';
import searchClientNotFoundDesc from '@salesforce/label/c.searchClientNotFoundDesc';
import searchClientNotFoundNote from '@salesforce/label/c.searchClientNotFoundNote';
import searchClientCaseTitle from '@salesforce/label/c.searchClientCaseTitle';
import searchClientCaseSubTitle from '@salesforce/label/c.searchClientCaseSubTitle';
import searchClientFoundAccountCaseDesc from '@salesforce/label/c.searchClientFoundAccountCaseDesc';
import searchClientFoundAccountCaseNote from '@salesforce/label/c.searchClientFoundAccountCaseNote';
import searchClientAccountCreationTitle from '@salesforce/label/c.searchClientAccountCreationTitle';
import searchClientAccountCreationSubTitle from '@salesforce/label/c.searchClientAccountCreationSubTitle';
import searchClientFoundAccountOnCreation from '@salesforce/label/c.searchClientFoundAccountOnCreation';
import searchClientFoundAccountOnCreationCase from '@salesforce/label/c.searchClientFoundAccountOnCreationCase';
import searchClientFoundAccountOnCreationTitle from '@salesforce/label/c.searchClientFoundAccountOnCreationTitle';
import searchClientAccountCreatedTitle from '@salesforce/label/c.searchClientAccountCreatedTitle';
import searchClientAccountCreatedSubTitle from '@salesforce/label/c.searchClientAccountCreatedSubTitle';
import searchClientSalesNotFoundDesc from '@salesforce/label/c.searchClientSalesNotFoundDesc';


export default class SearchClient extends NavigationMixin(LightningElement) {
    @api recordId;
    @api pageType;
    @track isLoading = false;
    @track isLoadingModal = false;
    @track docNumValue = '';
    @track docNumValueCreation = '';
    @track documentTypeSelectedValue;
    @track searchByPhoneIsSelected;
    @track foundAccount;
    @track createdAccount;
    @track phoneValue = '';
    @track searchByDocumentIsSelected = true;
    @track documentTypeSelectedValueLabel;
    @track showModalCreation = false;
    @track accountWasCreated = false;
    @track showDuplicateAccount = false;
    @track duplicateAccount;
    @track companySelected;
    @track buttonCreationDisabled = false;
    @track listDuplicateAccount = [];
    @track companiesOptions = [];
    @track selectedDuplicateAccount;
    @track selectedDuplicateAccountCheck = false;
    @track enableButtonLink = true;
    @track resultObject;
    @track isBussinesAccount = false;
    @track isPersonAccount = true;
    @track pageTypeService = false;
    @track buttonCreationEnabled = false;
    documentTypeSelected;
    accountId;
    accountWasSearched=false;
    disabled = true;
    documentTypes;

    label = {
        searchClientHomeTitle,
        searchClientHomeSubTitle,
        searchClientFoundAccountHome,
        searchClientFoundAccountHomeDesc,
        searchClientNotFound,
        searchClientNotFoundDesc,
        searchClientNotFoundNote,
        searchClientCaseTitle,
        searchClientCaseSubTitle,
        searchClientFoundAccountCaseDesc,
        searchClientFoundAccountCaseNote,
        searchClientAccountCreationTitle,
        searchClientAccountCreationSubTitle,
        searchClientFoundAccountOnCreation,
        searchClientFoundAccountOnCreationCase,
        searchClientFoundAccountOnCreationTitle,
        searchClientAccountCreatedTitle,
        searchClientAccountCreatedSubTitle,
        searchClientSalesNotFoundDesc
    };

    @wire(getPicklistValues, { recordTypeId: "012000000000000AAA", fieldApiName: DOC_TYPE })
    wiredPicklistValues({ error, data }) {
        if (data) {
            this.documentTypes = data.values;
            this.documentTypeSelected = this.documentTypes[0];
            this.documentTypeSelectedValue=this.documentTypeSelected.value;
            this.documentTypeSelectedValueLabel = this.getDocumentTypeLabel(this.documentTypeSelectedValue);
        } else if (error) {
            console.error('Error retrieving picklist values: ', error);
        }
    }

    connectedCallback() {
        if(this.pageType == 'SERVICE' || this.pageType == undefined){
            this.pageTypeService = true;
        }
        this.getAccountPermission();
        this.loadMetadataCompaniesRecords();
    }

    getAccountPermission(){
        getAccountPermission({permissionName: 'AllowAccountCreation'}
            ).then(result => {
                this.buttonCreationEnabled = result;
            })
            .catch(error => {
                console.log('error: ' + error);
            });
    }

    get accountWasSearchedAndFound() {
        return this.accountWasSearched&&this.foundAccount;
    }

    get accountWasSearchedAndNotFound() {
        return this.accountWasSearched&&!this.foundAccount;
    }

    get foundAccountOnCase() {
        return this.recordId && this.foundAccount && this.accountWasSearched;
    }

    get recordOnCase() {
        return this.recordId;
    }

    get recordOnCaseCreation() {
        return this.recordId;
    }

    get foundAccountOnHome() {
        return !this.recordId && this.foundAccount && this.accountWasSearched;
    }

    get initScreen() {
        return !this.accountWasCreated && !this.accountWasSearched;
    }

    get createdAccountOnCase() {
        return this.recordId && this.createdAccount && this.accountWasCreated;
    }

    get createdAccountOnHome() {
        return !this.recordId && this.createdAccount && this.accountWasCreated;
    }

    get switchButtonClass() {
        return this.searchByDocumentIsSelected ? 'switch-button' : 'switch-button right';
    }

    get showSearchButton() {
        return this.accountWasSearched && !this.accountWasCreated;
    }

    get readOnlyPhoneField() {
        return this.searchByPhoneIsSelected || this.showDuplicateAccount;
    }

    get readOnlyTypeAndDocumentField() {
        return this.searchByDocumentIsSelected || this.showDuplicateAccount;
    }

    get accountCreationButtonEnabled() {
        return this.pageTypeService && this.buttonCreationEnabled;
    }

    async loadMetadataCompaniesRecords() {
        try {
            const metadata = await getCompanies();
            const setCompanies = [...new Set(metadata.map(record => record.GroupCompaniesUeno__c))];
            this.companiesOptions = setCompanies.map(value => ({
            label: this.normCompaniesOptions(value),
            value: value
            }));
            if (this.companiesOptions.length > 0) {
                this.companySelected = this.companiesOptions[0].value;
            }
        } catch (error) {
            console.error('Error fetching metadata companies:', error);
        }
    }

    normCompaniesOptions(label) {
      if (label == 'UENO_BANK') {
            return 'Ueno Bank';
      } else {
            return label.charAt(0).toUpperCase() + label.slice(1).toLowerCase();
      }
    }

    handleCompanyChange(event) {
        this.companySelected = event.target.value;
   }

    onDocumentTypeSelectionChange(event) {
        this.handleValidationDocType();
        this.documentTypeSelected = event.detail;
        this.documentTypeSelectedValue=this.documentTypeSelected.value;
        if(this.documentTypeSelectedValue === '6') {
            this.isBussinesAccount = true;
            this.isPersonAccount = false;
        } else {
            this.isBussinesAccount = false;
            this.isPersonAccount = true;
        }
        this.documentTypeSelectedValueLabel = this.getDocumentTypeLabel(this.documentTypeSelectedValue);
    }

    onSwitchButtonChange() {
        this.searchByDocumentIsSelected = !this.searchByDocumentIsSelected;
        this.docNumValue = '';
        this.phoneValue = '';
        this.isBussinesAccount = false;
        this.isPersonAccount = false;
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

    
    handleDocNumInputChange(event) {
        this.handleValidationDocNum();
        if (/\S/.test(event.detail.value)) {
            this.docNumValue = event.detail.value;
            if (!this.documentTypeSelected) {
                this.disabled = true;
            } else {
                this.disabled = false;
            }
        } else {
            this.disabled = true;
        }
    }
    handlePhoneInputChange(event) {
        this.handleValidationPhone();
        if (/\S/.test(event.detail.value)) {
            this.phoneValue = event.detail.value;
            this.disabled = false;
        } else {
            this.disabled = true;
        }
    }
    handleClick() {
        this.isLoading = true;
        if(this.searchByDocumentIsSelected){
            if(this.docNumValue == null || this.docNumValue == undefined || this.docNumValue == '' ){
            this.isLoading = false;
            const evt = new ShowToastEvent({
                        title: 'Error',
                        message: 'Debe ingresar Número de documento.',
                        variant: 'Error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(evt);
                    return;
            } else {
                this.docNumValueCreation = this.docNumValue;
            }
        } else {
            if(this.phoneValue == null || this.phoneValue == undefined || this.phoneValue == '' ){
                this.isLoading = false;
                const evt = new ShowToastEvent({
                        title: 'Error',
                        message: 'Debe ingresar Número de Teléfono.',
                        variant: 'Error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(evt);
                    return;
            } else {
                this.docNumValue = this.phoneValue;
                this.docNumValueCreation = '';
                this.documentTypeSelectedValue = '99';
                this.searchByPhoneIsSelected = true;
                this.accountPhone = this.phoneValue;
            }
        }

        getAccountId({ documentNumber: this.docNumValue, documentType: this.documentTypeSelectedValue})
            .then((result) => {
                this.accountId = result;
                this.error = undefined;
                this.accountWasSearched=true;
                if (this.accountId) {
                    this.searchAccount(this.accountId,false);
                }
                else {
                    this.isLoading = false;
                }

            })
            .catch((error) => {
                this.error = error;
                this.accountId = undefined;
                this.isLoading = false;
                this.accountWasSearched=true;
            })

    }

    handleComanyNameChange(event) {
        this.accountLastName = event.target.value;
    }

    handleFirstNameChange(event) {
        this.accountFirstName = event.target.value;
    }

    handleLastNameChange(event) {
        this.accountLastName = event.target.value;
    }

    handleDocumentTypeChange(event) {
        this.documentTypeSelectedValue = event.detail.value;
    }

    handleDocNumberChange(event) {
        this.accountDocNum = event.target.value;
        this.docNumValue = this.accountDocNum;
    }
    
    handlePhoneChange(event) {
        this.accountPhone = event.target.value;
    }

    handleEmailChange(event) {
        this.accountEmail = event.target.value;
        if (!event.target.validity.valid) {
            this.buttonCreationDisabled = true;
        } else {
            this.buttonCreationDisabled = false;
        }
    }

    handleCreateAccount() {
        this.showModalCreation = true;
    }

    handleGlobalSearchAccount(){
        this.handleClickSearchAccount();
    }

    handleClickSearchAccount(){
        let searchQuery;
        if (this.searchByPhoneIsSelected) {
            searchQuery = this.phoneValue;
        }
        if (this.searchByDocumentIsSelected) {
            searchQuery = this.docNumValue;
        }
        let stringToEncode = '{"componentDef":"forceSearch:search","attributes":{"term":"'+searchQuery + '","scopeMap":{"type":"TOP_RESULTS"},"context": {"disableSpellCorrection":false,"SEARCH_ACTIVITY":{"term":"'+ searchQuery + '"}}}}';
        let encodedString = btoa(stringToEncode);
        let globalSearchUrl ="/one/one.app?source=alohaHeader#" +encodedString
        const url = window.location.origin + globalSearchUrl;
        window.open( url, '_self' );
    }

    navigateToAccount() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.accountId,
                objectApiName: 'Account',
                actionName: 'view'
            }
        }, true);
    }

    navigateToCase(caseId) {
        const url = window.location.origin + '/lightning/r/Case/' + caseId + '/view';
        window.open(url, '_self');
    }

    handleAssociateAccountToCase(){
        this.isLoading = true;
        updateCaseWithAccount({ accountId: this.accountId, recordId:this.recordId })
        .then((result) => {
                if (result != null) {
                    console.log('result result result ' + result.Id);
                    this.navigateToCase(result.Id);
                } 
                this.isLoading = false;
            })
        .catch((error) => {
                console.log('catch error: ' + error);
                this.error = error;
                this.accountId = undefined;
                this.isLoading = false;
                this.accountWasSearched=true;
            })
        this.isLoading = false;
    }

    searchAccount(accountId, isCreated) {
        getAccountById({ accountId: accountId }).then(
            res => {
                if (isCreated) {
                    this.createdAccount = res;
                } else {
                    this.foundAccount = res;
                }
                this.isLoading = false;
            }
        )
    }

    searchAnotherAccount() {
        this.documentTypeSelectedValue = this.documentTypeSelected.value;
        this.docNumValue = undefined;
        this.accountFirstName = undefined;
        this.accountLastName = undefined;
        this.accountPhone = undefined;
        this.foundAccount = undefined;
        this.accountWasSearched=false;
        this.phoneValue = undefined;
        this.searchByPhoneIsSelected = false;
        this.showDuplicateAccount = false;
        if(this.documentTypeSelected.value == '6'){
            this.isBussinesAccount = true;
        } else {
            this.isPersonAccount = true;
        }
    }

    closeModal() {
        this.showModalCreation = false;
    }

    cancelAccountCreation() {
        this.showModalCreation = false;
        this.showDuplicateAccount = false;
        this.duplicateAccount = undefined;
        this.accountId = undefined;
        this.selectedDuplicateAccount = undefined;
        this.selectedDuplicateAccountCheck = false;
        this.clearInformation();
    }

    clearInformation(){
        this.accountFirstName = undefined;
        this.accountLastName = undefined;
        this.accountPhone = undefined;
        this.phoneValue = undefined;
        this.accountEmail = undefined;
        this.enableButtonLink = true;
    }

    getDocumentTypeLabel(documentTypeValue) {
      const selectedOption = this.documentTypes.find(
         option => option.value === documentTypeValue
      );
      return selectedOption ? selectedOption.label : '';
    }


    submitAccountCreation() {
        if (this.isBussinesAccount) {
            if(this.accountLastName == undefined || this.accountLastName == '' || this.accountPhone == undefined || this.accountPhone == '' || 
            this.companySelected == undefined || this.companySelected == '' || this.accountEmail == undefined || this.accountEmail == ''){
                const evt = new ShowToastEvent({
                title: 'Atención',
                message: 'Completá todos los campos requeridos para continuar.',
                variant: 'Error',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);
            return;
            }
        } else if(this.accountFirstName == undefined || this.accountFirstName == '' || this.accountLastName == undefined || this.accountLastName == '' || this.accountPhone == undefined || this.accountPhone == '' || 
            this.companySelected == undefined || this.companySelected == '' || this.accountEmail == undefined || this.accountEmail == ''){
                const evt = new ShowToastEvent({
                title: 'Atención',
                message: 'Completá todos los campos requeridos para continuar.',
                variant: 'Error',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);
            return;
        }

        this.accountCreation();

    }

    submitBussinesAccountCreation() {
        if(this.accountLastName == undefined || this.accountLastName == '' || this.accountPhone == undefined || this.accountPhone == '' || 
            this.companySelected == undefined || this.companySelected == '' || this.accountEmail == undefined || this.accountEmail == ''){
                const evt = new ShowToastEvent({
                title: 'Atención',
                message: 'Completá todos los campos requeridos para continuar.',
                variant: 'Error',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);
        } else {
            this.accountCreation();
        }
    }

    accountCreation() {
        this.isLoadingModal = true;
        createAccountSF({ documentNumber: this.docNumValue, documentType: this.documentTypeSelectedValue, firstName: this.accountFirstName, lastName: this.accountLastName, phone: this.accountPhone, email: this.accountEmail, company: this.companySelected })
            .then((result) => {
                if(result.success){
                    this.accountId = result.accountId;
                    this.error = undefined;
                    this.showModalCreation = false;
                    this.accountWasCreated = true;
                    this.accountWasSearched = false;
                    if(this.recordId){
                        this.handleAssociateAccountToCase();
                    } else {
                        this.searchAccount(this.accountId,true);
                    }
                } else {
                    if(result.isDuplicated == true) {
                        this.accountId = result.accountId;
                        this.accountWasCreated = false;
                        this.showDuplicateAccount = true;
                        this.listDuplicateAccount = result.recordAccounts;
                    } else {
                        const evt = new ShowToastEvent({
                        title: 'Error Error',
                        message: result.message,
                        variant: 'Error',
                        mode: 'dismissable'});
                        this.dispatchEvent(evt);
                    }
                }
                this.isLoadingModal = false;
            })
            .catch((error) => {
                console.log('catch error: ' + error);
                this.error = error;
                this.accountId = undefined;
                this.isLoading = false;
                this.accountWasSearched=true;
                this.showModalCreation = false;
                this.isLoadingModal = false;
            })
    }

    handleSelectClick(event) {
        this.addRemoveSelectedCustomBox(event);
        const selectedItem = event.currentTarget.dataset.accountNumber;
        this.selectedDuplicateAccount = selectedItem;
        this.selectedDuplicateAccountCheck = true;
        this.enableButtonLink = false;
    }

    handleSelectedAccount() {
        this.accountId = this.selectedDuplicateAccount;
        this.navigateToAccount();
    }

    handleSelectedAccountToCase() {
        this.handleAssociateAccountToCase();
        this.navigateToCase(this.recordId);
    }

    addRemoveSelectedCustomBox(event) {
        const highlightedElement = this.template.querySelector('.custom-box-active');
        if (highlightedElement) highlightedElement.classList.remove('custom-box-active');
        const targetElement = event.currentTarget;
        targetElement.classList.add('custom-box-active');
    }

}