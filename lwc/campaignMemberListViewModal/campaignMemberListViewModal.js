import LightningModal from 'lightning/modal';
import { api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateCampaignMembers from '@salesforce/apex/CampaignMemberController.updateCampaignMembers'; 

export default class CampaignMemberListViewModal extends LightningModal {
    @api selectedCampaignMemberIds = [];
    @track selectedContactId;
    @track isLoading = false;

    handleOwnerChange(event) {
        this.selectedContactId = event.detail.recordId;
        console.log('this.selectedContactId: ', this.selectedContactId);
    }

    async handleSubmit() {
        if (!this.selectedContactId || this.selectedCampaignMemberIds.length === 0) {
            this.showToast('Error', 'Debe seleccionar un ejecutivo y al menos un miembro.', 'error');
            return;
        }

        this.isLoading = true;

        try {
            await updateCampaignMembers({
                campaignMemberIds: this.selectedCampaignMemberIds,
                newContactId: this.selectedContactId
            });

            this.close({ action: 'save' });
        } catch (error) {
            this.showToast('Error', 'No se pudieron actualizar los miembros.', 'error');
            console.error(error);
            this.close({ action: 'error' });
        } finally {
            this.isLoading = false;
        }
    }
    
    handleCancel() {
        this.close();
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}