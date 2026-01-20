import { LightningElement, api, track } from 'lwc';

export default class HistoryPoints extends LightningElement {
//TODO hacer que de este lado se filtren los registros por fecha, por nivel, por minimo y por maximo. Tambien usar los inputs para seleccionar rangos.
//TODO verificar que al abrir distintos registros cada uno mantenga sus datos, para esto necesito crear otro mock.

    @api data = [];
    @api columns = [];
}