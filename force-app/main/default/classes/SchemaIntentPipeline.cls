public with sharing class SchemaIntentPipeline {
    public class Options {
        @AuraEnabled public SchemaSnapshotService.Options schemaOptions;
        @AuraEnabled public Map<String, Object> constraints;
        @AuraEnabled public String blueprintName;

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

        BlueprintLibraryData.LibraryEntry curatedEntry = !String.isBlank(resolved.blueprintName)
            ? BlueprintLibraryService.getEntry(resolved.blueprintName)
            : null;
        PlanModels.ActionBlueprint curatedBlueprint = (curatedEntry != null) ? curatedEntry.blueprint : null;

        String effectiveGoal = goal;
        if (String.isBlank(effectiveGoal) && curatedEntry != null) {
            effectiveGoal = String.isBlank(curatedEntry.description) ? curatedEntry.name : curatedEntry.description;
        }

        List<PlanModels.ActionBlueprint> actionBlueprints = new List<PlanModels.ActionBlueprint>();
        result.recommendations = new List<PlanModels.Recommendation>();

        if (curatedBlueprint != null) {
            actionBlueprints.add(curatedBlueprint);

            PlanModels.Recommendation rec = new PlanModels.Recommendation();
            rec.name = String.isBlank(curatedBlueprint.label) ? curatedBlueprint.name : curatedBlueprint.label;
            rec.blueprint = curatedBlueprint;
            rec.source = 'CURATED';
            if (curatedEntry != null && curatedEntry.tags != null) {
                rec.tags.addAll(curatedEntry.tags);
            }
            rec.score = Decimal.valueOf('1');
            rec.rationale = String.isBlank(curatedEntry != null ? curatedEntry.description : null)
                ? 'Curated library blueprint'
                : curatedEntry.description;
            result.recommendations.add(rec);
        } else {
            BlueprintRecommendationService.RecommendationResponse recommendationResponse =
                BlueprintRecommendationService.recommend(effectiveGoal, schemaSlice, resolved.constraints);
            actionBlueprints.addAll(recommendationResponse.blueprints);
            result.recommendations.addAll(recommendationResponse.recommendations);
        }

        PlanModels.Plan plan = DynamicActionPlanner.buildPlan(effectiveGoal, schemaSlice, resolved.constraints, actionBlueprints);
        result.plan = plan;

        result.artifacts = CodeGenService.generate(plan.actions);
        return result;
    }
}
