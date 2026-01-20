import { LightningElement, track }  from 'lwc';
import { ShowToastEvent }           from 'lightning/platformShowToastEvent';

import getMonthDates                from '@salesforce/apex/EmployeeShiftChangeController.getMonthDates';
import userContactInfo              from '@salesforce/apex/EmployeeShiftChangeController.userContactInfo';
import getShiftsToChange            from '@salesforce/apex/EmployeeShiftChangeController.getShiftsToChange';
import sendDayOffForApproval        from '@salesforce/apex/EmployeeShiftChangeController.sendDayOffForApproval';
import getCurrentContactShifts      from '@salesforce/apex/EmployeeShiftChangeController.getCurrentContactShifts';
import sendReplacementForApproval   from '@salesforce/apex/EmployeeShiftChangeController.sendReplacementForApproval';
import getDayOffTypes               from '@salesforce/apex/EmployeeShiftChangeController.getDayOffTypes';

import USER_ID from '@salesforce/user/Id';

const columns = [
    {label: 'Empleado', fieldName: 'employeeName', hideDefaultActions: true},
    {label: 'Entrada', fieldName: 'startHour', type: "date",
       typeAttributes:{
           year: "numeric",
           month: "short",
           day: "2-digit",
           hour: "2-digit",
           minute: "2-digit"
       }, hideDefaultActions: true},
    {label: 'Salida', fieldName: 'endHour', type: "date",
        typeAttributes:{
            year: "numeric",
            month: "short",
            day: "2-digit",
            hour: "2-digit",
            minute: "2-digit"
        }, hideDefaultActions: true},
    { label: 'Break 1', fieldName: 'firstBreakProgramedTime', hideDefaultActions: true },
    { label: 'Break 2', fieldName: 'secondBreakProgramedTime', hideDefaultActions: true },
    { label: 'Training', fieldName: 'trainingProgramedTime', hideDefaultActions: true },
    { label: '¿Es día libre?', fieldName: 'isDayOff', hideDefaultActions: true }
]

export default class EmployeeShiftChange extends LightningElement {

    currentUser = USER_ID;
    @track employeeShifts = [];
    @track isLoading = false;
    @track shiftLoaded = false;
    @track shiftSelected = false;
    @track showChangeShiftModal = false;
    @track showChangeDayOffModal = false;
    @track selectedShift = null;
    @track contact = null;
    @track contactToAssign = null;
    // todo: la hora viene en UTC +3 horas de la local
    @track startDate;
    @track endDate;
    @track filter = {};
    @track currentEmployeeShifts = [];
    @track selectedEmployeeShifts = [];
    @track dayOffTypes;
    @track selectedDayOffType = '';
    // @track showPageOne = true;
    // @track showPageTwo = false;
    @track myTurnsHomeEmpty = false;
    @track myTurnsModalEmpty = false;

    @track columns = columns;

    connectedCallback(){
        this.isLoading = true;
        this.loadInitialData();
    }

