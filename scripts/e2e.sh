#!/usr/bin/env bash
set -euo pipefail
ORG_ALIAS="${1:-dynamicAction}"

# 0) Scratch org + push core
sf org create scratch -f config/project-scratch-def.json -a "$ORG_ALIAS" -s
sf project deploy start -o "$ORG_ALIAS"

# 1) Upload blueprint library as a static resource (single JSON array)
sf data upsert bulk -o "$ORG_ALIAS" -s StaticResource -f scripts/BlueprintLibrary.csv -i Name || true

# 2) Recommend (captures JSON to .tmp)
mkdir -p .tmp
sf apex run -o "$ORG_ALIAS" -f scripts/recommend.apex --json > .tmp/recommend.json

# 3) Generate from top recommendation
sf apex run -o "$ORG_ALIAS" -f scripts/generate_from_top.apex --json > .tmp/generate.json

# 4) Convert & deploy generated artifacts
node scripts/deploy-artifacts.js .tmp/generate.json "$ORG_ALIAS"

# 5) Run tests
sf apex run test -o "$ORG_ALIAS" -l RunLocalTests -r human