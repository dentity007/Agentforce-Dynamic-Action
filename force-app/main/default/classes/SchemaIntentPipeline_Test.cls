@IsTest
private class SchemaIntentPipeline_Test {
    @IsTest
    static void pipelineProducesRecommendationsAndArtifacts() {
        SchemaIntentPipeline.Options options = new SchemaIntentPipeline.Options();
        options.schemaOptions.maxObjects = 3;
        options.schemaOptions.maxFieldsPerObject = 5;

        PlanModels.PipelineResult result = SchemaIntentPipeline.run('Update opportunity stage to Closed Won', options);

        System.assertNotEquals(null, result.schema, 'Schema snapshot should be returned.');
        System.assert(result.schema.containsKey('objects'), 'Schema snapshot should include objects data.');
        System.assert(result.recommendations != null && !result.recommendations.isEmpty(), 'Recommendations should be present.');
        System.assertNotEquals(null, result.plan, 'Plan should be created.');
        System.assert(result.plan.actions.size() == result.artifacts.apex.size(), 'Each action should yield an Apex artifact.');
    }

    @IsTest
    static void recommendationScoresAreRanked() {
        SchemaIntentPipeline.Options options = new SchemaIntentPipeline.Options();
        PlanModels.PipelineResult result = SchemaIntentPipeline.run('Qualify a lead and set status', options);
        System.assert(result.recommendations.size() > 0, 'Recommendations required for ranking test');
        Decimal topScore = result.recommendations[0].score;
        for (PlanModels.Recommendation rec : result.recommendations) {
            System.assert(topScore >= rec.score, 'Recommendations should be sorted by score descending');
        }
    }
}
