import { LightningElement, api, wire } from 'lwc';
import { IsConsoleNavigation, getFocusedTabInfo, openSubtab, EnclosingTabId, getTabInfo} from 'lightning/platformWorkspaceApi';

export default class NewCaseButton extends LightningElement {
    @api recordId;

    @wire(EnclosingTabId) tabId;

    async openSubtab() {

    if (!this.tabId) {
      return;
    }

    const tabInfo = await getTabInfo(this.tabId);
    const primaryTabId = tabInfo.isSubtab ? tabInfo.parentTabId.toString() : tabInfo.tabId.toString();

        try {

            if (primaryTabId) {

                await openSubtab(primaryTabId,{
                    pageReference: {
                       type: 'standard__navItemPage',
                       attributes: {
                           apiName: 'Crear_Caso',
                           recordId : this.recordId
                       },
                    },
                    label : 'Crear Caso',
                    icon : 'standard:case'
                });
            } else {
                console.error('No se pudo obtener el ID de la pestaña actual.');
            }
        } catch (error) {
            console.error('Error al abrir la subpestaña:', error);
        }
    }
}