import { LightningElement, api, track, wire } from 'lwc';
import getCurrentUserId from '@salesforce/apex/RegisterActionPlanController.getCurrentUserId';
import getTaskById from '@salesforce/apex/RegisterActionPlanController.getTaskById';
import updateTaskStatus from '@salesforce/apex/RegisterActionPlanController.updateTaskStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class RegisterActionPlan extends LightningElement {
    @api recordId; 
    @track isAltaSelected = false;
    @track showConfirmationMessage = false;
    @track isVisible = false; 
    fechaActivacion = '';
    @track showAprobarButton = false;
    @track showAltaButton = false;
    @track taskOwnerId;
    @track taskOwnerName;
    currentUserId;
    wiredTaskResult;

    @wire(getCurrentUserId)
    wiredUserId({ data, error }) {
        if (data) {
            this.currentUserId = data;
        } else if (error) {
            console.error('Error al obtener el usuario actual', error);
        }
    }

    @wire(getTaskById, { taskId: '$recordId' })
    wiredTask(result) {
        this.wiredTaskResult = result; 
        const { data, error } = result;
        if (data) {
            const subject = data.Subject;
            const status = data.Status; 
            console.log('Debug - Status:', status);
            console.log('Debug - Subject:', subject);
            this.taskOwnerId = data.OwnerId;
            this.taskOwnerName = data.Owner.Name;


            const isRevisarYActivar = subject === 'Revisión de Documentos y Activación de la Cuenta';

            if (['Aprobado', 'Rechazado', 'Devuelto'].includes(status)) {
                this.isVisible = false;
                this.showAprobarButton = false;
                this.showAltaButton = false;
            } else {
                this.isVisible = true;
                this.showAprobarButton = !isRevisarYActivar;
                this.showAltaButton = isRevisarYActivar;
            }
        } else if (error) {
            console.error('Error al obtener la tarea:', error);
        }
    }

    canUserManageTask() {
        // Si no es el dueño de la tarea
        if (this.taskOwnerId !== this.currentUserId) {
            const isQueue = this.taskOwnerId.startsWith('00G'); // Las colas empiezan con '00G'
            if (isQueue) {
                this.showToast('Advertencia', 
                    'Usted no es el propietario de la tarea por lo cual no puede gestionarla. En el caso de que el propietario sea Legales Onboarding debe autoasignársela.', 
                    'warning');
            } else {
                this.showToast('Advertencia', 'Usted no es el propietario de la tarea y no puede gestionarla.', 'warning');
            }
            return false;
        }
        return true;
    }
    


    handleAlta() {
        this.isAltaSelected = true;
    }

    handleFechaChange(event) {
        this.fechaActivacion = event.target.value; 
    }

    handleConfirmAlta() {
        if (this.fechaActivacion) {
            this.showConfirmationMessage = true;
        } else {
            this.showToast('Error', 'Por favor, complete el campo de fecha de activación', 'error');
        }
    }

    handleAprobar() {
        if (!this.canUserManageTask()) return;
        updateTaskStatus({ taskId: this.recordId, fechaActivacion: this.fechaActivacion, action: 'aprobar' })
            .then(() => {
                this.showToast('Éxito', 'Se completó con éxito', 'success');
                this.isVisible = false;
                setTimeout(() => {
                    window.location.reload(); 
                }, 500);
            })
            .catch(error => {
                this.showToast('Error', 'Error al procesar la acción', 'error');
                console.error('Error al procesar la acción:', error);
            });
        this.showConfirmationMessage = false;  
    }

    handleConfirmacionSi() {
        if (!this.canUserManageTask()) return;
        updateTaskStatus({ taskId: this.recordId, fechaActivacion: this.fechaActivacion, action: 'darAlta' })
            .then(() => {
                this.showToast('Éxito', 'Se completó con éxito', 'success');
                this.isVisible = false;
                setTimeout(() => {
                    window.location.reload(); 
                }, 500);
            })
            .catch(error => {
                this.showToast('Error', 'Error al procesar la acción', 'error');
                console.error('Error al procesar la acción:', error);
            });
        this.showConfirmationMessage = false;  
    }

    handleConfirmacionNo() {
        window.history.back();
        this.showConfirmationMessage = false; 
    }

    handleRechazar() {
        if (!this.canUserManageTask()) return;
        updateTaskStatus({ taskId: this.recordId, action: 'rechazar' })
            .then(() => {
                this.showToast('Éxito', 'Tarea marcada como completada y rechazada', 'success');
                this.isVisible = false;
                setTimeout(() => {
                    window.location.reload(); 
                }, 500);
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
                console.error('Error al procesar el rechazo:', error);
            });
    }
    
    handleDevolver() {
        if (!this.canUserManageTask()) return;
        updateTaskStatus({ taskId: this.recordId, action: 'devolver' })
            .then(() => {
                this.showToast('Éxito', 'Tarea marcada como devuelta', 'success');
                this.isVisible = false;
                setTimeout(() => {
                    window.location.reload(); 
                }, 500);
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
                console.error('Error al procesar la devolución:', error);
            });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }
}