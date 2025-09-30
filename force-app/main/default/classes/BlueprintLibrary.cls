public with sharing class BlueprintLibrary {
    public static PlanModels.ActionBlueprint getByName(String name) {
        PlanModels.ActionBlueprint bp = BlueprintLibraryService.getBlueprint(name);
        if (bp == null) {
            throw new AuraHandledException('Unknown blueprint: ' + name);
        }
        return bp;
    }

    public static List<BlueprintLibraryData.LibraryEntry> listEntries() {
        return BlueprintLibraryService.allEntries();
    }
}
