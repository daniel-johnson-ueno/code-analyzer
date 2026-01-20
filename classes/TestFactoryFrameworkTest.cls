/**
 * Created by danieljohnson on 25/02/2025.
 */

@IsTest
public class TestFactoryFrameworkTest {

    @TestSetup
    private static void setupTest() {

        //Crear Registro SIN insertarlo y SIN valores por default porque no existe TestFactoryFrameworkDefaults.AccountDefaults
        Account testAccount2 = (Account)TestFactoryFramework.createSObject(new Account());


        //Crea Registro con valores por default, porque SI existe TestFactoryFrameworkDefaults.ContactDefaults
        Contact testContact = (Contact)TestFactoryFramework.createSObject(new Contact(), true);


        //Crear Registro SIN Insertarlo, si no se le pasa el parametro doInsert, o si se lo pasa en false, no se inserta el registro,
        //dando la posibilidad de agregar valores o modificarlos antes de el insert.
        Account testAccount1 = (Account)TestFactoryFramework.createSObject(new Account());
        testAccount1.Name = 'Sin valores por dafault';
        insert testAccount1;


        //Crea un registro con un set de valores por default especificos.
        //Se pueden crear clases especificas para valores por dafault, como por ejemplo para diferentes recordTypes, en este caso para Accounts.
        Account testPersonAccount = (Account)TestFactoryFramework.createSObject(new Account(), 'TestFactoryFrameworkDefaults.PersonAccountDefaults', true);


        //En caso se ser necesario crear varios registros a la vez, se puede usareste metodo seteando la cantidad de registros a crear
        //Al igual que con todos los otros metodos, se pueden setear los valores por defecto y se pueden insertar los registros o no.
        Account[] aList = (Account[])TestFactoryFramework.createSObjectList(new Account(), 200, 'TestFactoryFrameworkDefaults.PersonAccountDefaults');

        Account testBusinessAccount = (Account)TestFactoryFramework.createSObject(new Account(), 'TestFactoryFrameworkDefaults.BusinessAccountDefaults', true);

        Account testInternalCompany = (Account)TestFactoryFramework.createSObject(new Account(), 'TestFactoryFrameworkDefaults.InternalCompanyAccountDefaults', true);

        Case testReclamoFraudeCase = (Case)TestFactoryFramework.createSObject(new Case(), 'TestFactoryFrameworkDefaults.ReclamoFraudeCaseDefaults', true);

        Case testSolicitudCaseDefaults = (Case)TestFactoryFramework.createSObject(new Case(), 'TestFactoryFrameworkDefaults.SolicitudCaseDefaults', true);

        Case testConsultaCase = (Case)TestFactoryFramework.createSObject(new Case(), 'TestFactoryFrameworkDefaults.ConsultaCaseDefaults', true);

        Case testReclamoCase = (Case)TestFactoryFramework.createSObject(new Case(), 'TestFactoryFrameworkDefaults.ReclamoCaseDefaults', true);

        Ueno_Service_Domain__c testUenoServiceDomain = (Ueno_Service_Domain__c)TestFactoryFramework.createSObject(new Ueno_Service_Domain__c(), 'TestFactoryFrameworkDefaults.UenoServiceDomainDefaults', true);
        


        
        
    }



    @IsTest
    static void when_ListOfObjectIsInserted_expect_defaultFieldsArePopulated(){

        Account[] aList = (Account[])TestFactoryFramework.createSObjectList(new Account(), 10, 'TestFactoryFrameworkDefaults.PersonAccountDefaults', false);

        for(Account a : aList){
            Assert.areEqual(a.FirstName, 'Test', 'Expecting Default field value is set to specific value');
        }
    }

}