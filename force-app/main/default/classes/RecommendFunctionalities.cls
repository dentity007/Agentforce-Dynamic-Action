public with sharing class RecommendFunctionalities {
    // Harmonized response shape with pipeline: ranked list with rationale + tags
    public class Response { public List<PlanModels.Recommendation> recommendations; }

    // Entry point: narrative + includeObjects (schema gathered internally)
    public static Response run(String businessNarrative, List<String> includeObjects, Integer topK) {
        // Gather a lightweight schema slice, then delegate to blended recommender
        Set<String> objectFilter = (includeObjects == null || includeObjects.isEmpty())
            ? null
            : new Set<String>(includeObjects);
        SchemaSnapshot snap = SchemaSnapshot.buildSnapshot(objectFilter);
        // Convert to Map<String,Object> shape expected by recommender
        Map<String, Object> schemaSlice = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(snap));

        return runWithSchema(businessNarrative, schemaSlice, topK);
    }

    // Overload: accept external schema snapshot from a Data‑Aware agent
    public static Response runWithSchema(String businessNarrative, Map<String, Object> schemaSlice, Integer topK) {
        BlueprintRecommendationService.RecommendationResponse rr =
            BlueprintRecommendationService.recommend(businessNarrative, schemaSlice, null);

        // Optional topK trim
        if (topK != null && topK > 0 && rr.recommendations.size() > topK) {
            rr.recommendations = rr.recommendations.subList(0, topK);
        }

        Response resp = new Response();
        resp.recommendations = rr.recommendations;
        return resp;
    }
}
