public with sharing class BlueprintLibraryData {
    public class LibraryEntry {
        public String name;
        public List<String> tags;
        public String description;
        public PlanModels.ActionBlueprint blueprint;
    }

    public static List<LibraryEntry> load() {
        String json = libraryJson();
        List<Object> rawEntries = (List<Object>) JSON.deserializeUntyped(json);
        List<LibraryEntry> entries = new List<LibraryEntry>();
        for (Object item : rawEntries) {
            Map<String, Object> mapEntry = (Map<String, Object>) item;
            LibraryEntry entry = new LibraryEntry();
            entry.name = (String) mapEntry.get('name');
            entry.description = (String) mapEntry.get('description');
            entry.tags = new List<String>();
            if (mapEntry.containsKey('tags') && mapEntry.get('tags') != null) {
                for (Object rawTag : (List<Object>) mapEntry.get('tags')) {
                    entry.tags.add(String.valueOf(rawTag));
                }
            }
            Object blueprintObj = mapEntry.get('blueprint');
            entry.blueprint = (PlanModels.ActionBlueprint) JSON.deserialize(JSON.serialize(blueprintObj), PlanModels.ActionBlueprint.class);
            entries.add(entry);
        }
        return entries;
    }

    private static String libraryJson() {
        return '[\n' +
            '  {\n' +
            '    "name": "UpdateOpportunityStage",\n' +
            '    "description": "Updates opportunity stage with enumerated values and FLS guardrails.",\n' +
            '    "tags": ["sales", "opportunity", "update"],\n' +
            '    "blueprint": ' + opportunityBlueprintJson() + '\n' +
            '  },\n' +
            '  {\n' +
            '    "name": "CreateFollowUpTask",\n' +
            '    "description": "Creates follow-up task with sharing and privacy guardrails.",\n' +
            '    "tags": ["sales", "task", "pii"],\n' +
            '    "blueprint": ' + followUpBlueprintJson() + '\n' +
            '  },\n' +
            '  {\n' +
            '    "name": "CreateInventoryReservationTask",\n' +
            '    "description": "Creates inventory reservation task with numeric guardrail.",\n' +
            '    "tags": ["inventory", "task", "quantity"],\n' +
            '    "blueprint": ' + inventoryBlueprintJson() + '\n' +
            '  }\n' +
            ']';
    }

    private static String opportunityBlueprintJson() {
        return '{"name":"UpdateOpportunityStage","label":"Update Opportunity Stage","category":"DOMAIN","targetSObject":"Opportunity","operation":"UPDATE","summary":"Updated Opportunity stage based on agent directive.","checkpoint":"I will update the Opportunity stage for the requested deals. Proceed?","keyFields":["Id"],"inputs":[{"apiName":"Id","fieldApiName":"Id","label":"Opportunity Id","dataType":"Id","required":true,"usage":"FIELD"},{"apiName":"StageName","fieldApiName":"StageName","label":"New Stage","dataType":"String","required":true,"usage":"FIELD"},{"apiName":"CloseDate","fieldApiName":"CloseDate","label":"Revised Close Date","dataType":"Date","required":false,"usage":"FIELD"}],"guardrails":[{"type":"FLS_EDIT","params":{"fields":["Id","StageName","CloseDate"]}},{"type":"ENUM_ALLOWED","params":{"field":"StageName","values":["Prospecting","Qualification","Proposal","Negotiation","Closed Won","Closed Lost"]}}]}';
    }

    private static String followUpBlueprintJson() {
        return '{"name":"CreateFollowUpTask","label":"Create Follow Up Task","category":"DOMAIN","targetSObject":"Task","operation":"INSERT","summary":"Logged a follow-up task for the sales rep.","checkpoint":"I will create a follow-up task referencing the customer conversation. Proceed?","inputs":[{"apiName":"Subject","fieldApiName":"Subject","label":"Task Subject","dataType":"String","required":true,"usage":"FIELD"},{"apiName":"WhatId","fieldApiName":"WhatId","label":"Related Record","dataType":"Id","required":true,"usage":"FIELD"},{"apiName":"OwnerId","fieldApiName":"OwnerId","label":"Task Owner","dataType":"Id","required":false,"usage":"FIELD"},{"apiName":"DueDate","fieldApiName":"ActivityDate","label":"Due Date","dataType":"Date","required":false,"usage":"FIELD"}],"guardrails":[{"type":"FLS_EDIT","params":{"fields":["Subject","WhatId","OwnerId","ActivityDate"]}},{"type":"SHARING_REQUIRED"},{"type":"PII_REDACT","params":{"fields":["Description"]},"message":"Task description must be scrubbed of PII before saving."}]}';
    }

    private static String inventoryBlueprintJson() {
        return '{"name":"CreateInventoryReservationTask","label":"Create Inventory Reservation Task","category":"DOMAIN","targetSObject":"Task","operation":"INSERT","summary":"Created a high priority Task to trigger inventory follow-up.","checkpoint":"I will log a Task to request inventory reservation. Proceed?","inputs":[{"apiName":"Subject","fieldApiName":"Subject","label":"Task Subject","dataType":"String","required":true,"usage":"FIELD"},{"apiName":"WhatId","fieldApiName":"WhatId","label":"Product Reference","dataType":"Id","required":true,"usage":"FIELD"},{"apiName":"Quantity__c","fieldApiName":"Quantity__c","label":"Requested Quantity","dataType":"Decimal","required":true,"usage":"FIELD"},{"apiName":"Warehouse__c","fieldApiName":"Warehouse__c","label":"Warehouse","dataType":"Id","required":false,"usage":"FIELD"}],"guardrails":[{"type":"NUMERIC_POSITIVE","params":{"field":"Quantity__c","min":1},"message":"Quantity must be greater than zero."},{"type":"FLS_EDIT","params":{"fields":["Subject","WhatId","Quantity__c","Warehouse__c"]}}]}';
    }
}
