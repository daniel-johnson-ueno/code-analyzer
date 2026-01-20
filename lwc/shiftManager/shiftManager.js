import { LightningElement, track } from 'lwc';
// import importCsvData from '@salesforce/apex/ShiftManagerController.importCsvData';
// import insertNewShifts from '@salesforce/apex/ShiftManagerController.insertNewShifts';
import importCsvData from '@salesforce/apex/ShiftProcessor.importCsvData';
import insertNewShifts from '@salesforce/apex/ShiftProcessor.insertNewShifts';

import {showSuccessMessage, showErrorMessage} from 'c/utils';


const columns = [
        { label: 'Nombre', fieldName: 'employeeName', hideDefaultActions: true },
        { label: 'Fecha Entrada', fieldName: 'programedDateIn', hideDefaultActions: true },
        { label: 'Fecha Salida', fieldName: 'programedDateOut', hideDefaultActions: true },
        { label: 'Franja Horaria', fieldName: 'programedWorkingHours', hideDefaultActions: true },
        { label: 'Break 1', fieldName: 'firstBreakProgramedTime', hideDefaultActions: true },
        { label: 'Break 2', fieldName: 'secondBreakProgramedTime', hideDefaultActions: true },
        { label: 'Training', fieldName: 'trainingProgramedTime', hideDefaultActions: true },
        { label: 'Comentarios', fieldName: 'otherProgramedTime', hideDefaultActions: true },
]

//todo Segun el valor que seleccionen en tipo de estado deberian filtrarse
//la formula de horas trabajadas solo deberia tomar bloques distintos a day off?


export default class ShiftManager extends LightningElement {

    @track isLoading = false;
    @track csvLoaded= false;
    @track shiftWrapperList = [];
    @track columns = columns;


    handleFileUpload(event) {
        this.isLoading = true;
        const file = event.target.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onload = () => {
                const csvLines = reader.result.split('\n');
                importCsvData({ csvLines })
                    .then(result => {
                        console.log('Importación completada');
                        if(result != null && result.length > 0){
                            this.shiftWrapperList = result;
                            this.csvLoaded = true;
                        }
                    })
                    .catch(error => {
                        console.error('Error durante la importación: ', error);
                        showErrorMessage('Error', error?.body?.message);
                    })
                    .finally(() => {
                        this.isLoading = false;
                    })
            };
            reader.readAsText(file);


        }
    }

    handleCreateShifts(){
        this.isLoading = true;
        this.isInserting = true;
        insertNewShifts({shiftList: this.shiftWrapperList})
        .then(result => {
            console.log(' creados');
            showSuccessMessage('Success', 'Turnos creados correctamente', this);
            this.csvLoaded = false;
        })
        .catch(error => {
            console.error('Error durante la creación: ', error);
            showErrorMessage('Error', error?.body?.message);
        })
        .finally(() => {
            this.isLoading = false;
        })

    }

}