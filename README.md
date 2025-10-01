# Agentforce Dynamic Action

Agentforce Dynamic Action turns Salesforce org metadata and a natural language goal into executable actions. It extends the prior *Data-Aware Agent* prototype by wiring a three-phase loop:

1. **Blueprint** – Gather schema, gather intent, ask an LLM (or local heuristic) to emit structured `ActionBlueprint` JSON.
2. **Synthesize** – Convert the blueprint into Apex classes, guardrails, and unit tests by rendering code templates.
3. **Orchestrate** – Register and execute the generated actions through a runtime dispatcher with FLS/sharing validation.

The repository is ready to run with a stubbed LLM client so you can experiment offline, but it is structured to drop in a production LLM provider without touching core logic.

---

## Repository Tour

| Path | Purpose |
|------|---------|
| `force-app/main/default/classes/` | Apex sources for blueprint generation, template rendering, orchestration, and tests. |
| `force-app/main/default/staticresources/` | Curated blueprint library (zip) |
| `blueprints/` | Raw JSON blueprints (dev-time) |
| `docs/` | Architecture notes, blueprint schema contract, guardrail catalogue, and integration guides. |
| `scripts/` | CLI helper files (bash, apex, node) |
| `config/` | Scratch org def if you don't already have it |
| `.github/workflows/` | CI |
| `sfdx-project.json` | Salesforce DX project descriptor. |

Key Apex entry points:
- `DynamicActionPipeline` – End-to-end driver that returns both the plan and generated code artifacts.
- `BlueprintSynthesisService` – Handles prompt orchestration and response parsing.
- `CodeTemplateEngine` – Renders Apex/test classes with runtime guardrails baked in.
- `DynamicActionOrchestrator` – Executes generated actions with safety checks.

---

## Quick Start

### One-command setup
```bash
./scripts/init.sh
```
This script spins up a scratch org, deploys source, assigns the runtime permset, generates the sample action, deploys the artifacts, and runs tests.
Requires Node.js 18+, the Salesforce `sf` CLI, and a configured Dev Hub (`SFDX_AUTH_URL`).

### If you don't use bash
1. **Clone & Authorize**
   ```bash
   git clone <repo>
   cd Agentforce-Dynamic-Action
   node scripts/build-blueprint-library.js
   sf org create scratch -f config/project-scratch-def.json -a dynamicAction -s
   sf project deploy start -o dynamicAction
   ```
2. **Assign runtime permissions**
   ```bash
   sf org assign permset -n DynamicAction_Permissions -o dynamicAction
   ```
3. **(Optional) Register an LLM client**
   Edit `scripts/register-llm.apex` and run `sf apex run -o dynamicAction -f scripts/register-llm.apex`. Until then the stub heuristics will map common goals to example blueprints.
4. **Generate code artifacts**
   ```bash
   mkdir -p .tmp
   sf apex run -o dynamicAction -f scripts/generate.apex --json > .tmp/generate.json
   node scripts/deploy-artifacts.js .tmp/generate.json dynamicAction
   ```
5. **Run tests**
   ```bash
   sf apex run test -o dynamicAction -l RunLocalTests -r human
   ```

---
## End-to-End Pipeline

Use `SchemaIntentPipeline` to execute the full schema → recommendation → implementation flow in one call.

```apex
SchemaIntentPipeline.Options options = new SchemaIntentPipeline.Options();
options.schemaOptions.maxObjects = 5;
options.schemaOptions.maxFieldsPerObject = 10;

PlanModels.PipelineResult pipeline = SchemaIntentPipeline.run(
    'Recommend follow-up actions for high value opportunities',
    options
);
System.debug(pipeline.schema);
System.debug(pipeline.recommendations);
System.debug(pipeline.artifacts);
```

- `pipeline.schema` contains a trimmed org snapshot (objects, fields, relationships).
- `pipeline.recommendations` lists ranked action blueprints with rationale and scores.
- `pipeline.plan` mirrors the orchestrator plan used for execution.
- `pipeline.artifacts` delivers generated Apex classes, tests, and metadata.

Tie the result into `DynamicActionOrchestrator.run` once users confirm the checkpoint displayed in the plan.

### One-command E2E (recommend → synthesize → deploy → test)

Run the full loop with a single script. It will: recommend candidates, synthesize from the top result, deploy artifacts, and run tests.

```bash
./scripts/e2e.sh dynamicAction
```

## Recommend → Generate

Use the Step-2 recommendation API to get ranked blueprints, then feed the top result into Step-3 code generation.

