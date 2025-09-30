# Evaluation Workflow

Use the evaluation harness to benchmark dynamic action generation over time.

## Components

- **GenerationBenchmark.cls** – Apex utility that compares generated outputs against golden expectations.
- **GenerationBenchmark_Test.cls** – Unit tests that ensure the harness executes.
- **evaluations/golden/** – Human-readable copies of golden blueprints and expected code fragments.

## Running Manually

1. Deploy the project to an org.
2. Execute:
   ```apex
   System.debug(GenerationBenchmark.summarize());
   ```
3. Inspect the debug log for per-scenario pass/fail indicators and notes on mismatches.

## CI Integration

- Call `GenerationBenchmark.run()` inside a scheduled Apex job or test context to collect structured results.
- Fail the build if any `CaseResult` reports `false` for blueprint, class, or test assertions.
- Optionally extend `CaseResult` with additional metadata (e.g., response latency) for richer dashboards.

## Adding Scenarios

1. Add a new case to `GenerationBenchmark.goldenCases()` with a golden blueprint JSON string.
2. Drop supporting reference files into `evaluations/golden/` for documentation.
3. Update `evaluations/README.md` to describe the new scenario.
4. Run `sfdx force:apex:test:run` to ensure the benchmark tests pass.

Consistently running the harness helps surface regressions between heuristic and LLM outputs and documents expected behavior for critical business goals.
