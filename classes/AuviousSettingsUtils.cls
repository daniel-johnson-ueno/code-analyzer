/**
 * @name               : AuviousSettingsUtils
 * @author             : Alvaro Gonzales Lapponi
 * @creation date      : 14-02-2025
 * @modification date  : 12-03-2025
 * @last modified by   : Alvaro Gonzales Lapponi
 * @description        : Clase utilitaria para la custom metadata Auvious Settings (AuviousSettings__mdt)
 * @versions           : version 1.0: clase apex inicial 
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   14-02-2025   Alvaro Gonzales Lapponi   Initial Version
**/
public with sharing class AuviousSettingsUtils {
    
    /**
    * @description Obtiene la metadata de las configuraciones del widget de Auvious que solicita videollamadas.
    * @author Alvaro Gonzales Lapponi | 12-03-2025 
    * @param String developerName 
    * @return AuviousSettings__mdt 
    **/
    @AuraEnabled(cacheable=true)
    public static AuviousSettings__mdt fetchSettings(String developerName){
        AuviousSettings__mdt settings = AuviousSettings__mdt.getInstance(developerName);
        return AuviousSettings__mdt.getInstance(developerName);
    }
}