public with sharing class BlueprintRecommendationService {
    public class RecommendationResponse {
        public List<PlanModels.ActionBlueprint> blueprints;
        public List<PlanModels.Recommendation> recommendations;

        public RecommendationResponse() {
            blueprints = new List<PlanModels.ActionBlueprint>();
            recommendations = new List<PlanModels.Recommendation>();
        }
    }

    public static RecommendationResponse recommend(String goal, Map<String, Object> schemaSlice, Map<String, Object> constraints) {
        List<PlanModels.ActionBlueprint> blueprints = BlueprintSynthesisService.buildBlueprints(goal, schemaSlice, constraints);
        return fromBlueprints(goal, blueprints);
    }

    public static RecommendationResponse fromBlueprints(String goal, List<PlanModels.ActionBlueprint> blueprints) {
        RecommendationResponse response = new RecommendationResponse();
        if (blueprints == null) {
            return response;
        }
        response.blueprints.addAll(blueprints);

        Integer index = 0;
        for (PlanModels.ActionBlueprint bp : blueprints) {
            if (bp == null) {
                continue;
            }
            PlanModels.Recommendation recommendation = new PlanModels.Recommendation();
            recommendation.name = String.isBlank(bp.label) ? bp.name : bp.label;
            recommendation.blueprint = bp;
            recommendation.score = calculateScore(bp, index);
            recommendation.rationale = buildRationale(bp, goal);
            response.recommendations.add(recommendation);
            index++;
        }
        response.recommendations.sort(new RecommendationSorter());
        return response;
    }

    private static Decimal calculateScore(PlanModels.ActionBlueprint bp, Integer index) {
        Decimal base = Math.max(0, 1 - (Decimal.valueOf(index) * 0.15));
        Decimal guardrailScore = (bp.guardrails != null && !bp.guardrails.isEmpty()) ? 0.1 : 0;
        Decimal inputScore = (bp.inputs != null) ? Math.min(0.2, Decimal.valueOf(bp.inputs.size()) * 0.02) : 0;
        Decimal summaryScore = !String.isBlank(bp.summary) ? 0.05 : 0;
        return (base + guardrailScore + inputScore + summaryScore).setScale(2);
    }

    private static String buildRationale(PlanModels.ActionBlueprint bp, String goal) {
        List<String> parts = new List<String>();
        if (!String.isBlank(bp.targetSObject)) {
            parts.add('Targets ' + bp.targetSObject);
        }
        if (bp.inputs != null && !bp.inputs.isEmpty()) {
            parts.add(bp.inputs.size() + ' required data points');
        }
        if (bp.guardrails != null && !bp.guardrails.isEmpty()) {
            parts.add('Includes ' + bp.guardrails.size() + ' guardrails');
        }
        if (String.isBlank(goal) == false) {
            parts.add('Relevant to goal: ' + goal.left(Math.min(goal.length(), 60)));
        }
        return String.join(parts, ' · ');
    }

    private class RecommendationSorter implements System.Comparator<PlanModels.Recommendation> {
        public Integer compare(PlanModels.Recommendation a, PlanModels.Recommendation b) {
            if (a == null && b == null) return 0;
            if (a == null) return 1;
            if (b == null) return -1;
            if (a.score == null && b.score == null) return 0;
            if (a.score == null) return 1;
            if (b.score == null) return -1;
            Integer scoreCompare = -1 * a.score.compareTo(b.score);
            if (scoreCompare != 0) {
                return scoreCompare;
            }
            String nameA = String.isBlank(a.name) ? '' : a.name;
            String nameB = String.isBlank(b.name) ? '' : b.name;
            return nameA.compareToIgnoreCase(nameB);
        }
    }
}
