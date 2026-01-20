/**
 * @name               : auviousWidget
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 02-01-2025
 * @modification date  : 26-03-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Componente reusable para invocar videollamadas Auvious - Genesys
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   21-01-2025   Alvaro Gonzales Lapponi   Initial Version
**/
import { LightningElement, api } from 'lwc';
import fetchSettings from '@salesforce/apex/AuviousSettingsUtils.fetchSettings';

const AUVOUS_ESM_SCRIPT_URL = 'https://auvious.video/widget/dist/auvious/auvious.esm.js';
const AUVOUS_SCRIPT_URL = 'https://auvious.video/widget/dist/auvious/auvious.js'; 

export default class AuviousWidget extends LightningElement {
    @api caseId;
    @api cliente;
    @api nombreSucursal;

    // Variables para el estado de los scripts
    auviousEsmJsLoaded = false;
    auviousJsLoaded = false;

    /**
     * @description Método para solicitar inicio de videollamada
     */
    @api
    async requestVideocall(){
        if (this.auviousEsmJsLoaded && this.auviousJsLoaded) { 
            await this.launchWidget(); 
        } else {
            console.error('Los scripts de Auvious no se han cargado correctamente');
        }
    }

    /**
     * @description Lanza el widget de videollamadas
     */
    async launchWidget() {

        const auviousSettings = await this.getAuviousSettings();
        if(auviousSettings){
            let widgetOptions = {
                'application-id': auviousSettings.ApplicationID__c,
                'chat-mode': auviousSettings.ChatMode__c,
                'organization': auviousSettings.Organization__c,
                'greeting-action': auviousSettings.GreetingAction__c,
                'locale': auviousSettings.Locale__c,
                'kiosk-mode': auviousSettings.KioskMode__c,
                'pc-environment': auviousSettings.PCEnvironment__c,
                'pc-organization-id': auviousSettings.PCOrganizationID__c,
                'pc-deployment-id': auviousSettings.PCDeploymentID__c,
                'incoming-chat-messages-blocked': auviousSettings.IncomingChatMessagesBlocked__c
            };

            const widget = document.createElement('app-auvious-widget');

            Object.keys(widgetOptions).forEach(key => {
                widget.setAttribute(key, widgetOptions[key]);
            });

            const customerName = this.cliente.fullName ? this.cliente.fullName : 'ueno bank';
            console.log(customerName);
            widget.setAttribute('customer-display-name', customerName);
            
            const queue = this.cliente.esPersona ? auviousSettings.PersonQueue__c : auviousSettings.CompanyQueue__c;
            widget.setCustomerMetadata({
                cedula: this.cliente.numeroDocumento,
                queue: queue,
                nombreSucursal: this.nombreSucursal,
                salesforceAccountId: this.cliente.accountId,
                salesforceCaseId: this.caseId
            });

            document.body.appendChild(widget);

            /** Listener cuando se terminar la conversación */
            widget.addEventListener('conversationEnded', () => {
                this.handleSessionEnded('conversationEnded');
            });

            /** Listener cuando se termina la llamada */
            widget.addEventListener('callEnded', () => {
                this.handleSessionEnded('callEnded');
            });

            /** Listener cuando se desconecta el agente */
            widget.addEventListener('agentDisconnected', () => {
                this.handleSessionEnded('agentDisconnected');
            });

            (async () => {
                await customElements.whenDefined('app-auvious-widget');
                widget.launch('video');
            })();
        }
        

    }

    /**
     * @description Método que carga los módulos al renderizar el componente
     */
    connectedCallback() {
        // Cargar los scripts de Auvious si no se han cargado ya
        if (!this.auviousEsmJsLoaded || !this.auviousJsLoaded) {
            // Cargar el script modular (type="module")
            this.loadModuleScript(AUVOUS_ESM_SCRIPT_URL);

            // Cargar el script no-modular (nomodule)
            this.loadNoModuleScript(AUVOUS_SCRIPT_URL);
        }
    }

    async getAuviousSettings(){
        let auviousSettings;
        try {
            const result = await fetchSettings({ developerName: 'StandardSetting' });
            if (result) {
                auviousSettings = result;
            }
        } catch (error) {
            console.error(error);
        } 
        return auviousSettings;
    }

    handleSessionEnded(reason){
        const selectedEvent = new CustomEvent('sessionended',{
            detail: { reason: reason }
        });
        this.dispatchEvent(selectedEvent);
    }

    /**
     * @description Función para cargar el script como módulo
     * @param String
     */
    loadModuleScript(url) {
        const script = document.createElement('script');
        script.type = 'module';
        script.src = url;
        script.onload = () => {
            this.auviousEsmJsLoaded = true;
        };
        script.onerror = (error) => {
            console.error('Error al cargar el script ESM de Auvious', error);
        };
        document.body.appendChild(script);
    }

    /**
     * @description Función para cargar el script como no-módulo
     * @param String
     */
    loadNoModuleScript(url) {
        const script = document.createElement('script');
        script.nomodule = true;
        script.src = url;
        script.onload = () => {
            this.auviousJsLoaded = true;
        };
        script.onerror = (error) => {
            console.error('Error al cargar el script no-modular de Auvious', error);
        };
        document.body.appendChild(script);
    }

}