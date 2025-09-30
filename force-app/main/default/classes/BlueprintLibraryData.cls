public with sharing class BlueprintLibraryData {
    public class LibraryEntry {
        public String name;
        public List<String> tags;
        public String description;
        public PlanModels.ActionBlueprint blueprint;
    }

    public static List<LibraryEntry> load() {
        List<LibraryEntry> entries = new List<LibraryEntry>();
        for (Object raw : (List<Object>) JSON.deserializeUntyped(libraryJson())) {
            Map<String, Object> data = (Map<String, Object>) raw;
            LibraryEntry entry = new LibraryEntry();
            entry.name = (String) data.get('name');
            entry.description = (String) data.get('description');
            entry.tags = new List<String>();
            if (data.containsKey('tags') && data.get('tags') != null) {
                for (Object t : (List<Object>) data.get('tags')) {
                    entry.tags.add(String.valueOf(t));
                }
            }
            entry.blueprint = (PlanModels.ActionBlueprint) JSON.deserialize(
                JSON.serialize(data.get('blueprint')),
                PlanModels.ActionBlueprint.class
            );
            entries.add(entry);
        }
        return entries;
    }

    private static String libraryJson() {
        return '[\n' +
            '  {\n' +
            '    "name": "oppty_closed_won",\n' +
            '    "description": "Updates opportunity stage with guardrails.",\n' +
            '    "tags": ["sales", "opportunity", "closedwon"],\n' +
            '    "blueprint": ' + opportunityBlueprintJson() + '\n' +
            '  },\n' +
            '  {\n' +
            '    "name": "lead_qualify",\n' +
            '    "description": "Qualifies a lead and sets status/rating.",\n' +
            '    "tags": ["sales", "lead", "qualification"],\n' +
            '    "blueprint": ' + leadBlueprintJson() + '\n' +
            '  },\n' +
            '  {\n' +
            '    "name": "case_escalate",\n' +
            '    "description": "Escalates a service case with PII guardrails.",\n' +
            '    "tags": ["service", "case", "escalation"],\n' +
            '    "blueprint": ' + caseBlueprintJson() + '\n' +
            '  }\n' +
            ']';
    }

    private static String opportunityBlueprintJson() {
        return '{"name":"UpdateOpportunityStage","label":"Update Opportunity Stage","category":"DOMAIN","targetSObject":"Opportunity","operation":"UPDATE","summary":"Updated Opportunity stage to Closed Won with optional close date.","checkpoint":"I will update the Opportunity stage to Closed Won. Proceed?","keyFields":["Id"],"inputs":[{"apiName":"Id","fieldApiName":"Id","label":"Opportunity Id","dataType":"Id","required":true,"usage":"FIELD"},{"apiName":"StageName","fieldApiName":"StageName","label":"New Stage","dataType":"String","required":true,"usage":"FIELD"},{"apiName":"CloseDate","fieldApiName":"CloseDate","label":"Close Date","dataType":"Date","required":false,"usage":"FIELD"}],"guardrails":[{"type":"FLS_EDIT","params":{"fields":["Id","StageName","CloseDate"]}},{"type":"ENUM_ALLOWED","params":{"field":"StageName","values":["Prospecting","Qualification","Value Proposition","Closed Won","Closed Lost"]}}]}';
    }

    private static String leadBlueprintJson() {
        return '{"name":"QualifyLead","label":"Qualify Lead","category":"DOMAIN","targetSObject":"Lead","operation":"UPDATE","summary":"Qualified a lead and updated status, rating, and converted flags.","checkpoint":"I will qualify the lead and update its status. Proceed?","keyFields":["Id"],"inputs":[{"apiName":"Id","fieldApiName":"Id","label":"Lead Id","dataType":"Id","required":true,"usage":"FIELD"},{"apiName":"Status","fieldApiName":"Status","label":"Lead Status","dataType":"String","required":true,"usage":"FIELD"},{"apiName":"Rating","fieldApiName":"Rating","label":"Lead Rating","dataType":"String","required":false,"usage":"FIELD"},{"apiName":"IsConverted","fieldApiName":"IsConverted","label":"Converted?","dataType":"Boolean","required":false,"usage":"FIELD"}],"guardrails":[{"type":"FLS_EDIT","params":{"fields":["Status","Rating","IsConverted"]}},{"type":"ENUM_ALLOWED","params":{"field":"Status","values":["New","Working","Qualified","Unqualified"]}}]}';
    }

    private static String caseBlueprintJson() {
        return '{"name":"EscalateCase","label":"Escalate Case","category":"DOMAIN","targetSObject":"Case","operation":"UPDATE","summary":"Escalated service case with priority and owner updates.","checkpoint":"I will escalate the case and notify the assigned owner. Proceed?","keyFields":["Id"],"inputs":[{"apiName":"Id","fieldApiName":"Id","label":"Case Id","dataType":"Id","required":true,"usage":"FIELD"},{"apiName":"Status","fieldApiName":"Status","label":"Case Status","dataType":"String","required":true,"usage":"FIELD"},{"apiName":"Priority","fieldApiName":"Priority","label":"Priority","dataType":"String","required":true,"usage":"FIELD"},{"apiName":"Escalation_Notes__c","fieldApiName":"Escalation_Notes__c","label":"Escalation Notes","dataType":"String","required":false,"usage":"FIELD"},{"apiName":"OwnerId","fieldApiName":"OwnerId","label":"New Owner","dataType":"Id","required":false,"usage":"FIELD"}],"guardrails":[{"type":"FLS_EDIT","params":{"fields":["Status","Priority","Escalation_Notes__c","OwnerId"]}},{"type":"ENUM_ALLOWED","params":{"field":"Priority","values":["High","Medium","Low"]}},{"type":"PII_REDACT","params":{"fields":["Escalation_Notes__c"]},"message":"Escalation notes must exclude PII."}]}';
    }
}
