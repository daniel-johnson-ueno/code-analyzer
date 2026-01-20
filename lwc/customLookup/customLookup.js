import { LightningElement, api, track } from 'lwc';
/** The delay used when debouncing event handlers before invoking Apex. */
const DELAY = 500;


export default class CustomLookup extends LightningElement {

    @api helpText = "";//custom search lookup
    @api label = "";//Parent Account
    @api required;
    @api selectedIconName = "";//standard:account
    @api objectLabel = "";//Account
    @api recordsList = [];
    selectedRecordName;

    @api objectApiName = "";//Account
    @api mainField = "";//Name
    @api subFields = "";//Industry
    @api otherFields = ""
    @api searchString = "";
    @api selectedRecordId = "";
    @track selectedRecord;
    @track filterRecords = [];

    preventClosingOfSearchPanel = false;


    get showRecentRecords() {
        if (!this.filterRecords) {
            return false;
        }
        return this.filterRecords.length > 0;
    }



    filterHandler(){
        const normalizedSearchString = this.searchString.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");

        let records = this.recordsList.filter(v=>{
            return v.mainField.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "").includes(normalizedSearchString) ||
            v.subField.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "").includes(normalizedSearchString)
        })
        if(records.length > 0){
            this.filterRecords = records;
        } else {
            this.filterRecords = [];
        }

    }

    get isValueSelected() {
        return this.selectedRecordId;
    }

    //handler for calling apex when user change the value in lookup
    handleChange(event) {
        this.searchString = event.target.value;
        this.filterHandler();

    }

    //handler for clicking outside the selection panel
    handleBlur() {
        this.filterRecords = [];
        this.preventClosingOfSearchPanel = false;
    }

    //handle the click inside the search panel to prevent it getting closed
    handleDivClick() {
        this.preventClosingOfSearchPanel = true;
    }

    //handler for deselection of the selected item
    handleCommit() {
        this.selectedRecordId = "";
        this.selectedRecordName = "";
        this.selectedRecord = "";

        // Creates the event
        const selectedEvent = new CustomEvent('valuedeleted', {
            detail: this.selectedRecord
        });
        //dispatching the custom event
        this.dispatchEvent(selectedEvent);
    }

    //handler for selection of records from lookup result list
    handleSelect(event) {

        let currentRecordId = event.currentTarget.dataset.id || event.detail.id;

        let records = [...this.filterRecords];
        records.forEach( r => {
            if(currentRecordId == r.id){
                this.selectedRecord = r.otherFields;
            }
        })

        let selectedRecord = {
            mainField: this.selectedRecord.Key__c,
            subField: this.selectedRecord.RecordType__c,
            id: this.selectedRecord.Id
        };

        this.selectedRecordId = selectedRecord.id;
        this.selectedRecordName = selectedRecord.mainField;
        this.filterRecords = [];

        // Creates the event
        const selectedEvent = new CustomEvent('valueselected', {
            detail: this.selectedRecord
        });
        //dispatching the custom event
        this.dispatchEvent(selectedEvent);
    }

    //to close the search panel when clicked outside of search input
    handleInputBlur(event) {
        // Debouncing this method: Do not actually invoke the Apex call as long as this function is
        // being called within a delay of DELAY. This is to avoid a very large number of Apex method calls.
        window.clearTimeout(this.delayTimeout);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            if (!this.preventClosingOfSearchPanel) {
                this.filterRecords = [];
            }
            this.preventClosingOfSearchPanel = false;
        }, DELAY);
    }
}