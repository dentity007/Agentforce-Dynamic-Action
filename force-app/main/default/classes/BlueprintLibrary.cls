public with sharing class BlueprintLibrary {
    public class Entry {
        public String name;
        public List<String> tags;
        public PlanModels.ActionBlueprint blueprint;
    }

    private class InputParseResult {
        public List<PlanModels.ActionInput> inputs = new List<PlanModels.ActionInput>();
        public List<PlanModels.Guardrail> guardrails = new List<PlanModels.Guardrail>();
    }

    private static List<Entry> cachedEntries;

    public static List<Entry> loadAll() {
        if (cachedEntries == null) {
            cachedEntries = loadFromStaticResource();
        }
        return cloneEntries(cachedEntries);
    }

    public static Entry getEntry(String name) {
        if (String.isBlank(name)) {
            return null;
        }
        for (Entry entry : loadAll()) {
            if (entry != null && name.equalsIgnoreCase(entry.name)) {
                return entry;
            }
        }
        return null;
    }

    public static PlanModels.ActionBlueprint getByName(String name) {
        Entry entry = getEntry(name);
        if (entry == null || entry.blueprint == null) {
            throw new AuraHandledException('Unknown blueprint: ' + name);
        }
        return cloneBlueprint(entry.blueprint);
    }

    private static List<Entry> loadFromStaticResource() {
        List<Entry> entries = new List<Entry>();
        try {
            Blob payload = Resource.BlueprintLibrary.getContents();
            if (payload == null) {
                return entries;
            }
            String json = payload.toString();
            List<Object> rawEntries = (List<Object>) JSON.deserializeUntyped(json);
            for (Object raw : rawEntries) {
                if (!(raw instanceof Map<String, Object>)) {
                    continue;
                }
                Map<String, Object> data = (Map<String, Object>) raw;
                Entry entry = parseEntry(data);
                if (entry != null) {
                    entries.add(entry);
                }
            }
        } catch (Exception ex) {
            System.debug('BlueprintLibrary: failed to load curated entries: ' + ex.getMessage());
        }
        return entries;
    }

    private static Entry parseEntry(Map<String, Object> data) {
        if (data == null || !data.containsKey('name')) {
            return null;
        }
        Entry entry = new Entry();
        entry.name = (String) data.get('name');
        entry.tags = toStringList((List<Object>) data.get('tags'));

        PlanModels.ActionBlueprint blueprint = new PlanModels.ActionBlueprint();
        blueprint.name = chooseActionName(entry.name, (String) data.get('actionName'));
        blueprint.label = chooseLabel((String) data.get('label'), blueprint.name);
        blueprint.category = String.isBlank((String) data.get('category')) ? 'DOMAIN' : (String) data.get('category');
        blueprint.targetSObject = (String) data.get('targetSObject');
        blueprint.operation = (String) data.get('operation');
        blueprint.checkpoint = (String) data.get('checkpoint');
        blueprint.summary = !String.isBlank((String) data.get('summary')) ? (String) data.get('summary') : blueprint.checkpoint;

        InputParseResult inputParse = parseInputs((Map<String, Object>) data.get('inputs'));
        blueprint.inputs.addAll(inputParse.inputs);

        List<String> keyFields = toStringList((List<Object>) data.get('keyFields'));
        if (keyFields.isEmpty()) {
            keyFields.add('Id');
        }
        blueprint.keyFields.addAll(keyFields);

        List<PlanModels.Guardrail> guardrails = new List<PlanModels.Guardrail>();
        guardrails.addAll(inputParse.guardrails);
        guardrails.addAll(parseAdditionalGuardrails((Map<String, Object>) data.get('guardrails')));
        blueprint.guardrails = guardrails;

        entry.blueprint = blueprint;
        return entry;
    }

    private static InputParseResult parseInputs(Map<String, Object> node) {
        InputParseResult result = new InputParseResult();
        if (node == null) {
            return result;
        }
        List<String> fieldNames = new List<String>(node.keySet());
        fieldNames.sort();
        for (String fieldName : fieldNames) {
            Map<String, Object> info = (Map<String, Object>) node.get(fieldName);
            PlanModels.ActionInput input = new PlanModels.ActionInput();
            input.apiName = fieldName;
            input.fieldApiName = fieldName;
            input.label = chooseLabel((info == null) ? null : (String) info.get('label'), fieldName);
            input.dataType = (info == null) ? 'String' : (String) info.get('type');
            input.required = info != null && info.containsKey('required') ? (Boolean) info.get('required') : false;
            input.usage = 'FIELD';
            if (info != null && info.containsKey('description')) {
                input.description = (String) info.get('description');
            }
            result.inputs.add(input);

            if (info != null && info.containsKey('enum')) {
                List<String> enumValues = toStringList((List<Object>) info.get('enum'));
                if (!enumValues.isEmpty()) {
                    PlanModels.Guardrail guardrail = new PlanModels.Guardrail();
                    guardrail.type = 'ENUM_ALLOWED';
                    guardrail.params = new Map<String, Object>{
                        'field' => fieldName,
                        'values' => enumValues
                    };
                    result.guardrails.add(guardrail);
                }
            }
        }
        return result;
    }

    private static List<PlanModels.Guardrail> parseAdditionalGuardrails(Map<String, Object> config) {
        List<PlanModels.Guardrail> guardrails = new List<PlanModels.Guardrail>();
        if (config == null) {
            return guardrails;
        }
        if (config.containsKey('fls')) {
            Map<String, Object> fls = (Map<String, Object>) config.get('fls');
            List<String> fields = toStringList((List<Object>) fls.get('fields'));
            if (!fields.isEmpty()) {
                Boolean requireUpdateable = fls.containsKey('requireUpdateable') ? (Boolean) fls.get('requireUpdateable') : true;
                PlanModels.Guardrail guardrail = new PlanModels.Guardrail();
                guardrail.type = requireUpdateable ? 'FLS_EDIT' : 'FLS_ACCESS';
                guardrail.params = new Map<String, Object>{ 'fields' => fields };
                guardrails.add(guardrail);
            }
        }
        if (config.containsKey('sharing')) {
            PlanModels.Guardrail guardrail = new PlanModels.Guardrail();
            guardrail.type = 'SHARING_REQUIRED';
            guardrail.params = new Map<String, Object>();
            guardrails.add(guardrail);
        }
        if (config.containsKey('enum')) {
            for (Object item : (List<Object>) config.get('enum')) {
                Map<String, Object> enumConfig = (Map<String, Object>) item;
                String field = (String) enumConfig.get('field');
                List<String> values = toStringList((List<Object>) enumConfig.get('values'));
                if (!String.isBlank(field) && !values.isEmpty()) {
                    PlanModels.Guardrail guardrail = new PlanModels.Guardrail();
                    guardrail.type = 'ENUM_ALLOWED';
                    guardrail.params = new Map<String, Object>{
                        'field' => field,
                        'values' => values
                    };
                    guardrails.add(guardrail);
                }
            }
        }
        if (config.containsKey('numericPositive')) {
            for (Object fieldObj : (List<Object>) config.get('numericPositive')) {
                String field = String.valueOf(fieldObj);
                if (!String.isBlank(field)) {
                    PlanModels.Guardrail guardrail = new PlanModels.Guardrail();
                    guardrail.type = 'NUMERIC_POSITIVE';
                    guardrail.params = new Map<String, Object>{ 'field' => field };
                    guardrails.add(guardrail);
                }
            }
        }
        if (config.containsKey('pii')) {
            Map<String, Object> pii = (Map<String, Object>) config.get('pii');
            List<String> fields = toStringList((List<Object>) pii.get('fields'));
            if (!fields.isEmpty()) {
                PlanModels.Guardrail guardrail = new PlanModels.Guardrail();
                guardrail.type = 'PII_REDACT';
                guardrail.params = new Map<String, Object>{ 'fields' => fields };
                guardrails.add(guardrail);
            }
        }
        return guardrails;
    }

    private static List<String> toStringList(List<Object> raw) {
        List<String> values = new List<String>();
        if (raw == null) {
            return values;
        }
        for (Object item : raw) {
            if (item == null) continue;
            values.add(String.valueOf(item));
        }
        return values;
    }

    private static String chooseActionName(String fallback, String explicit) {
        if (!String.isBlank(explicit)) {
            return explicit;
        }
        return toPascalCase(fallback);
    }

    private static String chooseLabel(String label, String fallback) {
        if (!String.isBlank(label)) {
            return label;
        }
        return toSentenceCase(fallback);
    }

    private static String toPascalCase(String value) {
        if (String.isBlank(value)) {
            return 'GeneratedAction';
        }
        String cleaned = value.replaceAll('[^A-Za-z0-9_]', ' ');
        List<String> parts = cleaned.trim().split(' ');
        String result = '';
        for (String part : parts) {
            if (String.isBlank(part)) continue;
            result += part.substring(0, 1).toUpperCase() + part.substring(1).toLowerCase();
        }
        return String.isBlank(result) ? 'GeneratedAction' : result;
    }

    private static String toSentenceCase(String value) {
        if (String.isBlank(value)) {
            return value;
        }
        String spaced = value.replaceAll('([a-z])([A-Z])', '$1 $2').replace('_', ' ');
        return spaced.substring(0, 1).toUpperCase() + spaced.substring(1);
    }

    private static List<Entry> cloneEntries(List<Entry> entries) {
        List<Entry> clones = new List<Entry>();
        for (Entry entry : entries) {
            if (entry == null) continue;
            Entry clone = new Entry();
            clone.name = entry.name;
            clone.tags = new List<String>(entry.tags);
            clone.blueprint = cloneBlueprint(entry.blueprint);
            clones.add(clone);
        }
        return clones;
    }

    private static PlanModels.ActionBlueprint cloneBlueprint(PlanModels.ActionBlueprint blueprint) {
        if (blueprint == null) {
            return null;
        }
        return (PlanModels.ActionBlueprint) JSON.deserialize(JSON.serialize(blueprint), PlanModels.ActionBlueprint.class);
    }
}
