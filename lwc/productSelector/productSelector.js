import { LightningElement, api, wire, track } from 'lwc';
import getOpportunityLineItems from '@salesforce/apex/ProductSelectorController.getOpportunityLineItems';
import refreshOpportunityLineItems from '@salesforce/apex/ProductSelectorController.refreshOpportunityLineItems';
import deleteOpportunityLineItem from '@salesforce/apex/ProductSelectorController.deleteOpportunityLineItem';
import updateLineItemPrice from '@salesforce/apex/ProductSelectorController.updateLineItemPrice';

import addProductToOpportunity from '@salesforce/apex/ProductSelectorController.addProductToOpportunity';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import AddProductModal from 'c/addProductModal';
import OWNER_COMPANY_NAME_FIELD from '@salesforce/schema/Opportunity.Owner.CompanyName';

import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = ['Opportunity.Pricebook2Id', 'Opportunity.StageName', 'Opportunity.CurrencyIsoCode', 
                'Opportunity.Pricebook2Id', 'Opportunity.CampaignId', 
                'Opportunity.RecordType.DeveloperName', 'Opportunity.OwnerId', 
                'Opportunity.Account.RecordType.DeveloperName', OWNER_COMPANY_NAME_FIELD];
const ENABLED_STAGES = ['Nuevo', 'Asignación'];
const ENABLED_COMERTIAL_TYPE = ['Ueno Bank'];


export default class ProductSelector extends LightningElement {
    @api recordId; // OpportunityId
    @track existingLineItems = [];
    @track isLoading = false;
    @track stageName = '';
    @track updatedPrices = {};
    @track hasCampaign = false;

    pricebook2Id;
    recordTypeDeveloperName;
    oppOwnerId;
    accountType;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredOpportunity({ error, data }) {
        if (data) {
            this.pricebook2Id = data.fields.Pricebook2Id.value;
            this.stageName = data.fields.StageName.value;
            this.recordTypeDeveloperName = data.fields.RecordType.value.fields.DeveloperName.value;
            this.oppOwnerId = data.fields.OwnerId.value;
            this.accountType = data.fields.Account?.value?.fields?.RecordType?.value?.fields?.DeveloperName?.value;
            this.ownerCompanyName = data.fields.Owner.value.fields.CompanyName.value;
            this.hasCampaign = data.fields.CampaignId.value ? true : false;
            console.log('hasCampaign: ', this.hasCampaign);
        } else if (error) {
            console.error('Error al obtener Pricebook2Id:', error);
        }
    }

