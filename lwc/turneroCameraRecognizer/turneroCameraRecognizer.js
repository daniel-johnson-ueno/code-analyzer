/**
 * @name               : turneroCameraRecognizer
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 11-11-2024
 * @modification date  : 19-03-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : 
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   19-11-2024   Alvaro Gonzales Lapponi   Initial Version
**/
import { LightningElement, track } from 'lwc';

const IMAGE_QUALITY = 1; //Valores permitidos de 0 a 1

export default class TurneroCameraRecognizer extends LightningElement {

    videoElement;
    canvasElement;
    base64Image;
    showPicture = false;
    initialized = false; //flag para que solo se tome una foto

    get videoStyle() {
        return this.showPicture ? 'display: none;' : 'display: block;';
    }

    /**
     * @description Inicia cámara y obtiene videoElement
     */
    renderedCallback() {
        if (!this.initialized) {
            this.initialized = true;
            this.videoElement = this.template.querySelector('.videoElement');
            this.initCamera();
        }
    }

    /**
     * @description Crea elemento de video
     */
    async initCamera() {
        if (navigator.mediaDevices) {
            try {
                this.videoElement.srcObject = await navigator.mediaDevices.getUserMedia({video: true, audio: false}); 


                await this.delay(5000);
                await this.captureImage();
                this.getClientInfo();
            } catch (error) {
                console.error('Error accessing camera: ', error);
            } finally {
                this.stopCamera();
                this.showPicture = true;
            }
        } else {
            console.error('getUserMedia is not supported in this browser');
        }
    }

    /**
     * @description Lanza Custom Event al padre con la foto tomada
     */
    getClientInfo(){
        const selectedEvent = new CustomEvent('getclientinfo',{
            detail: { base64Image: this.base64Image }
        });
        this.dispatchEvent(selectedEvent);
    }

    /**
     * @description Crea la imagen a partir del video y la convierte a base64.
     */
    async captureImage() {
        if (this.videoElement && this.videoElement.srcObject !== null) {
            const videoAspectRatio = this.videoElement.videoWidth / this.videoElement.videoHeight;
            const canvasAspectRatio = 3 / 4; // Aspect ratio de la imagen de salida
            
            let sx = 0, sy = 0, sWidth = this.videoElement.videoWidth, sHeight = this.videoElement.videoHeight;

            // Recortar el video si no coincide deseado
            if (videoAspectRatio > canvasAspectRatio) {
                sWidth = sHeight * canvasAspectRatio;
                sx = (this.videoElement.videoWidth - sWidth) / 2;
            } else {
                sHeight = sWidth / canvasAspectRatio;
                sy = (this.videoElement.videoHeight - sHeight) / 2;
            }

            // Canvas con proporciones deseadas
            const canvas = document.createElement('canvas');
            canvas.width = 300;
            canvas.height = 400;

            const context = canvas.getContext('2d');
            context.drawImage(
                this.videoElement,
                sx, sy, sWidth, sHeight,
                0, 0, canvas.width, canvas.height
            );

            const quality = IMAGE_QUALITY;
            const imageDataCompressed = canvas.toDataURL('image/jpeg', quality);
            this.base64Image = imageDataCompressed;
            canvas.remove();
        }
    }


    stopCamera() {
        if (this.videoElement && this.videoElement.srcObject) {
            const tracks = this.videoElement.srcObject.getTracks();
            tracks.forEach(track => track.stop());
            this.videoElement.srcObject = null;
        }
    }

    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

}