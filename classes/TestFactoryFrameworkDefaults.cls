/**
 * Created by danieljohnson on 25/02/2025.
 *
 * To specify defaults for objects, use the naming convention [ObjectName]Defaults.
 * For custom objects, omit the __c from the Object Name
 */

public with sharing class TestFactoryFrameworkDefaults {

    public class PersonAccountDefaults implements TestFactoryFramework.FieldDefaults {
        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount');
        String recordTypeId = recordTypeInfo.getRecordTypeId();

        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    Account.FirstName => 'Test',
                    Account.LastName => 'Person Account',
                    Account.PersonCode__c => 123456,
                    Account.RecordTypeId => recordTypeId
            };
        }
    }

    public class BusinessAccountDefaults implements TestFactoryFramework.FieldDefaults {
        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('IndustriesBusiness');
        String recordTypeId = recordTypeInfo.getRecordTypeId();

        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    Account.Name => 'Business Account',
                    Account.PersonCode__c => 123456,
                    Account.RecordTypeId => recordTypeId
            };
        }
    }

    public class InternalCompanyAccountDefaults implements TestFactoryFramework.FieldDefaults {
        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Internal_Company');
        String recordTypeId = recordTypeInfo.getRecordTypeId();

        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    Account.Name => 'Internal Account',
                    Account.Numero_Oficina__c => 277,
                    Account.RecordTypeId => recordTypeId
            };
        }
    }

    public class ConsultaCaseDefaults implements TestFactoryFramework.FieldDefaults {
        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Consulta');
        String recordTypeId = recordTypeInfo.getRecordTypeId();

        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    Case.Subject => 'Test Case',
                    Case.RecordTypeId => recordTypeId
            };
        }
    }

    public class ReclamoCaseDefaults implements TestFactoryFramework.FieldDefaults {
        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Reclamo');
        String recordTypeId = recordTypeInfo.getRecordTypeId();

        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    Case.Subject => 'Test Case',
                    Case.RecordTypeId => recordTypeId
            };
        }
    }

    public class ReclamoFraudeCaseDefaults implements TestFactoryFramework.FieldDefaults {
        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Reclamo_Fraude');
        String recordTypeId = recordTypeInfo.getRecordTypeId();

        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    Case.Subject => 'Test Case',
                    Case.RecordTypeId => recordTypeId
            };
        }
    }

    public class SolicitudCaseDefaults implements TestFactoryFramework.FieldDefaults {
        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Solicitud');
        String recordTypeId = recordTypeInfo.getRecordTypeId();

        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    Case.Subject => 'Test Case',
                    Case.RecordTypeId => recordTypeId
            };
        }
    }

    public class MigradoZendeskCaseDefaults implements TestFactoryFramework.FieldDefaults {
        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Migrado_Zendesk');
        String recordTypeId = recordTypeInfo.getRecordTypeId();

        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    Case.Subject => 'Test Case',
                    Case.RecordTypeId => recordTypeId
            };
        }
    }

    public class ContactDefaults implements TestFactoryFramework.FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    Contact.FirstName => 'First',
                    Contact.LastName => 'Last'
            };
        }
    }

    public class UenoServiceDomainDefaults implements TestFactoryFramework.FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Ueno_Service_Domain__c.ApiKey__c => '09-746e-4e1d',
                Ueno_Service_Domain__c.DomainName__c => 'https://kongcloud.ind-dev-sae1.ueno.com.py'
            };
        }
    }

}