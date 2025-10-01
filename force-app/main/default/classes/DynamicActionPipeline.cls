public with sharing class DynamicActionPipeline {
    public class Result {
        @AuraEnabled public PlanModels.Plan plan;
        @AuraEnabled public PlanModels.CodeArtifacts artifacts;
    }

    public static Result execute(String goal, Map<String, Object> schemaSlice, Map<String, Object> constraints) {
        Result result = new Result();
        result.plan = DynamicActionPlanner.buildPlan(goal, schemaSlice, constraints);
        result.artifacts = CodeGenService.generate(result.plan.actions);
        return result;
    }

    public static Result executeWithBlueprint(String blueprintName, Map<String, Object> schemaSlice, Map<String, Object> constraints) {
        PlanModels.ActionBlueprint blueprint = BlueprintLibraryService.getBlueprint(blueprintName);
        if (blueprint == null) {
            throw new AuraHandledException('Unknown curated blueprint: ' + blueprintName);
        }
        List<PlanModels.ActionBlueprint> blueprints = new List<PlanModels.ActionBlueprint>{ blueprint };
        PlanModels.Plan plan = DynamicActionPlanner.buildPlan(
            String.isBlank(blueprint.label) ? blueprint.name : blueprint.label,
            schemaSlice,
            constraints,
            blueprints
        );
        Result result = new Result();
        result.plan = plan;
        result.artifacts = CodeGenService.generate(plan.actions);
        return result;
    }

    // New: Execute directly from a provided blueprint (e.g., top recommendation)
    public static Result executeFromBlueprint(PlanModels.ActionBlueprint blueprint, Map<String, Object> schemaSlice, Map<String, Object> constraints) {
        if (blueprint == null) {
            throw new AuraHandledException('Blueprint cannot be null');
        }
        List<PlanModels.ActionBlueprint> blueprints = new List<PlanModels.ActionBlueprint>{ blueprint };
        String goal = String.isBlank(blueprint.label) ? blueprint.name : blueprint.label;
        PlanModels.Plan plan = DynamicActionPlanner.buildPlan(goal, schemaSlice, constraints, blueprints);
        Result result = new Result();
        result.plan = plan;
        result.artifacts = CodeGenService.generate(plan.actions);
        return result;
    }

}
