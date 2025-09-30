public with sharing class DynamicActionPlanner {
    public static PlanModels.Plan buildPlan(String goal, Map<String, Object> schemaSlice, Map<String, Object> constraints) {
        PlanModels.Plan plan = new PlanModels.Plan();
        plan.goal = goal;
        plan.actions = BlueprintSynthesisService.buildBlueprints(goal, schemaSlice, constraints);
        plan.dependencies.add('FLS');
        plan.dependencies.add('Sharing');
        plan.guardrails.add('LLM generated blueprint validated via runtime guardrails');
        plan.checkpoint = deriveCheckpoint(plan.actions);
        return plan;
    }

    private static String deriveCheckpoint(List<PlanModels.ActionBlueprint> actions) {
        if (actions == null || actions.isEmpty()) {
            return 'No actions generated.';
        }
        for (PlanModels.ActionBlueprint bp : actions) {
            if (bp != null && !String.isBlank(bp.checkpoint)) {
                return bp.checkpoint;
            }
        }
        PlanModels.ActionBlueprint first = actions[0];
        return 'Ready to execute action ' + first.name + '. Proceed?';
    }
}
