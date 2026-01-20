import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import SLA_DAY_1 from "@salesforce/schema/Lead.SLA_Day_1__c";
import SLA_DAY_1_END from "@salesforce/schema/Lead.Start_InProgress_Stage_SLA__c";

import SLA_DAY_3 from "@salesforce/schema/Lead.SLA_Day_3__c";
import SLA_DAY_3_END from "@salesforce/schema/Lead.Close_Or_Converted_Date_Time__c";

const FIELDS = [SLA_DAY_1, SLA_DAY_1_END, SLA_DAY_3, SLA_DAY_3_END];

export default class SlaLeadManager extends LightningElement {

    @api recordId;
    
    @wire(getRecord, { recordId: "$recordId", fields: FIELDS })
    lead;

    get slaDay1TimeEnd() {
        const slaDay1End = getFieldValue(this.lead.data, SLA_DAY_1_END);
        if ( typeof(slaDay1End) == "undefined" || slaDay1End == null ) {
            return false;
        }else {
            return true;
        }
    }
    get slaDay1OnTime(){
        const slaDay1Hours = getFieldValue(this.lead.data, SLA_DAY_1);
        if (slaDay1Hours>10) {
            return false;
        }else{
            return true;
        }
    }
    get slaDay1Percent() {
        const slaDay1Hours = getFieldValue(this.lead.data, SLA_DAY_1);
        let slaDay1Percent = (slaDay1Hours*100)/10;
        if (slaDay1Percent>100) {
            slaDay1Percent = 100;
        }
        return slaDay1Percent;
    }
    get slaDay1Flag() {
        const slaDay1Hours = getFieldValue(this.lead.data, SLA_DAY_1);
        if (slaDay1Hours>10) {
            return "/img/samples/flag_red.gif";
        } else {
            return "/img/samples/flag_green.gif";
        }
    }
    get slaDay1Time() {
        const slaDay1Hours = getFieldValue(this.lead.data, SLA_DAY_1);
        if ( typeof(slaDay1Hours) == "undefined" || slaDay1Hours == null ) {
            return 10;
        }
        if (slaDay1Hours>10) {
            return slaDay1Hours-10;
        } else {
            return 10-slaDay1Hours;
        }
    }
    get slaDay3TimeEnd() {
        const slaDay3End = getFieldValue(this.lead.data, SLA_DAY_3_END);
        if ( typeof(slaDay3End) == "undefined" || slaDay3End == null ) {
            return false;
        }else {
            return true;
        }
    }
    get slaDay3OnTime(){
        const slaDay3Hours = getFieldValue(this.lead.data, SLA_DAY_3);
        if (slaDay3Hours>30) {
            return false;
        }else{
            return true;
        }
    }
    get slaDay3Percent() {
        const slaDay3Hours = getFieldValue(this.lead.data, SLA_DAY_3);
        let slaDay3Percent = (slaDay3Hours*100)/30;
        if (slaDay3Percent>100) {
            slaDay3Percent = 100;
        }
        return slaDay3Percent;
    }
    get slaDay3Flag() {
        const slaDay3Hours = getFieldValue(this.lead.data, SLA_DAY_3);
        if (slaDay3Hours>30) {
            return "/img/samples/flag_red.gif";
        } else {
            return "/img/samples/flag_green.gif";
        }
    }
    get slaDay3Time() {
        const slaDay3Hours = getFieldValue(this.lead.data, SLA_DAY_3);
        if ( typeof(slaDay3Hours) == "undefined" || slaDay3Hours == null ) {
            return 30;
        }
        if (slaDay3Hours>30) {
            return slaDay3Hours-30;
        } else {
            return 30-slaDay3Hours;
        }
    }
}