**Step 2: Get Recommendations**
```apex
String narrative = 'For AAA insurance sales, when a deal is approved, set the opportunity to Closed Won.';
List<String> includeObjects = new List<String>{'Opportunity','Lead','Case'};
RecommendFunctionalities.Response r = RecommendFunctionalities.run(narrative, includeObjects, 3);
System.debug(JSON.serializePretty(r));
```

Sample narratives for quick testing (use `scripts/recommend.apex`):
- Case escalation: For P1 customer issues, escalate the case to Tier 2 and set priority to High.
- Lead qualification: When an SDR qualifies interest, move the lead to Qualified and set rating to Hot.
- Opportunity closed-lost: If negotiations fail, mark the opportunity Closed Lost and capture a short loss reason.
- Case follow-up task: After resolving the issue, create a follow-up task on the case for a satisfaction call.

If you already have an external schema snapshot (from a Data‑Aware agent), use `SchemaIntentPipeline.run(goal, externalSchema, options)` to blend recommendations and synthesis in one call (see End-to-End Pipeline above).

**Step 3: Generate from Top Recommendation**
```apex
// Re-run recommendation for simplicity (or load from Step 2 results)
String narrative = 'For AAA insurance sales, when a deal is approved, set the opportunity to Closed Won.';
List<String> includeObjects = new List<String>{'Opportunity'};
RecommendFunctionalities.Response r = RecommendFunctionalities.run(narrative, includeObjects, 1);

PlanModels.ActionBlueprint bp = r.recommendations.isEmpty() ? null : r.recommendations[0].blueprint;
DynamicActionPipeline.Result result = DynamicActionPipeline.executeFromBlueprint(
    bp,
    null, // optional schema slice
    null  // optional constraints
);
System.debug(JSON.serialize(result));
```

## Input Options

| Mode | How to run | Notes |
|------|-------------|-------|
| Goal text only | `SchemaIntentPipeline.run(goal, options)` with heuristics | Works offline using curated heuristics and guardrails. |
| Goal text + LLM | Register a client via `scripts/register-llm.apex`, then call `SchemaIntentPipeline.run(goal, options)` | Prompts include schema slice + goal; enable telemetry to capture prompts. |
| Curated blueprint JSON | `DynamicActionPipeline.executeWithBlueprint('oppty_closed_won', null, null)` or `BlueprintLibrary.getByName(...)` | Bypasses LLM and uses the curated catalog in `/blueprints`. |

### Schema Snapshot Format

If providing external schema snapshots (instead of letting `SchemaSnapshot.buildSnapshot()` gather them), use this JSON structure:

```json
{
  "objects": {
    "Opportunity": {
      "apiName": "Opportunity",
      "fields": {
        "Id": {"apiName": "Id", "type": "Id", "nillable": false, "createable": false, "updateable": false},
        "StageName": {"apiName": "StageName", "type": "Picklist", "nillable": false, "createable": true, "updateable": true, "picklistValues": ["Prospecting", "Closed Won"]},
        "CloseDate": {"apiName": "CloseDate", "type": "Date", "nillable": true, "createable": true, "updateable": true}
      },
      "childRelationships": ["OpportunityLineItems.OpportunityId"]
    }
  }
}
```

Each object includes actionable fields (createable/updateable) with their metadata and picklist values where applicable.

Recommendation ranking blends curated exemplars (from `/blueprints`, built into the `BlueprintLibrary` static resource) with LLM/heuristic suggestions. Tags in curated entries (e.g., object names, verbs like Update/Convert, guardrail hints) are used to score proximity to the narrative and schema.

Curated blueprint keys available out of the box:
- `opportunity_closed_won`
- `oppty_closed_won`
- `lead_qualify`
- `case_escalate`
- `case_escalate_tier2`
- `lead_mark_qualified`
- `opportunity_close_lost`
- `case_create_followup_task`

## Result Shape Example

```jsonc
{
  "plan": {
    "goal": "Update opportunity stage to Closed Won",
    "actions": [
      { "name": "UpdateOpportunityStage", "targetSObject": "Opportunity" }
    ]
  },
  "artifacts": {
    "force-app/main/default/classes/DynamicAction_UpdateOpportunityStage.cls": "// ... Apex implementation ...",
    "force-app/main/default/classes/DynamicAction_UpdateOpportunityStage.cls-meta.xml": "<?xml version=\\"1.0\\" ...>"
  }
}
```

## Blueprint Contract

