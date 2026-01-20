import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import getOpportunities from "@salesforce/apex/OpportunitiesListViewHelper.getOpportunities";
import searchOpportunities from "@salesforce/apex/OpportunitiesListViewHelper.searchOpportunities";
import { NavigationMixin } from 'lightning/navigation';
import updateOpportunities from '@salesforce/apex/OpportunitiesListViewHelper.updateOpportunities'; // New Apex method for updating records

const COLS = [
    { label: 'Nombre', fieldName: 'Name' },
    { label: 'Cuenta', fieldName: 'AccountName' },
    { label: 'Fecha de cierre', fieldName: 'CloseDate' },
    { label: 'Monto', fieldName: 'Amount' },
    { label: 'Etapa de la oportunidad', fieldName: 'StageName' },
    { label: 'Propietario', fieldName: 'OwnerName' }  
];


export default class OpportunitiesListView  extends NavigationMixin(LightningElement) {
    cols = COLS;
    contacts = [];
    baseData = [];
    selectedIds = new Set(); 
    @track selectedRows = []; 
    @track isConfirmationModalOpen = false;
    isDisabled = true;
    @wire(getOpportunities)
    contactsWire(result) {
        this.wiredContacts = result;
        if (result.data) {
            this.baseData = result.data.map(row => this.mapContacts(row));
            this.contacts = [...this.baseData];
            this.updateSelectedRows(); 
        } 
    }

    mapContacts(row) {
        return { 
            ...row,
            Name: row.Name || '',
            AccountName: row.Account ? row.Account.Name : '',
            Amount: row.Amount|| '',
            CloseDate: row.CloseDate || '',
            StageName: row.StageName || '',
            OwnerName: row.Owner ? row.Owner.Name : ''
        };
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows.map(row => row.Id); 

        selectedRows.forEach(id => this.selectedIds.add(id)); 
    
        this.contacts.forEach(contact => {
            if (!selectedRows.includes(contact.Id) && this.selectedIds.has(contact.Id)) {
                this.selectedIds.delete(contact.Id); 
            }
        });
    
        this.selectedRows = Array.from(this.selectedIds); 
        this.isDisabled = this.selectedRows.length <= 1; 
    }
    
    handleUnselectAll() {
        this.selectedIds.clear(); 
        this.updateSelectedRows();
    }

    async handleSearch(event) {
        const searchString = event.target.value;
        try {
            if (searchString === "") {
                this.contacts = [...this.baseData]; 
            } else if (searchString.length > 1) {
                const searchOpportunitiess = await searchOpportunities({ searchString });
                this.contacts = searchOpportunitiess.map(row => this.mapContacts(row));
            }
        } catch (error) {
            this.showErrorToast('Searching error: ' + error.message);
            console.error('Error handleSearch: ', error);
        }
    
        this.updateSelectedRows();
    }
    
    updateSelectedRows() {
        this.selectedRows = this.contacts
            .filter(contact => this.selectedIds.has(contact.Id)) 
            .map(contact => contact.Id);
    
        const datatable = this.template.querySelector('lightning-datatable');
        if (datatable) {
            datatable.selectedRows = this.selectedRows;
        }
    
        this.isDisabled = this.selectedIds.size === 0; 
    }  
      
    
    get selectedContactsLen() {
        return this.selectedIds.size;
    }
    
    navigateToNewRecordPage() {
        this.isConfirmationModalOpen = true;
    }

    handleModalClose() {
        this.isConfirmationModalOpen = false;
    }

    showSuccessToast(message) {
        const event = new ShowToastEvent({
            title: 'Success',
            message: message,
            variant: 'success'
        });
        this.dispatchEvent(event);
    }

    showErrorToast(message) {
        const event = new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error'
        });
        this.dispatchEvent(event);
    }

    async handleModalSubmit(event) {
        const { OwnerId, ...rest } = event.detail.values;
    
        const updatedValues = { OwnerId: OwnerId };
        const baseUrl = window.location.origin;
        
        await updateOpportunities({ selectedIds: Array.from(this.selectedIds), updatedValues, baseUrl: window.location.origin })
        .then(result => {
            if (result.success) {
                this.showSuccessToast(result.message);
                this.dispatchEvent(new CloseActionScreenEvent({ bubbles: true, composed: true }));
                setTimeout(() => {
                    window.location.reload(); 
                }, 500);
            } else {
                this.showErrorToast(result.message);
            }
            this.isConfirmationModalOpen = false;
            this.contacts = [...this.baseData];
        }).catch(error => {
            console.error('An error occurred:', error);
            this.showErrorToast('Ha ocurrido un error. Por favor comuníquese con su administrador para más detalle.');
        });
    }
    
       
    
}