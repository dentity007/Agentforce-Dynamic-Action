@IsTest
private class BlueprintLibraryService_Test {
    @IsTest
    static void findMatchesReturnsCuratedBlueprints() {
        Map<String, Object> schema = new Map<String, Object>();
        schema.put('objects', new List<Object>{
            new Map<String, Object>{
                'apiName' => 'Opportunity',
                'fields' => new List<Object>{
                    new Map<String, Object>{'apiName' => 'StageName'},
                    new Map<String, Object>{'apiName' => 'CloseDate'}
                }
            }
        });
        List<BlueprintLibraryService.MatchResult> matches = BlueprintLibraryService.findMatches('Update opportunity stage quickly', schema, 3);
        System.assert(matches.size() > 0, 'Expected curated matches for opportunity update.');
        System.assertEquals('UpdateOpportunityStage', matches[0].entry.name);
        System.assert(matches[0].score > 0, 'Curated match should have positive score.');
    }
}
