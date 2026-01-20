/**
 * @name               : AuviousSettingsUtilsTest
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 12-03-2025
 * @modification date  : 12-03-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Clase test de AuviousSettingsUtils
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   12-03-2025   Alvaro Gonzales Lapponi   Initial Version
**/
@isTest
public with sharing class AuviousSettingsUtilsTest {

    static final String AUVIOUS_SETTING_DEVELOPERNAME = 'AuviousRecordTest';
    static final String ASSERT_MESSAGE              = 'Valor de campo de configuración incorrecto';
    static final String EXPECT_AUVIOUS_PERSONQUEUE  = 'colaPersonaTest';
    static final String EXPECT_AUVIOUS_COPMANYQUEUE = 'colaEmpresaTest';

    /**
    * @description Obtener registro test de metadata de Auvious Settings
    * @author Alvaro Gonzales Lapponi | 12-03-2025 
    **/
    @isTest
    public static void fetchSettingsTestOk() {
        Test.startTest();
        AuviousSettings__mdt auviousMetadata = AuviousSettingsUtils.fetchSettings(AUVIOUS_SETTING_DEVELOPERNAME);
        Test.stopTest();
        system.AssertEquals( EXPECT_AUVIOUS_PERSONQUEUE, auviousMetadata.PersonQueue__c, ASSERT_MESSAGE );
        system.AssertEquals( EXPECT_AUVIOUS_COPMANYQUEUE, auviousMetadata.CompanyQueue__c, ASSERT_MESSAGE );
    }
}