public with sharing class BlueprintLibraryService {
    public class MatchResult {
        public BlueprintLibraryData.LibraryEntry entry;
        public Decimal score;
    }

    private static List<BlueprintLibraryData.LibraryEntry> cachedEntries;

    public static List<BlueprintLibraryData.LibraryEntry> allEntries() {
        if (cachedEntries == null) {
            cachedEntries = BlueprintLibraryData.load();
        }
        return cachedEntries.deepClone(true);
    }

    public static BlueprintLibraryData.LibraryEntry getEntry(String name) {
        if (String.isBlank(name)) {
            return null;
        }
        for (BlueprintLibraryData.LibraryEntry entry : allEntries()) {
            if (entry != null && String.valueOf(entry.name).equalsIgnoreCase(name)) {
                return entry;
            }
        }
        return null;
    }

    public static PlanModels.ActionBlueprint getBlueprint(String name) {
        BlueprintLibraryData.LibraryEntry entry = getEntry(name);
        if (entry == null || entry.blueprint == null) {
            return null;
        }
        return (PlanModels.ActionBlueprint) JSON.deserialize(JSON.serialize(entry.blueprint), PlanModels.ActionBlueprint.class);
    }

    public static List<MatchResult> findMatches(String goal, Map<String, Object> schemaSlice, Integer limit) {
        List<MatchResult> matches = new List<MatchResult>();
        String normalizedGoal = (goal == null) ? '' : goal.toLowerCase();
        Set<String> schemaTokens = extractSchemaTokens(schemaSlice);

        for (BlueprintLibraryData.LibraryEntry entry : allEntries()) {
            Decimal score = scoreEntry(entry, normalizedGoal, schemaTokens);
            if (score > 0) {
                MatchResult result = new MatchResult();
                result.entry = entry;
                result.score = score.setScale(2);
                matches.add(result);
            }
        }
        matches.sort(new MatchComparator());
        if (limit != null && limit > 0 && matches.size() > limit) {
            return matches.subList(0, limit);
        }
        return matches;
    }

    private static Decimal scoreEntry(BlueprintLibraryData.LibraryEntry entry, String goal, Set<String> schemaTokens) {
        Decimal score = Decimal.valueOf('0');
        if (entry.tags != null) {
            for (String tag : entry.tags) {
                if (String.isBlank(tag)) continue;
                String lower = tag.toLowerCase();
                if (goal.contains(lower)) {
                    score += Decimal.valueOf('0.4');
                }
                if (schemaTokens.contains(lower)) {
                    score += Decimal.valueOf('0.3');
                }
            }
        }
        if (!String.isBlank(entry.description) && goal.contains(entry.description.toLowerCase().split(' ')[0])) {
            score += Decimal.valueOf('0.1');
        }
        if (score == Decimal.valueOf('0') && goal != null && entry.blueprint != null && !String.isBlank(entry.blueprint.targetSObject)) {
            if (goal.contains(entry.blueprint.targetSObject.toLowerCase())) {
                score += Decimal.valueOf('0.2');
            }
        }
        return score;
    }

    private static Set<String> extractSchemaTokens(Map<String, Object> schemaSlice) {
        Set<String> tokens = new Set<String>();
        if (schemaSlice == null || !schemaSlice.containsKey('objects')) {
            return tokens;
        }
        List<Object> objects = (List<Object>) schemaSlice.get('objects');
        for (Object obj : objects) {
            if (!(obj instanceof Map<String, Object>)) continue;
            Map<String, Object> objectMap = (Map<String, Object>) obj;
            String apiName = (String) objectMap.get('apiName');
            if (!String.isBlank(apiName)) {
                tokens.add(apiName.toLowerCase());
            }
            List<Object> fields = (List<Object>) objectMap.get('fields');
            if (fields == null) continue;
            for (Object fieldObj : fields) {
                if (!(fieldObj instanceof Map<String, Object>)) continue;
                Map<String, Object> fieldMap = (Map<String, Object>) fieldObj;
                String fieldApi = (String) fieldMap.get('apiName');
                if (!String.isBlank(fieldApi)) {
                    tokens.add(fieldApi.toLowerCase());
                }
            }
        }
        return tokens;
    }

    private class MatchComparator implements System.Comparator<MatchResult> {
        public Integer compare(MatchResult a, MatchResult b) {
            if (a == null && b == null) return 0;
            if (a == null) return 1;
            if (b == null) return -1;
            Integer scoreCompare = -1 * a.score.compareTo(b.score);
            if (scoreCompare != 0) {
                return scoreCompare;
            }
            return a.entry.name.compareToIgnoreCase(b.entry.name);
        }
    }
}
