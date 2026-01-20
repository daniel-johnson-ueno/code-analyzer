import { LightningElement, api, track } from 'lwc';

const columns = [
              { label: 'Fecha', fieldName: 'recordDate', hideDefaultActions: true},
              { label: 'Nivel', fieldName: 'level', type: 'decimal', hideDefaultActions: true},
              { label: 'Mínimo', fieldName: 'minimumPoints', type: 'decimal', hideDefaultActions: true},
              { label: 'Máximo', fieldName: 'maximumPoints', type: 'decimal', hideDefaultActions: true},

          ];

export default class HistoryLevel extends LightningElement {

    @api historyLevel;
    @track columns = columns;

    connectedCallback() {
        console.log('hola');
    }

}