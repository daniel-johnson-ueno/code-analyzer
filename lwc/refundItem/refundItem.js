import { LightningElement, api,track } from 'lwc';

export default class RefundItem extends LightningElement {

    @api voucher;

    get wasRejected(){
        return (this.voucher.verdict == "Reintegro pendiente a procesar" || this.voucher.rejectionType != null)?true:false;
    }

    get wasApproved(){
        console.log('this.voucher.verdict '+this.voucher.verdict)
        return this.voucher.promotion != null?true:false;
    }

    get itIsProcessedOrInProcessClass(){
        if(this.typeCashbackState=="CASHBACK_VISIBLE"){
            return "processed-container item-content";
        }
        else{
            return "in-process-container item-content"
        }
    }

}