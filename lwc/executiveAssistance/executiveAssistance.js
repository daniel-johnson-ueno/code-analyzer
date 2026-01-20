import { LightningElement, track } from 'lwc';
import executiveAssistanceList from '@salesforce/apex/ExecutiveAssistanceController.executiveAssistanceList';
import {onHandleSort, showSuccessMessage, showErrorMessage, getModifiedFormattedDate, exportCSVFile} from 'c/utils';


const columns = [
    { label: 'Ejecutivo', fieldName: 'name', type: 'string', sortable: true},
    { label: 'Equipo', fieldName: 'channel', type: 'string', sortable: true},
    { label: 'Lider', fieldName: 'manager', type: 'string', sortable: true },
    { label: 'Programado', fieldName: 'programmedTime', type: 'string' },
    { label: 'Hora programada', fieldName: 'totalProgrammedHours', type: 'string' },
    { label: 'Primer login', fieldName: 'executiveFirstLogin', type: 'string'},
    { label: 'Ultimo logout', fieldName: 'executiveLastLogin', type: 'string'},
    { label: 'Tarde', fieldName: 'connectedLateTime', type: 'string'},
    { label: 'Tiempo conectado', fieldName: 'connectedTime', type: 'string'},
]

const todayDate = new Date();
todayDate.toLocaleDateString('en-CA', { timeZone: 'America/Asuncion' });

export default class ExecutiveAssistance extends LightningElement {

    @track isLoading = false;
    areas = [];
    @track selectedDate = getModifiedFormattedDate(todayDate);
    @track columns = columns;
    @track executiveAssistanceList = [];
    @track filteredExecutiveAssistanceData = [];
    //@track value = 'all';
    @track selectedFilter = 'all';
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy;

    connectedCallback(){
        this.getExecutiveAssistanceData();
    }



    handleDateChange(event) {
        this.selectedDate = event.detail.value;
        console.log('selectedDate: ' + this.selectedDate);
        this.getExecutiveAssistanceData();
    }

    getExecutiveAssistanceData(){
        this.isLoading = true;
        executiveAssistanceList({selectedDate: this.selectedDate})
        .then(result => {
            console.log(result);
            if(result.length > 0){
                console.log(result);
                this.executiveAssistanceList = result;
                this.filterExecutiveAssistanceData();
            }
        })
        .catch(error => {
            console.log(error);
        })
        .finally(() => {
            this.isLoading = false;
        })
    }

    handleFilterChange(event){

       this.selectedFilter = event.target.value;

       this.filterExecutiveAssistanceData()
    }

    filterExecutiveAssistanceData(){

        let filteredExecutiveAssistanceData = [];
        this.filteredExecutiveAssistanceData = [];

        if(this.selectedFilter == 'all'){
             filteredExecutiveAssistanceData = this.executiveAssistanceList;
        } else {

            switch(this.selectedFilter){
                case 'connectedWithoutShift':
                    filteredExecutiveAssistanceData = this.executiveAssistanceList.filter(item => item.connectedWithoutShift == true);
                    break;
                case 'connectedLate':
                    filteredExecutiveAssistanceData = this.executiveAssistanceList.filter(item => item.connectedLate == true);
                    break;
                case 'absent':
                    filteredExecutiveAssistanceData = this.executiveAssistanceList.filter(item => item.absent == true);
                    break;
                case 'earlyLogout':
                    filteredExecutiveAssistanceData = this.executiveAssistanceList.filter(item => item.earlyLogout == true);
                    break;
            }
        }

        this.filteredExecutiveAssistanceData = filteredExecutiveAssistanceData;
    }

    handleRefresh(){
        this.executiveAssistanceList = [];
        this.getExecutiveAssistanceData();
    }

    handleExport(){
       console.log('export');
       let headers = {};
        try{
            this.columns.forEach(column => {
               headers[column.fieldName] = column.label;
            });

           console.log('headers: ' + JSON.stringify(headers));
           exportCSVFile(headers, this.filteredExecutiveAssistanceData, 'Asistencia Ejecutivos');
        } catch(e){
            console.log('error')
            console.log(e);
        }

    }


   onHandleSort(event) {
       const { sortedData, sortDirection, sortedBy } = onHandleSort(event, this.filteredExecutiveAssistanceData, this.sortDirection, this.sortedBy);
       this.filteredExecutiveAssistanceData = sortedData;
       this.sortDirection = sortDirection;
       this.sortedBy = sortedBy;
   }


    get options() {
        return [
            { label: 'Todo', value: 'all'},
            { label: 'Conectado y no programado', value: 'connectedWithoutShift' },
            { label: 'Llegó tarde hoy', value: 'connectedLate' },
            { label: 'Ausentes', value: 'absent' },
            { label: 'Se fue temprano', value: 'earlyLogout' },

        ];
    }




}