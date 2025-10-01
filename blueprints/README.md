# Blueprint Library

Curated blueprints that serve as exemplars for different verticals and guardrail presets. Each file is referenced by `BlueprintLibraryService` and can seed prompts or be executed directly.

| File | Tags | Description |
|------|------|-------------|
| `oppty_closed_won.json` | `sales`, `opportunity`, `closedwon` | Update Opportunity stage with guardrails. |
| `lead_qualify.json` | `sales`, `lead`, `qualification` | Qualify a lead and set status/rating safely. |
| `case_escalate.json` | `service`, `case`, `escalation` | Escalate a case with priority and PII safeguards. |

Run `node scripts/build-blueprint-library.js` after editing these JSON files to refresh the `BlueprintLibrary` static resource.
