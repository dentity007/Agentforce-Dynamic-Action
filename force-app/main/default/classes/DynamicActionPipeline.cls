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
}
