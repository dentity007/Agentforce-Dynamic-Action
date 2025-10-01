public with sharing class RecommendFunctionalities {
    public class Response {
        public List<HeuristicRanker.Recommendation> recommendations;
    }

    @AuraEnabled(cacheable=true)
    public static Response run(String businessNarrative, List<String> includeObjects, Integer topK) {
        // 1) Schema
        SchemaSnapshot snap = SchemaSnapshot.buildSnapshot(includeObjects == null ? new Set<String>() : new Set<String>(includeObjects));

        // 2) Candidates from curated library (and optionally heuristics)
        List<PlanModels.ActionBlueprint> candidates = BlueprintLibrary.candidates();
        if (candidates.isEmpty()) {
            // Fallback to your heuristic generator if you have one; else return empty.
            candidates = new List<PlanModels.ActionBlueprint>();
        }

        // 3) Rank (heuristics + optional LLM blend)
        List<HeuristicRanker.Recommendation> h = HeuristicRanker.rank(businessNarrative, snap, candidates, topK);
        List<HeuristicRanker.Recommendation> blended = h;
        List<HeuristicRanker.Recommendation> l = LLMRanker.tryRank(businessNarrative, snap, candidates, topK);
        if (!l.isEmpty()) {
            // Simple blend: prefer LLM order but ensure heuristic top-1 present
            Set<String> seen = new Set<String>();
            List<HeuristicRanker.Recommendation> merged = new List<HeuristicRanker.Recommendation>();
            for (HeuristicRanker.Recommendation r : l) { merged.add(r); seen.add(r.blueprint.name); }
            for (HeuristicRanker.Recommendation r : h) if (!seen.contains(r.blueprint.name)) merged.add(r);
            blended = merged.subList(0, Math.min(topK == null ? 3 : topK, merged.size()));
        }

        Response resp = new Response();
        resp.recommendations = blended;
        return resp;
    }
}