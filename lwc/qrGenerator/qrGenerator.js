/**
 * @name               : QrGenerator
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 14-11-2024
 * @modification date  : 26-11-2024
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Componente reusable para códigos QR
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   14-11-2024   Alvaro Gonzales Lapponi   Initial Version
**/
import { LightningElement, api } from 'lwc';
import qrcode from './qrcode';

export default class QrGenerator extends LightningElement {
    @api urlText;

    /**
     * @description Metodo llamado al renderizar el componente.
     */
    renderedCallback() {
        const qrCodeGenerated = new qrcode(0, 'H');
        qrCodeGenerated.addData(this.urlText);
        qrCodeGenerated.make();

        // Selecciona el contenedor donde se generará el QR
        let qrContainer = this.template.querySelector(".qrCode");
        qrContainer.innerHTML = qrCodeGenerated.createSvgTag({});
    }
}