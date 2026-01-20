import { LightningElement,api,track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkRefundStatus from '@salesforce/apex/RefundQueryController.checkRefundStatus';
import relateReceipts from '@salesforce/apex/RefundQueryController.relateReceipts';

export default class RefundQuery extends LightningElement {
    //id del caso
    @api recordId;
    //comprobante de reintegro respuesta
    @track voucher = null;
    //lista de comprobantes a relacionar con el caso
    @track listOfLinkedRefunds = [];
    //lista auxiliar de comprobantes a relacionar con el caso
    @track auxiliaryList = [];
    //variable metodo de pago
    @track paymentMethod='';
    //variable numero de comprobante
    @track receiptNumber='';
    //variable con speech para cliente
    @track messageToClient='';
    //variable para mostrar comprobante o consulta
    @track showResult=false;
    //variable para definir si esta realizado o en proceso
    @track itIsProcessed = false;
    //variable para definir si esta realizado o en proceso
    @track itIsInProgress = false;
    //variable para definir si esta rechazado
    @track itIsAnError = false;
    //variable para indicar si esta cargando
    @track isLoading = false;
    //variable para comprobante en progreso 
    @track itIsPending = false;
    //variable que muestra speech al cliente
    @track showClientMessage = false;
    //variable para indicar si debe mostrar boton de relacionar el caso
    @track showButtonAddToCase = false;
    //variable para mostrar leyenda de creacion de registro
    @track createRelRejRecord = false;
    //Variable para mensaje cuando el comprobante es rechazado
    @track messageRejection = '';
    //variable para indicar accion de reintegro rechazado
    @track showMessageRejection = false;
    //lista de motivos de rechazo que pueden escalar
    @track rejectionReasonsEscalate = ['TRANSACTION_STORE_NOT_FOUND','TRANSACTION_CUSTOMER_WITHOUT_LOYALTY','DISCARDED_BY_INPUT_RULES_OPERATION_STORE','DISCARDED_BY_INPUT_RULES_OPERATION_STORE_BRAND','DISCARDED_BY_OUTPUT_RULES_PERSON_LOYALTY'];

    //metodo para obtener los metodos de pago
    get paymentMethodsToSelect() {
        return [
            { label: 'Tarjeta de crédito', value: 'TC' },
            { label: 'Tarjeta de débito', value: 'TD' },
            { label: 'QR', value: 'QR' },
        ];
    }

    //metodo que verifica si hay comprobantes a relacionar
    get thereIsLinkedRefunds(){
        return this.listOfLinkedRefunds.length>0;
    }

    get itIsInProgressOrProcessed(){
        return this.itIsInProgress||this.itIsProcessed;
    }

    //metodo para relacionar comprobante a la lista para relacionar 
    linkRefundToCase(){
        if(this.voucher){
            if(!this.listOfLinkedRefunds.some(item=>item.Id==this.voucher.Id)){
                this.listOfLinkedRefunds.push(this.voucher);
            }
        }
    }
    //metodo en la vista del comprobante para agregarlo a la lista a relacionare
    linkRefundAndBack(){
        this.linkRefundToCase();
        this.onBackButtonClick();
    }
    //metodo para volver a consultar por otro comprobante
    onBackButtonClick(){
        this.showResult=false;
        this.paymentMethod='';
        this.receiptNumber='';
    }
   
    //metodo para consultar el estado del comprobante
    onQueryButtonClick(){
        if(this.paymentMethod != '' && this.receiptNumber != ''){
            this.isLoading = true;
            this.itIsAnError=false;
            this.itIsProcessed=false;
            this.itIsPending=false;
            this.itIsInProgress=false;
            checkRefundStatus({PaymentMethod : this.paymentMethod,OperationNumber: this.receiptNumber, idCase: this.recordId})
            .then( response => {
                this.voucher = response;
                if(this.voucher.Id == null){
                    if(this.voucher.errorType == 'Not Found'){
                        this.showToast('Error', 'Posiblemente o ingreso mal el numero de comprobante o hay algun tipo de error.','error');
                    }else{
                        this.showToast('Error', 'Ocurrio un error al consultar el reintegro: '+this.voucher.codeError+ ' '+ this.voucher.errorType,'error');
                    }
                }else{
                    this.showResult = true;
                    if(this.voucher.rejectionType != null){
                        this.itIsAnError = true;
                    }
                    else if(this.voucher.userLevel != null){
                        if(this.voucher.typeCashbackState=="CASHBACK_VISIBLE"){
                            this.itIsProcessed = true;
                        }
                        else{
                            this.itIsInProgress=true;
                        }
                    }else{
                        this.itIsPending = true;
                    }
                    this.showButtonAddToCase = !this.itIsAnError;
                    this.showMessageRejection = this.itIsAnError;
                    if(this.itIsAnError){
                        if(this.rejectionReasonsEscalate.includes(this.voucher.rejectionTypeCode)){
                            this.linkRefundToCase();
                            this.messageRejection = 'Se relaciona el comprobante al caso.';
                        }else{
                            this.messageRejection = 'No se puede relacionar el movimiento al caso.';
                        }
                    }
                    if(this.voucher.messageToClient != null){
                        this.showClientMessage = true;
                        this.messageToClient = this.voucher.messageToClient;
                    }    
                }
                this.isLoading = false;
           })
            .catch( error => {
                this.showToast('Error', 'Error al consultar el reintegro '+ error,'error');
                this.isLoading = false
            })
        }else{
            this.showToast('Error', 'Por favor completar los datos obligatorios','error');
        }    
    }

    //metodo para crear registros relacionados
    createRelatedRefundRecords(){
        this.isLoading = true;
        relateReceipts({receipts: this.listOfLinkedRefunds, caseId: this.recordId})
        .then( response => {
            this.showToast('Exito', 'Se relacionaron correctamente los comprobantes al caso.','success');
            setTimeout(() => {
                window.location.reload();},
            1000);
            this.listOfLinkedRefunds = [];
            this.showResult = false;
            this.isLoading = false;
        })
        .catch( error => {
            this.showToast('Error', 'Error al relacionar los comprobantes al caso.','error');
            this.isLoading = false;
        })
    }

    //metodo para setear el valor numero de comprobante
    onReceiptNumberInputChange(event){
        this.receiptNumber= event.target.value;
    }

     //metodo para setear el valor elegido del metodo de pago
     onPaymentMethodInputChange(event){
        this.paymentMethod = event.target.value;
    }

    //metodo para mostrar errores o mensajes de exito
    showToast(title,message,variant){
        const event = new ShowToastEvent({
           title: title,
           message: message,
           variant: variant
        });
        this.dispatchEvent(event);
    }

    //metodo para controlar creacion de registros para reintegros rechazados
    createRelatedRejRecords(){
        this.auxiliaryList = [this.voucher];
        this.isLoading = true;
        relateReceipts({receipts: this.auxiliaryList, caseId: this.recordId})
        .then( response => {
            this.showToast('Exito', 'Se relacionaron correctamente los comprobantes al caso.','success');
            this.isLoading = false;
        })
        .catch( error => {
            this.showToast('Error', 'Error al relacionar los comprobantes al caso.','error');
            this.isLoading = false;
        })
    }
}