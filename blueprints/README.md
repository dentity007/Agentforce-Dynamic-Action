# Blueprint Library

Curated blueprints that serve as exemplars for different verticals and guardrail presets. Each file is referenced by `BlueprintLibraryService` and can seed prompts or be executed directly.

| File | Tags | Description |
|------|------|-------------|
| `oppty_closed_won.json` | `sales`, `opportunity`, `closedwon` | Update Opportunity stage with guardrails. |
| `lead_qualify.json` | `sales`, `lead`, `qualification` | Qualify a lead and set status/rating safely. |
| `case_escalate.json` | `service`, `case`, `escalation` | Escalate a case with priority and PII safeguards. |
| `case_escalate_tier2.json` | `case`, `escalate`, `ownership`, `priority`, `queue` | Reassign to Tier 2 and set priority/status. |
| `lead_mark_qualified.json` | `lead`, `qualification`, `rating` | Move lead to Qualified and set rating. |
| `opportunity_close_lost.json` | `opportunity`, `stage`, `closedlost`, `reason` | Set Closed Lost and capture reason text. |
| `case_create_followup_task.json` | `case`, `task`, `create`, `followup` | Create a follow-up Task linked to Case. |

Run `node scripts/build-blueprint-library.js` (or `npm run blueprints:build`) after editing these JSON files to refresh the `BlueprintLibrary` static resource.
