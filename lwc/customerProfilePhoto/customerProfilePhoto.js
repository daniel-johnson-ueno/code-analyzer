import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import uploadAccountSelfie from '@salesforce/apex/UpdateAccountSelfieController.uploadAccountSelfie';

const PERSON_CODE_FIELD = 'Account.PersonCode__c';
const PROFILE_PHOTO_URL_FIELD = 'Account.Profile_Photo_URL__c';
const SELFIE_ID_FIELD = 'Account.Selfie_Id__c';
const FIRST_NAME_FIELD = 'Account.FirstName';
const LAST_NAME_FIELD = 'Account.LastName';
const FIELDS = [PERSON_CODE_FIELD, PROFILE_PHOTO_URL_FIELD, SELFIE_ID_FIELD, FIRST_NAME_FIELD, LAST_NAME_FIELD];

export default class CustomerProfilePhoto extends LightningElement {
    @api recordId;
    account;

    @track _isLoading = false;
    @track _hasError = false;
    @track _photoUrl = '';

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredAccount({ error, data }) {
        if (data) {
            this.account = data;
            this.handlePhotoUrl();
        } else if (error) {
            console.error('Error fetching account:', error);
            this._hasError = true;
        }
    }

    get nameInitials() {
        const firstName = getFieldValue(this.account, FIRST_NAME_FIELD);
        const lastName = getFieldValue(this.account, LAST_NAME_FIELD);
        const firstInitial = firstName ? firstName.charAt(0).toUpperCase() : '';
        const lastInitial = lastName ? lastName.charAt(0).toUpperCase() : '';
        return `${firstInitial}${lastInitial}`;
    }

    get isLoading() {
        return this._isLoading;
    }

    get photoUrl() {
        return this._photoUrl;
    }

    get hasError() {
        return this._hasError;
    }

    handlePhotoUrl() {
        const profilePhotoUrl = getFieldValue(this.account, PROFILE_PHOTO_URL_FIELD);

        if (profilePhotoUrl) {
            this._photoUrl = profilePhotoUrl;
        } else {
            this.tryUploadSelfie();
        }
    }

    tryUploadSelfie() {
        const personCode = getFieldValue(this.account, PERSON_CODE_FIELD);
        const selfieId = getFieldValue(this.account, SELFIE_ID_FIELD);
        
        console.log(`person Code ${personCode} selfieId: ${selfieId}`);
        if (selfieId || personCode) {
            this._isLoading = true;
            uploadAccountSelfie({ accountId: this.recordId, personCode, selfieId })
                .then(response => {
                    this._isLoading = false;
                    if (!response) {
                        this._hasError = true;
                    } else {
                        this._photoUrl = response;
                    }
                })
                .catch(error => {
                    console.error('Error uploading selfie:', error);
                    this._isLoading = false;
                    this._hasError = true;
                });
        }
    }

    get shouldShowInitials() {
        return !this._photoUrl;
    }
}