    loadInitialData(){
        Promise.all([
            getMonthDates(),
            userContactInfo({ userId: this.currentUser }),
            getCurrentContactShifts({ userId: this.currentUser })
        ])
        .then(([monthDates, contactResult, shiftList]) => {
            if(monthDates){
                this.startDate = monthDates.start;
                this.endDate = monthDates.end;
            }
            if (contactResult) {
                this.contact = contactResult[0];
                this.createContactFilter();
            }
            if (shiftList.length > 0) {
                console.log(this.myTurnsHomeEmpty);
                this.employeeShifts = shiftList;
                this.shiftLoaded = true;
            }else{
                this.myTurnsHomeEmpty=true;
                console.log('else');
                console.log(this.myTurnsHomeEmpty);
            }
        })
        .catch(error => {
            console.log('catch');
            this.myTurnsHomeEmpty=true;
            console.error('Error loading initial data:', error);
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    toggleChangeShiftModal(){
        this.showChangeShiftModal = !this.showChangeShiftModal;
        if(this.showChangeShiftModal){
            this.getShiftsToChangeModal(this.contact.Id);
        }
    }
    
    toggleChangeDayOffModal(){
        this.showChangeDayOffModal = !this.showChangeDayOffModal;
        //agregar llamado apra pedir los valores del picklist
        if(this.showChangeDayOffModal == true){
            getDayOffTypes()
            .then(result => {
                console.log('result');
                console.log(JSON.stringify(result));
                if(result.length > 0){
                    console.log('dayOffTypes');
                    this.dayOffTypes = result;
                }
            })
            .catch(error => {
                console.error(error);
            })
        }

    }
    
    toggleShiftSelected(){
        this.shiftSelected = !this.shiftSelected;
    }

    onChangeShiftClick(){
        this.toggleChangeShiftModal();
    }

    onChangeDayOffClick(){
        this.toggleChangeDayOffModal();
    }

    handleDateChange(event){
        if(event.target.name == 'inputStartDate'){
            this.startDate = event.detail.value;
        }else if(event.target.name == 'inputEndDate'){
            this.endDate = event.detail.value;
        }
        if(this.startDate && this.endDate){
            this.getShiftsToChangeModal(this.contact.Id);
        }
    }

    getShiftsToChangeModal(contactId){
        getShiftsToChange({
            contactId: contactId, 
            startDate: this.startDate, 
            endDate: this.endDate
        })
        .then((result) => {
            if(result.length > 0){
                if(contactId == this.contact.Id){
                    this.currentEmployeeShifts = result;
                } else {
                    this.selectedEmployeeShifts = result;
                }
                console.log('EmployeeShifts.length');
                console.log(this.myTurnsModalEmpty);
                this.myTurnsModalEmpty = false;
            }else{
                this.myTurnsModalEmpty = true;
                console.log('else');
                console.log(this.myTurnsModalEmpty);
            }
        })
        .catch((error) => {
            console.error(error);
        })
    }

    handleRowSelection(event){
        this.selectedEmployeeShifts = null;
        event.preventDefault();
        this.selectedEmployeeShifts = event.detail.selectedRows;
        this.toggleShiftSelected();
    }

    handleButtonClick(event){
        switch (event.target.name) {
            case 'cancelDayOff':
                this.toggleChangeDayOffModal();
                break;
            case 'cancel':
                this.toggleChangeShiftModal();
                break;
            case 'submitToApproval':
                if(this.contactToAssign != null){
                    this.handleChangeShift();
                } else {
                    const evt = new ShowToastEvent({
                        title: 'Error',
                        message: 'Debe selecionar un Ejecutivo.',
                        variant: 'Error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(evt);
                }
                break;
            case 'submitToApprovalDayOff':
                this.handleApprovalDayOff();
                break;
            default:
        }
    }

    handleContactToAssign(event){
        this.contactToAssign = null;
        this.contactToAssign = event.detail.recordId;
    }

    handleDayOffTypeChange(event){
        this.selectedDayOffType = event.detail.value;
    }

    handleChangeShift(){
        sendReplacementForApproval({
            selectedShifts: this.selectedEmployeeShifts, 
            contactToAssign: this.contactToAssign, 
            userRequester: this.currentUser
        })
        .then((result) =>{
            const evt = new ShowToastEvent({
                title: 'Exitoso',
                message: 'Solicitud de aprobación para cambio de turno enviada.',
                variant: 'success',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);
        })
        .catch((error) => {
            console.error(error);
            const evt = new ShowToastEvent({
                title: 'Error',
                message: 'Ocurrio un error contacte a un Administrador.',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);
        })
        .finally(() => {
            this.toggleChangeShiftModal();
        });
    }

    handleApprovalDayOff(){
        sendDayOffForApproval({
            userRequester: this.currentUser,
            contactId: this.contact.Id, 
            startDate: this.startDate, 
            endDate: this.endDate,
            dayOffType: this.selectedDayOffType
        })
        .then((result) =>{
            const evt = new ShowToastEvent({
                title: 'Exitoso',
                message: 'Solicitud de aprobación para Dia libre enviada.',
                variant: 'success',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);
        })
        .catch((error) => {
            console.error(error);
            const evt = new ShowToastEvent({
                title: 'Error',
                message: 'Ocurrio un error contacte a un Administrador.',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);
        })
        .finally(() => {
            this.toggleChangeDayOffModal();
        });
    }

    createContactFilter(){
        if(this.contact.AccountId == null){
            this.contact.AccountId = '';
        }
        if(this.contact.Channel__c == null){
            this.contact.Channel__c = '';
        }
        this.filter = {
            criteria: [
                {
                    fieldPath: 'AccountId',
                    operator: 'eq',
                    value: this.contact.AccountId.toString(),
                }/* ,
                {
                    fieldPath: 'Channel__c',
                    operator: 'eq',
                    value: this.contact.Channel__c.toString(),
                } */
            ],
            filterLogic: '1',
        };
    }

}