/**
 * Created by danieljohnson on 25/02/2025.
 */

public with sharing class TestFactoryFramework {

    public static SObject createSObject(SObject sObj) {
        String objectName = String.valueOf(sObj.getSObjectType());
        String defaultClassName = objectName.replaceAll('__(c|C)$|__', '') + 'Defaults';

        if (Type.forName('TestFactoryFrameworkDefaults.' + defaultClassName) != null) {
            sObj = createSObject(sObj, 'TestFactoryFrameworkDefaults.' + defaultClassName);
        }
        return sObj;
    }

    public static SObject createSObject(SObject sObj, Boolean doInsert) {
        SObject retObject = createSObject(sObj);

        if(doInsert) insert retObject;

        return retObject;
    }

    public static SObject createSObject(SObject sObj, String defaultClassName) {
        Type t = Type.forName(defaultClassName);

        if(t == null) throw new TestFactoryException('Invalid defaults class.');

        FieldDefaults defaults = (FieldDefaults)t.newInstance();
        addFieldDefaults(sObj, defaults.getFieldDefaults());

        return sObj;
    }

    public static SObject createSObject(SObject sObj, String defaultClassName, Boolean doInsert) {
        SObject retObject = createSObject(sObj, defaultClassName);

        if(doInsert) insert retObject;

        return retObject;
    }

    public static SObject[] createSObjectList(SObject sObj, Integer numberOfObjects) {
        return createSObjectList(sObj, numberOfObjects, (String)null);
    }

    public static SObject[] createSObjectList(SObject sObj, Integer numberOfObjects, Boolean doInsert) {
        SObject[] retList = createSObjectList(sObj, numberOfObjects, (String)null);

        if(doInsert) insert retList;

        return retList;
    }

    public static SObject[] createSObjectList(SObject sObj, Integer numberOfObjects, String defaultClassName, Boolean doInsert) {
        SObject[] retList = createSObjectList(sObj, numberOfObjects, defaultClassName);

        if(doInsert) insert retList;

        return retList;
    }

    public static SObject[] createSObjectList(SObject sObj, Integer numberOfObjects, String defaultClassName) {
        SObject[] sObjs = new SObject[] {};
        SObject newObj;

        if (defaultClassName == null) {
            newObj = createSObject(sObj);
        } else {
            newObj = createSObject(sObj, defaultClassName);
        }

        String nameField = String.valueOf(nameFieldMap.get(sObj.getSObjectType()));
        if (nameField == null) {
            nameField = 'Name';
        }
        Boolean nameIsAutoNumber = sObj.getSObjectType().getDescribe().fields.getMap().get(nameField)?.getDescribe().isAutoNumber();

        for (Integer i = 0; i < numberOfObjects; i++) {
            SObject clonedSObj = newObj.clone(false, true);
            if (nameIsAutoNumber == false) {
                clonedSObj.put(nameField, (String)clonedSObj.get(nameField) + ' ' + i);
            }
            sObjs.add(clonedSObj);
        }
        return sObjs;
    }

    private static void addFieldDefaults(SObject sObj, Map<Schema.SObjectField, Object> defaults) {
        Map<String, Object> populatedFields = sObj.getPopulatedFieldsAsMap();

        for (Schema.SObjectField field : defaults.keySet()) {
            if (!populatedFields.containsKey(String.valueOf(field))) {
                sObj.put(field, defaults.get(field));
            }
        }
    }

    private static Map<Schema.SObjectType, Schema.SObjectField> nameFieldMap = new Map<Schema.SObjectType, Schema.SObjectField> {
            Contact.SObjectType => Contact.LastName,
            Case.SObjectType => Case.CaseNumber
    };

    public class TestFactoryException extends Exception {}

    public interface FieldDefaults {
        Map<Schema.SObjectField, Object> getFieldDefaults();
    }
}