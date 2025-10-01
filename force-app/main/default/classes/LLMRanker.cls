public with sharing class LLMRanker {
    public static List<HeuristicRanker.Recommendation> tryRank(String narrative, SchemaSnapshot snap, List<PlanModels.ActionBlueprint> cands, Integer topK) {
        if (!LLMClientGateway.isRegistered()) return new List<HeuristicRanker.Recommendation>();

        String prompt = buildPrompt(narrative, snap, cands);
        String raw = LLMClientGateway.current().complete(prompt);
        // Expect JSON: [{name:"...", score:0-1, rationale:"..."}]
        List<Object> arr = (List<Object>) JSON.deserializeUntyped(raw);
        Map<String, HeuristicRanker.Recommendation> byName = new Map<String, HeuristicRanker.Recommendation>();

        for (Object o : arr) {
            Map<String,Object> m = (Map<String,Object>) o;
            String name = (String) m.get('name');
            Decimal score = (Decimal) (m.get('score') == null ? 0 : Decimal.valueOf(String.valueOf(m.get('score'))));
            String rationale = (String) m.get('rationale');
            byName.put(name, new HeuristicRanker.Recommendation());
            byName.get(name).score = score;
            byName.get(name).rationale = rationale;
            byName.get(name).source = 'llm';
        }
        // Attach blueprints
        for (PlanModels.ActionBlueprint bp : cands) {
            if (byName.containsKey(bp.name)) {
                HeuristicRanker.Recommendation r = byName.get(bp.name);
                r.blueprint = bp;
            }
        }
        List<HeuristicRanker.Recommendation> recs = new List<HeuristicRanker.Recommendation>();
        recs.addAll(byName.values());
        recs.sort(new HeuristicRanker.Comparator());
        if (topK == null || topK <= 0) topK = 3;
        return recs.subList(0, Math.min(topK, recs.size()));
    }

    private static String buildPrompt(String narrative, SchemaSnapshot snap, List<PlanModels.ActionBlueprint> cands) {
        Map<String,Object> p = new Map<String,Object>{
            'narrative' => narrative,
            'schemaSummary' => new List<String>(snap.objects.keySet()),
            'candidates' => cands
        };
        return 'Rank the candidate action blueprints for this business goal. Return JSON array of {name,score(0..1),rationale}. ' + JSON.serialize(p);
    }
}