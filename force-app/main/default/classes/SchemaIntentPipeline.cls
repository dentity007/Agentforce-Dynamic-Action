public with sharing class SchemaIntentPipeline {
    public class Options {
        @AuraEnabled public SchemaSnapshotService.Options schemaOptions;
        @AuraEnabled public Map<String, Object> constraints;

        public Options() {
            schemaOptions = new SchemaSnapshotService.Options();
            constraints = new Map<String, Object>();
        }
    }

    public static PlanModels.PipelineResult run(String goal) {
        return run(goal, new Options());
    }

    public static PlanModels.PipelineResult run(String goal, Options options) {
        Options resolved = (options == null) ? new Options() : options;
        PlanModels.PipelineResult result = new PlanModels.PipelineResult();

        Map<String, Object> schemaSlice = SchemaSnapshotService.summarize(resolved.schemaOptions);
        result.schema = schemaSlice;

        BlueprintRecommendationService.RecommendationResponse recommendationResponse =
            BlueprintRecommendationService.recommend(goal, schemaSlice, resolved.constraints);
        result.recommendations = recommendationResponse.recommendations;

        PlanModels.Plan plan = DynamicActionPlanner.buildPlan(goal, schemaSlice, resolved.constraints, recommendationResponse.blueprints);
        result.plan = plan;

        result.artifacts = CodeGenService.generate(plan.actions);
        return result;
    }
}
