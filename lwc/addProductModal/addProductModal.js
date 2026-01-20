import { wire, track, api } from 'lwc';
import getProductEntriesByPricebookId from '@salesforce/apex/ProductSelectorController.getProductEntriesByPricebookId';
import LightningModal from 'lightning/modal';
import getProductFamilyPicklistValues from '@salesforce/apex/ProductSelectorController.getProductFamilyPicklistValues';
import searchProducts from '@salesforce/apex/ProductSelectorController.searchProducts';
import getPricebooks from '@salesforce/apex/ProductSelectorController.getPricebooks';
import { updateRecord } from 'lightning/uiRecordApi';
import getOpportunityLineItems from '@salesforce/apex/ProductSelectorController.getOpportunityLineItems';

import PRICEBOOK_FIELD from '@salesforce/schema/Opportunity.Pricebook2Id';


const COLUMNS = [
    { label: 'Nombre del Producto', fieldName: 'name', hideDefaultActions: true },
    { label: 'Familia del Producto', fieldName: 'family', hideDefaultActions: true }
];


export default class AddProductModal extends LightningModal{
    @track products = [];
    @track selectedProducts = [];
    @track selectedRowIds = [];
    @track hasResults = true;

    selectedPricebookId;
    pricebookOptions = [];

    columns = COLUMNS;
    familiasOptions = []; 
    familySelected = '';
    searchName = '';

    @track
    _pricebook2Id;
    _recordId;
    _itemsSelected;
    _ownerId;
    _accountType;
    _showDeleteModal = false;
    @api
    set pricebook2Id(value) {
        this._pricebook2Id = value;
        if (value) {
            this.loadProducts();
        }
    }
    get pricebook2Id() {
        return this._pricebook2Id;
    }
    @api
    set recordId(value) {
        this._recordId = value;
    }
    get recordId() {
        return this._recordId;
    }
    @api
    set ownerId(value) {
        this._ownerId = value;
    }
    get ownerId() {
        return this._ownerId;
    }
    @api
    set itemsSelected(value) {
        this._itemsSelected = value;
    }
    get itemsSelected() {
        return this._itemsSelected;
    }

    
    @api
    set accountType(value) {
        this._accountType = value;
    }
    get accountType() {
        return this._accountType;
    }
    
    @api
    set showDeleteModal(value) {
        this._showDeleteModal = value;
    }
    get showDeleteModal() {
        return this._showDeleteModal;
    }
    



    @wire(getPricebooks, { 
        accountType: '$_accountType', 
        ownerId: '$_ownerId' 
    })
    wiredPricebooks({ error, data }) {
        debugger
        if (data) {
            this.pricebookOptions = data.map(pb => ({
                label: pb.Name,
                value: pb.Id
            }));
            
        } 
        if (error) {
            console.error('Error cargando listas de precios', error);
            this.close({
                action: 'error',
                message: 'Error al cargar listas de precios'
            });
        }
    }

    async loadOpportunityLineItems() {
        try {
            const data = await getOpportunityLineItems({ opportunityId: this.recordId });
            this.existingLineItems = data;
        } catch (error) {
            console.error('Error al cargar line items:', error);
        }
    }

    loadProducts() {
        if (!this.pricebook2Id) return;
        getProductEntriesByPricebookId({ pricebook2Id: this.pricebook2Id })
        .then(data => {
                this.products = data.map(item => ({
                    id: item.Id,
                    name: item.Product2.Name,
                    family: item.Product2.Family,
                }));
                this.error = undefined;
                this.selectInitialProduct();

                this.isLoading = false;

            })
            .catch(error => {
                this.products = [];
                this.error = error;
                this.isLoading = false;
                console.error('Error cargando productos:', error);
            });
    }

    selectInitialProduct() {
        if (this.products.length === 0) return;
        
        this.selectedRowIds = [this.products[0].id];
        this.selectedProducts = [{
            ...this.products[0],
            quantity: 1,
            unitPrice: this.products[0].unitPrice || 0.0
        }];
    }

    renderedCallback() {
        if (this._hasRendered) return;
        this._hasRendered = true;    
        this.loadProducts();
    }

    @wire(getProductFamilyPicklistValues)
    wiredFamily({ data, error }) {
        if (data) {
            this.familiasOptions = data.map(value => ({
                label: value,
                value: value
            }));
            // Opcional: Agregar una opción "Todas las familias"
            this.familiasOptions.unshift({
                label: 'Todas las familias',
                value: ''
            });
        }
    }

    handleSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedProducts = selectedRows.map(row => this.products.find(p => p.id === row.id));        
    }

    handleCancel() {
        this.close();
    }

    //*metodologia de busqueda
    // Familia/name
    // *//
    handleFamiliaChange(event) {
        this.familySelected = event.target.value;
        this.handleSearch();

    }

    handleNombreChange(event) {
        this.searchName = event.target.value;
        this.handleSearch();
    }

    handleSearch() {
        if (!this.recordId) {
            console.error('recordId no está definido');
            return;
        }
        searchProducts({
            opportunityId: this.recordId,
            family: this.familySelected,
            name: this.searchName,
            pricebook2Id: this.pricebook2Id
        })
        .then((result) => {
            if(result.length === 0) {
                this.hasResults = false;
            }
            else {
                this.hasResults = true;
            }
            this.products = result.map(p => ({
                id: p.Id,
                product2: p.Product2,
                name: p.Product2.Name,
                family: p.Product2.Family,
                unitPrice: p.UnitPrice,
                quantity: 1,
                salesPrice: p.UnitPrice,
                motivo: ''
            }));
        })
        .catch((error) => {
            console.error('Error al buscar: ', error);
        });
    }

    
    

    async handleSave() {   
        if (this.selectedProducts.length === 0) {
            this.showToast('Error', 'Debes seleccionar un producto', 'error');
            return;
        }
        
        this.loadOpportunityLineItems().then(() => {
            const hasProducts = Array.isArray(this.existingLineItems) && this.existingLineItems.length > 0;

            if (hasProducts) {
                this.close({
                    action: 'error',
                    message: 'La oportunidad ya cuenta con producto asociado.'
                });
                return;
            }

            const [product] = this.selectedProducts;
            this.close({
                action: 'save',
                data: {
                    opportunityId: this.recordId,
                    pricebookEntryId: product.id,
                    quantity: 1,
                    unitPrice: product.unitPrice || 0.0
                }
            });
        });
    }


    handlePricebookChange(event) {
        this.selectedPricebookId = event.detail.value;
    }

    async handleSavePricebook() {
        this.isLoading = true;
        debugger
        if (!this.selectedPricebookId) {
            this.isLoading = false;
            this.close({
                action: 'error',
                message: 'Debes seleccionar una lista de precios antes de continuar.'
            });
            return; // Detiene la ejecución
        }

        try {
            
            // Actualizar la oportunidad
            const fields = {};
            fields['Id'] = this.recordId;
            fields[PRICEBOOK_FIELD.fieldApiName] = this.selectedPricebookId;
            
            const recordInput = { fields };
            await updateRecord(recordInput);
            this._pricebook2Id = this.selectedPricebookId;

            // Abrir el siguiente componente
            this.loadProducts();
            
        } catch (error) {
            console.error('Error actualizando lista de precios', error);
            this.isLoading = false;
        }
    }

    async confirmDelete() {
        this.close({
            action:'delete',
            data: {opportunityId: this.recordId}
        });
    }
    
    get haspricebook2Id() {
        return this._pricebook2Id != null;
    }
}