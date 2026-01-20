import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningAlert from "lightning/alert";

//showSuccessMessage('title', 'Success Message', this);
export function showSuccessMessage(msgTitle, msgBody, self){
    var msgMode = 'dismissable';

    const evt = new ShowToastEvent({
        title: msgTitle,
        message: msgBody,
        variant: 'Success',
        mode: msgMode
    });
    self.dispatchEvent(evt);
}

/**
 * Displays a toast notification.
 *
 * @param {string} msgTitle - The title of the toast message.
 * @param {string} msgBody - The body of the toast message.
 * @param {string} variant - The variant of the toast message (e.g., 'success', 'error', 'warning', 'info').
 * @param {string} mode - The display mode of the toast message (e.g., 'dismissable', 'pester', 'sticky').
 * @param {object} self - The context (usually 'this') to dispatch the event.
 */
export function showToastMessage(msgTitle, msgBody, variant, mode, self) {
    const evt = new ShowToastEvent({
        title: msgTitle,
        message: msgBody,
        variant: variant,
        mode: mode
    });
    self.dispatchEvent(evt);
}

//showErrorMessage('Title', 'Error Message');
export function showErrorMessage(title, msgBody){
    LightningAlert.open({
        message: msgBody,
        theme: "error",
        label: title
    });
}

//ordenar datos datatable
export function onHandleSort(event, data, currentSortDirection, currentSortedBy) {
    const { fieldName: sortedBy, sortDirection } = event.detail;

    const newSortDirection = (sortedBy === currentSortedBy)
        ? (currentSortDirection === 'asc' ? 'desc' : 'asc')
        : 'asc';

    const cloneData = [...data];
    cloneData.sort(sortBy(sortedBy, newSortDirection === 'asc' ? 1 : -1));

    return {
        sortedData: cloneData,
        sortDirection: newSortDirection,
        sortedBy: sortedBy
    };
}


//Recibe una fecha y devuelve una nueva fecha con los dias, meses y años sumados/restados a la fecha original
export function getModifiedFormattedDate(date, days = 0, months = 0, years = 0) {
    let tempDate = new Date(date);
    tempDate.setDate(tempDate.getDate() + days);
    tempDate.setMonth(tempDate.getMonth() + months);
    tempDate.setFullYear(tempDate.getFullYear() + years);
    return tempDate.toISOString().split('T')[0];
}

function sortBy(field, reverse, primer) {
    const key = primer
        ? function (x) {
            return primer(x[field]);
        }
        : function (x) {
            return x[field];
        };

    return function (a, b) {
        a = key(a);
        b = key(b);
        return reverse * ((a > b) - (b > a));
    };
}

export function exportCSVFile(headers, dataToExport, fileName){

    if(!dataToExport || !dataToExport.length) return null;

    const jsonObject = JSON.stringify(dataToExport);
    const result = convertToCSV(jsonObject, headers);
    console.log(result);
    if(result === null) return;

    const blob = new Blob([result], {type: 'text/plain'});
    const exportedFilename = fileName ? fileName + '.csv' : 'export.csv';

    if(navigator.msSaveBlob){
        navigator.msSaveBlob(blob, exportedFilename);

    } else if (navigator.userAgent.match(/iPhone|iPad|iPod/i)){
        const link = window.document.createElement('a');
        link.href = 'data:text/csv;charset=utf-8,' + encodeURI(result);
        link.target = "_blank";
        link.download = exportedFilename;
        link.click();

    } else {
        const link = document.createElement("a");

        if(link.download !== undefined){
            const url = URL.createObjectURL(blob);
            link.setAttribute("href", url);
            link.setAttribute("download", exportedFilename);
            link.style.visibility='hidden';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }
    }
}

function convertToCSV(objArray, headers){
    const columnDelimiter = ',';
    const lineDelimiter = '\r\n';
    const actualHeaderKey = Object.keys(headers);
    const headerToShow = Object.values(headers);
    const data = typeof objArray !=='object' ? JSON.parse(objArray):objArray;

    let str = '';
    str += headerToShow.join(columnDelimiter); // Add header row
    str += lineDelimiter;

    data.forEach(obj => {
        let line = '';
        actualHeaderKey.forEach(key => {
            // Ignorar propiedades booleanas
            if (typeof obj[key] === 'boolean') return; // Skip boolean properties

            if(line != '') {
                line += columnDelimiter;
            }
            let strItem = obj[key] ? obj[key] : '';  // Maneja valores nulos o undefined
            line += strItem ? strItem.replace(/,/g, '') : strItem;
        });
        str += line + lineDelimiter;
    });

    return str;
}

// DATE UTILS
export function substractToDate(date, daysToSubtract = 0, monthsToSubtract = 0, yearsToSubtract = 0) {
    date.setDate(date.getDate() - daysToSubtract);
    date.setMonth(date.getMonth() - monthsToSubtract);
    date.setFullYear(date.getFullYear() - yearsToSubtract);
    return date;
}

export function formatDateISO(date) {
    const yyyy = date.getFullYear();
    const mm = String(date.getMonth() + 1).padStart(2, '0');
    const dd = String(date.getDate()).padStart(2, '0');
    return `${yyyy}-${mm}-${dd}`;
}

export function formatDateReadble(date) {
    return date.toLocaleDateString('es-CA', {
        day: '2-digit',
        month: 'short',
        year: 'numeric'
    }).replace(',', '');
}