Generated actions follow the `PlanModels.ActionBlueprint` schema defined in `docs/blueprint-contract.md`. Each blueprint lists:
- `inputs` (payload → SObject field bindings, types, required flags)
- `guardrails` (FLS, numeric ranges, enum constraints, sharing)
- `operation` + `targetSObject`
- `checkpoint` text for user confirmation

Blueprints may come from:
- The stub heuristics (`HeuristicBlueprintFactory`)
- A live LLM call via `LLMClientGateway`
- A stored library of curated JSON blueprints

---

## Guardrails & Safety

`GuardrailEvaluator` centralizes validation of generated actions. Review `docs/guardrails.md` for the supported rule set (FLS, sharing, numeric checks, enums) and extension points for privacy or policy enforcement. The template engine automatically injects guardrail hooks into every generated Apex class.

---

## Extending the Pipeline

- **Template Tokens** – Extend `CodeTemplateEngine` to add Flow or SOQL emitters and bundle them in `CodeGenService`.
- **Telemetry** – Capture prompt/response pairs through a custom `LLMClient` implementation and store in an analytics object.
- **Domain Libraries** – Replace or augment the heuristics with curated blueprint libraries for your vertical (`/blueprints`).
- **Deployment Automation** – Add CI tasks that persist generated artifacts directly into the repo or packaging pipelines.

See `docs/llm-integration.md`, `docs/code-synthesis.md`, and `docs/runtime.md` for hands-on guides.

---

## Evaluation & Regression Tracking

- Run `GenerationBenchmark.summarize()` to compare current generation output with golden blueprints.
- Review `docs/evaluation.md` and `tests/generation/README.md` for adding scenarios and wiring the benchmark into CI.
- Golden reference assets live under `tests/generation/golden/` so the expected behavior stays visible in code review.

## Troubleshooting

### Common First-Run Issues
- **FLS/Sharing Errors**: Generated actions include guardrails but may fail if your user lacks FLS on target fields. Assign `DynamicAction_Permissions` or ensure your profile has read/write access to Opportunity/Case fields.
- **Missing Objects**: If Opportunity or Case objects aren't available, use `config/project-scratch-def.json` which enables Sales Cloud features, or modify `includeObjects` in recommendation calls to use available objects.
- **LLM Callouts Blocked**: Configure the `LLM_Provider` Named Credential with valid endpoint/credentials, then run `scripts/register-llm.apex` to register your client.
- **Deployment writes no files**: Ensure `scripts/generate.apex` completed successfully and that Node.js is installed for `scripts/deploy-artifacts.js`.
- **Permission errors**: Run `sf org assign permset -n DynamicAction_Permissions -o <alias>` after deploying metadata.
- **Scripts not executable**: Run `chmod +x scripts/*.sh` on Unix systems if scripts fail with "permission denied".

### Debug Steps
1. Check scratch org features: `sf org display -o <alias>` should show Sales Cloud enabled
2. Verify permissions: `sf org assign permset -n DynamicAction_Permissions -o <alias>`

---
**Continuous Integration**
- `e2e.yml` runs the full recommend → synthesize → deploy → test loop on PRs from this repo and pushes to `main`.
- Secrets required (choose one auth method):
  - SFDX URL: add `SFDX_AUTH_URL` under GitHub → Settings → Secrets → Actions.
    - Locally, retrieve with: `sf org display --verbose -o <DevHubAlias>` and copy “Sfdx Auth Url”.
  - JWT: add `SF_CONSUMER_KEY`, `SF_JWT_KEY` (private key PEM), `SF_USERNAME` (Dev Hub username).
- The workflow never exposes secrets to forked PRs; it runs on repo PRs, pushes to `main`, and `workflow_dispatch`.

CLI helper for Step‑2
- Run a single scenario: `node scripts/recommend-cli.js --org <alias> --scenario 2`
- Run all scenarios: `node scripts/recommend-cli.js --org <alias> --all`
3. Test basic generation: `sf apex run -f scripts/generate.apex -o <alias>`
4. Check logs: Add `System.debug()` statements and monitor with `sf apex tail log -o <alias>`

## Contributing

1. Fork and create a feature branch.
2. Write Apex tests for new functionality and execute them in a scratch org.
3. Run linting/formatting as needed (Apex code style matches Salesforce defaults).
4. Open a pull request referencing the Jira or work item.

Issues and feature ideas are tracked in `docs/roadmap.md`. Feel free to suggest enhancements there before submitting a PR.

---

## License

Released under the [MIT License](LICENSE).
