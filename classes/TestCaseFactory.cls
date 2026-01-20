/**
 * Created by alexis on 21/02/2025.
 */
@IsTest
public with sharing class TestCaseFactory {
    public static Case createNewCase (String origin, RecordType recordType){
        Case newCase = new Case();
        newCase.Origin = origin;
        newCase.Status = 'Nuevo';
        newCase.RecordType = recordType;
        newCase.RecordTypeId =  recordType.Id;

        insert newCase;

        return newCase;
    }

    public static Case createNewCase (String origin, RecordType recordType, Account account){
        Case newCase = new Case();
        newCase.Origin = origin;
        newCase.Status = 'Nuevo';
        newCase.RecordType = recordType;
        newCase.RecordTypeId =  recordType.Id;
        newCase.Account = account;
        newCase.AccountId = account.Id;

        insert newCase;

        return newCase;
    }
}