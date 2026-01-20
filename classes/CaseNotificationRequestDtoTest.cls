/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class CaseNotificationRequestDtoTest {

    @isTest
    static void testDtoInstantiationAndSerialization() {
        // Crear instancia de Typology
        CaseNotificationRequestDto.Typology typo = new CaseNotificationRequestDto.Typology();
        typo.type = 'Reclamo';
        typo.reason = 'Demora en atención';

        // Crear instancia del DTO principal
        CaseNotificationRequestDto dto = new CaseNotificationRequestDto();
        dto.caseId = '500XXXXXXXXXXXX';
        dto.personCode = '12345';
        dto.origin = 'Web';
        dto.event = 'SF_CASE_EVENT_NEW';
        dto.caseNumber = '00012345';
        dto.typology = typo;

        // Afirmaciones con mensajes
        System.assertEquals('12345', dto.personCode, 'El personCode debería ser "12345".');
        System.assertEquals('SF_CASE_EVENT_NEW', dto.event, 'El event debería ser "SF_CASE_EVENT_NEW".');
        System.assertEquals('Demora en atención', dto.typology.reason, 'El reason debería ser "Demora en atención".');

        // Serialización
        String json = JSON.serialize(dto);
        System.debug('Serialized DTO: ' + json);
        System.assert(json.contains('SF_CASE_EVENT_NEW'), 'El JSON debería contener el valor del evento.');
    }
}