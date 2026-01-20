/**
 * @name               : turneroLobbyCitas
 * @author             : Carlos Bastidas
 * @creation date      : 10-03-2025
 * @modification date  : 24-03-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : 
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   10-03-2025   Carlos Bastidas           Initial Version
**/
import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import SVG_LOGO from '@salesforce/resourceUrl/turneroLogo';

import getLobbyCitasData from '@salesforce/apex/TurneroLobbyCitasController.getLobbyCitasData';
import assignAppointment from '@salesforce/apex/TurneroLobbyCitasController.assignAppointment';
import getAllbranchesForSupervisorAndRefreshTime from '@salesforce/apex/TurneroLobbyCitasController.getAllbranchesForSupervisorAndRefreshTime';

import hasPermission from '@salesforce/customPermission/EjecutarTurneroLobby';


export default class TurneroLobbyCitas extends  NavigationMixin(LightningElement) {
    @track lobbyData;
    isLoading = false;
    @track columns;
    @track options;
    refreshTime = 300000;
    @track idfirstElement = null;
    branchName = '';
    icon = `${SVG_LOGO}#calend`;
    @track selectedBrunch = null;
    @track hiddenBrunches = false;
    elementNumber = '0';
    renderLobby = hasPermission != null ? hasPermission: false;


    connectedCallback(){
        if(!this.renderLobby) {
            return null;
        }
        this.isLoading = true;
        getAllbranchesForSupervisorAndRefreshTime()
        .then(result => {
            if(result && result.existData){
                this.hiddenBrunches = true;
                this.options = JSON.parse(result.dataTable);
                this.selectedBrunch = result.selectedBrunch;
                this.branchName = this.selectedBrunch;
                
            }
            this.refreshTime = parseInt(result.refreshTime);
        })
        .catch(error => {
            console.log(error);
        })
        .finally(() => {
            this.isLoading = false;
            this.handleUpdate();
            setInterval(() => {
                this.handleUpdate();
            }, this.refreshTime);
        })  
    }

    get showAppointmentDatatable(){
        return this.lobbyData && this.lobbyData.length > 0;
    }

    handleUpdate(){
        this.clearDataAfterSearch();
        this.isLoading = true;
        getLobbyCitasData({branchName: this.selectedBrunch})
        .then(result => {
            if(result && result.existData){                
                this.lobbyData = result.appointmentList;
                this.formatData();
                this.idfirstElement =result.idfirstElement;  
            }
            this.elementNumber = result.elementNumber;
            this.branchName = result.branchName;
            this.columns = JSON.parse(result.dataTable);
            this.formatColumns();
        })
        .catch(error => {
            console.log(error);
        })
        .finally(() => {
            this.isLoading = false;
        })  
    }

    formatColumns(){
        this.columns = this.columns.map(col => {
            if (col.type === "boolean") {
                return {
                    ...col,
                    fieldName:'',
                    initialWidth: 110,
                    cellAttributes: {
                        iconName: {  fieldName: col.fieldName },
                        iconPosition:"right"
                    }
                };
            } else if(col.type === "button"){
                return {
                    ...col,
                    typeAttributes: {
                        label: { fieldName: col.fieldName },
                        name: 'navigate',
                        variant: 'base'
                    },
                    initialWidth: 140
                }
            }
            return col;
        });
    }

    formatData(){
        this.lobbyData = this.flattenLookups(this.lobbyData);
        this.lobbyData.forEach(element => {
            element.RequirePriorityAttention__c = element.RequirePriorityAttention__c === true ? 'utility:check' : 'utility:close';
            element.WaitingTime__c = this.formatDuration(element.WaitingTime__c);
        });
    }

    /**
     * @description Aplana los campos lookup para que sean legibles para el datatable
     * @param {*} records 
     * @returns 
     */
    flattenLookups(records) {
        return records.map(record => {
            let flattened = {};
            for (let key in record) {
                if (record.hasOwnProperty(key)) {
                    if (typeof record[key] === "object" && record[key] !== null) {
                        // Si es un lookup
                        for (let subKey in record[key]) {
                            if (record[key].hasOwnProperty(subKey)) {
                                flattened[`${key}.${subKey}`] = record[key][subKey];
                            }
                        }
                    } else {
                        // Si es un campo normal
                        flattened[key] = record[key];
                    }
                }
            }
            return flattened;
        });
    }

    /**
     * @description Transforma segunods a Xh : Ym: Zs
     * @param {Integer} seconds
     */
    formatDuration(seconds) {
        if (seconds < 0) return "0s"; 
    
        const h = Math.floor(seconds / 3600);
        const m = Math.floor((seconds % 3600) / 60);
        const s = seconds % 60;
    
        return `${h > 0 ? h + "h " : ""}${m > 0 ? m + "m " : ""}${s > 0 ? s + "s" : ""}`.trim();
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'navigate') {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: row.Id, 
                    actionName: 'view'
                }
            });
        }
    }

    handleTakeAppointment(){
        if(this.idfirstElement != null){
            this.isLoading = true;
            assignAppointment({idfirstElement: this.idfirstElement})
            .then(result => {
                if(result && result.existData){
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: this.idfirstElement,
                            actionName: 'view'
                        }
                    });
                    this.handleUpdate();
                } else {
                    var msg = 'No se ha podido asignar la cita'
                    if(result.messageDetail){
                        msg = result.messageDetail;
                        const evt = new ShowToastEvent({
                            title: 'Error de Asignación',
                            message: msg,
                            mode: 'sticky',
                            variant: 'error',
                        });
                        this.dispatchEvent(evt);
                        this.handleUpdate();
                    }
                    
                }
            })
            .catch(error => {
                console.log(error);
            })
            .finally(() => {
                this.isLoading = false;
        })  
        }
        
    }

    handleChangeBranch(event) {
        this.selectedBrunch = event.detail.value;
        this.branchName = this.selectedBrunch;
        this.handleUpdate();
    }

    clearDataAfterSearch(){
        this.lobbyData = [];
        this.idfirstElement = null;
    }
}