    @wire(getOpportunityLineItems, { opportunityId: '$recordId' })
    wiredLineItems({ data, error }) {
        if (data) {
            debugger;
            this.existingLineItems = data;
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    get hasExistingProducts() {
        return this.existingLineItems.length > 0;
    }

    get existingLineItemsFormatted() {
        return this.existingLineItems.map(item => ({
            ...item
            
        }));
    }

    
    async openAddProductModal() {
        try {
            const result = await AddProductModal.open({
                size: 'medium', // o small/medium
                description: 'Add Products',
                recordId: this.recordId,
                pricebook2Id: this.pricebook2Id,
                itemsSelected: this.existingLineItems,
                ownerId: this.oppOwnerId,
                accountType: this.accountType,
                showDeleteModal : false

            });

            if (result && result.action === 'save') {
                this.isLoading = true;
                const { opportunityId, pricebookEntryId, quantity, unitPrice } = result.data;
                this.handleAddProduct({
                    detail: {
                        opportunityId,
                        pricebookEntryId,
                        quantity,
                        unitPrice
                    }
                });
            }
            if (result && result.action === 'error') {
                this.isLoading = false;
                this.showToast('Error', result.message, 'error');
        
            }
            
        } catch (error) {
            this.isLoading = false;

            console.error('--- ERROR DETALLADO ---');
            console.error('Mensaje:', error.message); // Mensaje principal
            console.error('Stack:', error.stack); // Traza de llamadas
            console.error('Tipo:', typeof error); // Tipo de objeto
            console.error('Stringify:', JSON.stringify(error, Object.getOwnPropertyNames(error))); // Todos las propiedades
            
            const errorDetails = {
                message: error.message,
                stack: error.stack,
                name: error.name,
                ...error
            };
            console.error('Error completo:', errorDetails);
            
            this.showToast('Error', 'No se pudo abrir el modal', 'error');
            
        }
    }

    handleAddProduct(event) {
        this.isLoading = true;

        if(this.existingLineItems.length > 0) {
            deleteOpportunityLineItem({
                oppLineItemId: this.existingLineItems[0].Id
            })
            .then(result => {
                this.addProduct(event);
            })
            .catch(error => {
                console.error('Error al elimina producto:', error);
                this.showToast('Error', 'No se pudo actualizar el producto', 'error');
            });
        }
        else {
            this.addProduct(event);
        }
    }

    addProduct(event) {
        const { opportunityId, pricebookEntryId, quantity, unitPrice } = event.detail;

        addProductToOpportunity({
            oppId: opportunityId,
            pbEntryId: pricebookEntryId,
            qty: quantity,
            price: unitPrice
        })
        .then(() => {
            this.showToast('Éxito', 'Producto agregado correctamente', 'success');
            // Refrescar los productos existentes
            return refreshOpportunityLineItems({ opportunityId: this.recordId });
        })
        .then(result => {
            
            this.existingLineItems = result;
            this.isLoading = false;

        })
        .catch(error => {
            console.error('Error al agregar producto:', error);
            this.isLoading = false;
            this.showToast('Error', 'No se pudo agregar el producto. Intenta nuevamente', 'error');
        });
    }

    refreshOpportunityItems() {
        refreshOpportunityLineItems({ opportunityId: this.recordId })
        .then(result => {            
            this.existingLineItems = result;
            this.isLoading = false;

        })
        .catch(error => {
            console.error('Error al agregar producto:', error);
            this.isLoading = false;
            this.showToast('Error', 'No se pudo agregar el producto', 'error');
        });    
    }


    handlePriceChange(event) {
        debugger;
        const itemId = event.target.dataset.id;
        const newValue = parseFloat(event.target.value);
        this.updatedPrices[itemId] = newValue;
    }

    handlePriceBlur(event) {
        debugger;
        this.isLoading = true;
        const input = event.target;
        const lineItemId = input.dataset.id;
        input.disabled = true;

        const newPrice = this.updatedPrices[lineItemId];
        if (newPrice !== undefined) {
            updateLineItemPrice({ lineItemId, newPrice })
                .then(() => {
                    this.showToast('Success', 'Precio de Venta actualizado', 'success');
                    this.isLoading = false;
                })
                .catch(error => {
                    this.isLoading = false;
                    console.error(error);
                    this.showToast('Error', 'No se pudo actualizar el Precio de Venta', 'error');
                });
        }else {
            this.isLoading = false;

        }
    }

    enablePriceEdit(event) {
        const lineItemId = event.currentTarget.dataset.id;
        const input = this.template.querySelector(`lightning-input[data-id="${lineItemId}"]`);
        if (input) {
            input.disabled = false;
            setTimeout(() => input.focus(), 0); // Forzar el foco después de habilitar
        }
    }

    async handleDeleteAll() {
        // Lógica para eliminar todos los productos o mostrar un modal de confirmación
        console.log('Eliminar productos');

        this.isLoading = true;

        try {
            const result = await AddProductModal.open({
                size: 'medium', 
                description: 'delete Products',
                recordId: this.recordId,
                pricebook2Id: this.pricebook2Id,
                itemsSelected: this.existingLineItems,
                ownerId: this.oppOwnerId,
                accountType: this.accountType,
                showDeleteModal : true //abre modal  para eliminar todos los productos
            });

            if (result && result.action === 'delete') {
                deleteOpportunityLineItem({
                    oppLineItemId: this.existingLineItems[0].Id
                })
                .then(resultdelete => {
                    
                    this.showToast('success', 'Producto eliminado', 'success');
                    this.refreshOpportunityItems();
                    this.isLoading = false;

                        window.location.reload();

                })
                .catch(error => {
                    console.error('Error al elimina producto:', error);
                    this.showToast('Error', 'No se pudo actualizar el producto', 'error');
                    this.isLoading = false;

                });
            }
            if (result && result.action === 'error') {
                this.isLoading = false;
                this.showToast('Error', result.message, 'error');
        
            }
            else {
                this.isLoading = false;
            }
            
        } catch (error) {
            this.isLoading = false;

            console.error('--- ERROR DETALLADO ---');
            console.error('Mensaje:', error.message);
            
            this.showToast('Error', 'No se pudo abrir el modal', 'error');
            
        }

        
    }

    get isDisabled() {
        debugger
        const isOnboarding = this.recordTypeDeveloperName === 'Onboarding';
        const isUpay = this.recordTypeDeveloperName === 'upay';
        const isStageValid = ENABLED_STAGES.includes(this.stageName);
        const isComertialUeno = ENABLED_COMERTIAL_TYPE.includes(this.ownerCompanyName);
        //return isOnboarding || !isStageValid || !isComertialUeno;
        if (isOnboarding || isUpay) {
           //se requiere etapa válida
            return !isStageValid;
        } else {
            // Para otros casos, se requiere que sea comercial
            return !isComertialUeno;
        }
    }

    get isEnableToDelete() {
        return this.existingLineItems.length > 0 
                && ENABLED_STAGES.includes(this.stageName) 
                && this.recordTypeDeveloperName !== 'upay';
    }

    get isDisabledToChangeProduct() {
        return this.isDisabled || this.hasCampaign;
    }

    
}