import { LightningElement, track, wire, api } from 'lwc';
import getFilteredMembers from '@salesforce/apex/CampaignMemberController.getFilteredMembers';
import searchCampaignMembersByName from '@salesforce/apex/CampaignMemberController.searchCampaignMembersByName';
import getUserPermissionsSet from '@salesforce/apex/CampaignMemberController.getUserPermissionsSet';
import getMetadataProfiles from '@salesforce/apex/CampaignMemberController.getMetadataProfiles';
import CampaignMemberListViewModal from 'c/campaignMemberListViewModal';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const VIEW_OPTIONS = [
    { label: 'Todos', value: 'AsignadosAmi' },
    { label: 'Convertidos', value: 'Convertidos' },
    { label: 'No interesados', value: 'No Interesados' },
    { label: 'Pendientes', value: 'Pendientes' },
    { label: 'Todos los miembros de campaña pendientes', value: 'Todos los Pendientes' }
    
];

const COLUMNS = [
    {
        label: 'Miembro Campaña',
        fieldName: 'miembroCampanaUrl',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'miembroCampanaLabel' }
        },
        hideDefaultActions: true
    },{
        label: 'CampaignId',
        fieldName: 'campanaURL',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'campanaLabel' }
        },
        hideDefaultActions: true
    },
    { label: 'Estado', fieldName: 'Status', hideDefaultActions: true },
    { label: 'Subestado', fieldName: 'Substatus__c', hideDefaultActions: true },
    { label: 'Prioridad', fieldName: 'Priority__c', hideDefaultActions: true },
    
    //{ label: 'Comentarios', fieldName: 'Comments__c', hideDefaultActions: true },
    {
        label: 'Comentarios',
        fieldName: 'Comments__c_Short',
        cellAttributes: {
            title: { fieldName: 'Comments__c' } // Tooltip con el texto completo
        },
        hideDefaultActions: true
    },
    { label: 'Teléfono', fieldName: 'Phone', hideDefaultActions: true },
    { label: 'Correo', fieldName: 'Email', hideDefaultActions: true },
    { label: 'Tipo de Contacto', fieldName: 'InteractionType__c', hideDefaultActions: true },
    { label: 'Interacción Braze', fieldName: 'BrazeInteraction__c', hideDefaultActions: true },
    { label: 'Fecha de vencimiento', fieldName: 'DueDate__c', hideDefaultActions: true },
    { label: 'Periodo de Ingreso', fieldName: 'EntryPeriod__c', hideDefaultActions: true },
    
    { label: 'Ejecutivo Asignado', fieldName: 'ejecutivoAsignadoNombre', hideDefaultActions: true }
];

export default class campaingMembersCustomListView extends LightningElement {
    selectedView = 'AsignadosAmi';
    @track members = [];
    @track error;
    selectedRows = []; 

    selectedIds = new Set(); 
    isDisabled = true;
    isLoading = true;


    columns = COLUMNS;

    hasResults = false;
    @track isAdmin = false;
    @track hideCheckbox = true;


    userPermissionsSet;
    metadataProfiles = [];
    dataLoaded = {
        profile: false,
        metadata: false
    };


    @wire(getUserPermissionsSet)
    wiredProfile({ error, data }) {
        debugger;
        if (data) {
            this.userPermissionsSet = data;
            this.dataLoaded.profile = true;
            this.checkAdminStatus();
        } else if (error) {
            console.error('Error obteniendo perfil', error);
        }
    }



    @wire(getMetadataProfiles)
    wiredMetadataProfiles({ error, data }) {
        debugger;
        if (data) {
            this.metadataProfiles = data;
            this.dataLoaded.metadata = true;
            this.checkAdminStatus();
        } else if (error) {
            console.error('Error obteniendo perfiles de metadata', error);
        }
    }

