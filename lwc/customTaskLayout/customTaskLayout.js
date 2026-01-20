import { LightningElement, api, wire } from 'lwc';
import getTaskById from '@salesforce/apex/TaskController.getTaskById';
import updateTaskComments from '@salesforce/apex/TaskController.updateTaskComments';
import updateOwner from '@salesforce/apex/TaskController.updateOwner';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import OWNER_ID_FIELD from '@salesforce/schema/Task.OwnerId';
import ID_FIELD from '@salesforce/schema/Task.Id';

export default class CustomTaskLayout extends LightningElement {
    @api recordId;
    task;
    commentValue = ''; 
    isCommentDisabled = true; 
    newOwnerId = '';
    isSavingOwner = false;


    @wire(getTaskById, { taskId: '$recordId' })
    wiredTask({ error, data }) {
        if (data) {
            this.task = data;
            this.commentValue = this.task.Description;  
            console.log('this.commentValue ' + this.commentValue);
            // Verificar si el estado es Aprobado o Rechazado
            this.checkCommentEditable();
        } else if (error) {
            console.error(error);
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

    get isOwnerQueue() {
        return this.task?.OwnerId?.startsWith('00G');
    }

    get isOwnerChangeDisabled() {
        return !this.isOwnerQueue;
    }
    
    
    handleOwnerChange(event) {
        this.newOwnerId = event.detail.recordId;
    }
    
    connectedCallback() {
        if (this.task && this.isOwnerAQueue) {
            this.newOwnerId = this.task.OwnerId;
        }
    }
    
    async handleSaveOwner() {
        this.isSavingOwner = true;
        try {
            await updateOwner({ taskId: this.recordId, newOwnerId: this.newOwnerId });
            this.dispatchEvent(new ShowToastEvent({
                title: 'Éxito',
                message: 'Propietario actualizado correctamente',
                variant: 'success'
            }));
            setTimeout(() => {
                window.location.reload(); 
            }, 500);
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Usted no es el propietario de la tarea por lo cual no puede gestionarla. En el caso de que el propietario sea Legales Onboarding debe autoasignársela.',
                variant: 'error'
            }));
        } finally {
            this.isSavingOwner = false;
        }
    }    
    
    
    checkCommentEditable() {
        console.log('this.task.Status ' + this.task.Status);
        if (this.task.Status && (this.task.Status === 'Aprobado' || this.task.Status === 'Rechazado'|| this.task.Status === 'Devuelto')) {
            this.isCommentDisabled = false;  
        } else {
            this.isCommentDisabled = true; 
        }
    }

    handleCommentChange(event) {
        this.commentValue = event.target.value;
    }

    get whoDisplay() {
        return this.task?.Who?.Name || this.task?.WhoId || '';
    }

    get whatDisplay() {
        return this.task?.What?.Name || this.task?.WhatId || '';
    }

    get ownerDisplay() {
        return this.task?.Owner?.Name || this.task?.OwnerId || '';
    }

    get createdByDisplay() {
        return this.task?.CreatedBy?.Name || this.task?.CreatedById || '';
    }

    get lastModifiedByDisplay() {
        return this.task?.LastModifiedBy?.Name || this.task?.LastModifiedById || '';
    }

    get formattedActivityDate() {
        return this.formatDate(this.task?.ActivityDate);
    }

    get formattedCreatedDate() {
        return this.formatDateTime(this.task?.CreatedDate);
    }

    get formattedLastModifiedDate() {
        return this.formatDateTime(this.task?.LastModifiedDate);
    }

    get formattedStartDateTime() {
        return this.formatDateTime(this.task?.StartDateTime__c);
    }

    get formattedTimeInHours() {
        return this.formatDecimal(this.task?.Time_in_Hours__c);
    }

    get formattedTimeInDays() {
        return this.formatDecimal(this.task?.Time_in_Days__c);
    }

    formatDateTime(dateStr) {
        if (!dateStr) return '';
        const date = new Date(dateStr);
        return new Intl.DateTimeFormat('es-ES', {
            day: 'numeric',
            month: 'numeric',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
        }).format(date);
    }

    formatDate(dateStr) {
        if (!dateStr) return '';
    
        // Evita interpretación UTC usando el constructor con año, mes, día
        const [year, month, day] = dateStr.split('-').map(Number);
        const date = new Date(year, month - 1, day); // mes es base 0
    
        return new Intl.DateTimeFormat('es-ES', {
            day: 'numeric',
            month: 'numeric',
            year: 'numeric'
        }).format(date);
    }
    

    formatDecimal(value) {
        if (isNaN(value)) return '';
        return Number(value).toFixed(3);
    }

     handleSave() {
        updateTaskComments({ taskId: this.recordId, newDescription: this.commentValue })
            .then(() => {
                this.showToast('Éxito', 'Comentarios actualizados correctamente', 'success');
            })
            .catch(error => {
                this.showToast('Error', 'No se pudo actualizar los comentarios', 'error');
            });
    }
}