public with sharing class SchemaSnapshot {
    public Map<String, SObjectInfo> objects = new Map<String, SObjectInfo>();

    public class SObjectInfo {
        public String apiName;
        public Map<String, FieldInfo> fields = new Map<String, FieldInfo>();
        public List<String> childRelationships = new List<String>();
    }

    public class FieldInfo {
        public String apiName;
        public String type;
        public Boolean nillable;
        public Boolean createable;
        public Boolean updateable;
        public List<String> picklistValues = new List<String>();
    }

    public static SchemaSnapshot buildSnapshot(Set<String> includeObjects) {
        SchemaSnapshot snap = new SchemaSnapshot();
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

        for (String objectName : globalDescribe.keySet()) {
            if (includeObjects != null && !includeObjects.isEmpty() && !includeObjects.contains(objectName)) {
                continue;
            }

            Schema.DescribeSObjectResult describe = globalDescribe.get(objectName).getDescribe();
            // Focus on objects that can be acted upon
            if (!describe.isCreateable() && !describe.isUpdateable()) {
                continue;
            }

            SObjectInfo info = new SObjectInfo();
            info.apiName = objectName;

            Map<String, Schema.SObjectField> fieldMap = describe.fields.getMap();
            List<String> fieldNames = new List<String>(fieldMap.keySet());
            fieldNames.sort();

            for (String fieldName : fieldNames) {
                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
                FieldInfo fieldInfo = new FieldInfo();
                fieldInfo.apiName = fieldName;
                fieldInfo.type = String.valueOf(fieldDescribe.getType());
                fieldInfo.nillable = fieldDescribe.isNillable();
                fieldInfo.createable = fieldDescribe.isCreateable();
                fieldInfo.updateable = fieldDescribe.isUpdateable();

                if (fieldDescribe.getType() == Schema.DisplayType.Picklist) {
                    for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
                        fieldInfo.picklistValues.add(entry.getValue());
                    }
                }

                info.fields.put(fieldName, fieldInfo);
            }

            for (Schema.ChildRelationship relationship : describe.getChildRelationships()) {
                if (relationship == null) {
                    continue;
                }
                String relName = String.valueOf(relationship.getRelationshipName());
                info.childRelationships.add(relationship.getChildSObject() + '.' + relName);
            }

            snap.objects.put(objectName, info);
        }

        return snap;
    }
}
