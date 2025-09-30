#!/usr/bin/env bash
# Run the generation benchmark and emit a summary suitable for CI.
set -euo pipefail

APEX_SNIPPET='System.debug(GenerationBenchmark.summarize());'

echo "Running GenerationBenchmark..." >&2
sfdx force:apex:execute --apexcode "$APEX_SNIPPET"