    checkAdminStatus() {
        if (this.dataLoaded.profile && this.dataLoaded.metadata) {
            this.isAdmin = (this.metadataProfiles || []).some(meta =>
                meta.IsManager__c === true &&
                (this.userPermissionsSet || []).some(ps =>
                    ps?.PermissionSet?.Name === meta.DeveloperName
                )
            );
            this.hideCheckbox = !this.isAdmin; 

            this.loadMembers();
        }
    }

    handleViewChange(event) {
        this.selectedView = event.detail.value;
        this.loadMembers();
    }

    // método utilitario reutilizable
    parseCampaignMembers(rawMembers) {
        return rawMembers.map(member => {
            const linkRegex = /<a\s+href="([^"]+)"[^>]*>(.*?)<\/a>/i;
            const match = linkRegex.exec(member.CampaignMember__c || '');
            const miembroCampanaUrl = match ? match[1] : '';
            const miembroCampanaLabel = match ? match[2] : '';
            const ejecutivoAsignadoNombre = member.AssignedExecutive__r?.Name || '';

            const fullComment = member.Comments__c || '';
            const firstLine = fullComment.slice(0, 100);
            const secondLine = fullComment.slice(100, 200);
            return {
                ...member,
                Comments__c_Short: member.Comments__c?.length > 100
                    ? member.Comments__c.slice(0, 100) + '...'
                    : member.Comments__c,

                miembroCampanaUrl,
                miembroCampanaLabel,
                campanaURL: '/' + member.CampaignId,
                campanaLabel: member.Campaign?.Name,
                ejecutivoAsignadoNombre
            };
        });
    }

    loadMembers() {
        this.isLoading = true;
        getFilteredMembers({ viewType: this.selectedView })
            .then(result => {
                this.members = this.parseCampaignMembers(result);
                this.hasResults = this.members.length > 0;
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                this.members = [];
                this.hasResults = false;
                this.showToast('Error', 'Error en la carga de miembros de campaña: ' + error.body?.message || error.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleSearch() {
        this.isLoading = true;
        searchCampaignMembersByName({
            name: this.searchName,
            viewType: this.selectedView
        })
        .then(result => {
            this.members = this.parseCampaignMembers(result);
            this.hasResults = this.members.length > 0;
            this.error = undefined;
        })
        .catch(error => {
            this.error = error;
            this.members = [];
            this.hasResults = false;
            this.showToast('Error', 'Error al buscar miembros: ' + error.body?.message || error.message, 'error');
        })
        .finally(() => {
            this.isLoading = false;
        });
    }


    handleSearchChange(event) {
        this.searchName = event.target.value;
        this.handleSearch();
    }


    handleRowSelection(event) {
        // Limpia el Set primero para empezar desde cero
        this.selectedIds.clear();
        
        event.detail.selectedRows.forEach(row => {
            this.selectedIds.add(row.Id);
        });
        
        this.selectedRows = Array.from(this.selectedIds);
        
        this.isDisabled = this.selectedRows.length === 0;
    }

    changAssignedExecutive() {

    }

    async openChangeExecutiveModal() {
        try {
            const result = await CampaignMemberListViewModal.open({
                size: 'medium', // o small/medium
                description: 'Change Members',
                selectedCampaignMemberIds: this.selectedRows 

            });

            if (result && result.action === 'save') {
                this.selectedRows = [];
                this.isDisabled = this.selectedRows.length < 1; 

                this.loadMembers();
            }
            if (result && result.action === 'error') {
                this.showToast('Error', 'Debes seleccionar un producto', 'error');
                this.isLoading = false;
                this.selectedRows = [];
                this.isDisabled = this.selectedRows.length < 1; 

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

    get viewOptions() {
        // Si es admin/gerente, mostrar todas las opciones
        if (this.isAdmin) {
            return VIEW_OPTIONS;
        }
        // Si no es admin/gerente, filtrar la opción de administrador
        return VIEW_OPTIONS.filter(option => option.value !== 'Todos los Pendientes');
    }


    showToast(title,message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }

}