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
| `docs/` | Architecture notes, blueprint schema contract, guardrail catalogue, and integration guides. |
| `sfdx-project.json` | Salesforce DX project descriptor. |

Key Apex entry points:
- `DynamicActionPipeline` – End-to-end driver that returns both the plan and generated code artifacts.
- `BlueprintSynthesisService` – Handles prompt orchestration and response parsing.
- `CodeTemplateEngine` – Renders Apex/test classes with runtime guardrails baked in.
- `DynamicActionOrchestrator` – Executes generated actions with safety checks.

---

## Quick Start

1. **Clone & Authorize**
   ```bash
   git clone <repo>
   cd Agentforce-Dynamic-Action
   sfdx force:org:create -f config/project-scratch-def.json -a dynamicAction -s
   sfdx force:source:push
   ```

2. **(Optional) Register an LLM client**
   Implement `LLMClientGateway.LLMClient` in your org and call `LLMClientGateway.register(new YourClient())` from a setup script. Until then the stub heuristics will map common goals to example blueprints.

3. **Generate code**
   Execute from the Developer Console or anonymous Apex:
   ```apex
   DynamicActionPipeline.Result result = DynamicActionPipeline.execute(
       'Update an opportunity to Closed Won',
       null,
       null
   );
   System.debug(result.plan);
   System.debug(result.artifacts);
   ```

4. **Deploy artifacts**
   Persist the generated Apex/test maps to metadata files or push through the Metadata API. A helper deployment script (`scripts/deploy_artifacts.py`) is outlined in `docs/deployment.md`.

5. **Run tests**
   ```bash
   sfdx force:apex:test:run -l RunLocalTests -r human
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

## Contributing

1. Fork and create a feature branch.
2. Write Apex tests for new functionality and execute them in a scratch org.
3. Run linting/formatting as needed (Apex code style matches Salesforce defaults).
4. Open a pull request referencing the Jira or work item.

Issues and feature ideas are tracked in `docs/roadmap.md`. Feel free to suggest enhancements there before submitting a PR.

---

## License

Released under the [MIT License](LICENSE).
