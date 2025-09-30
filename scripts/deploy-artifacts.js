#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const cp = require('child_process');

if (process.argv.length < 4) {
  console.error('Usage: scripts/deploy-artifacts.js <generate-json> <org-alias>');
  process.exit(1);
}

const [, , jsonPath, alias] = process.argv;
const raw = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));

function extractArtifactPayload(payload) {
  const candidates = [];
  if (payload.artifacts) {
    candidates.push(payload.artifacts);
  }
  if (payload.result && payload.result.artifacts) {
    candidates.push(payload.result.artifacts);
  }
  const logs = payload.result && payload.result.logs ? payload.result.logs : [];
  for (const log of logs) {
    const msg = log.message || log;
    if (!msg) continue;
    const brace = msg.indexOf('{');
    if (brace >= 0) {
      const snippet = msg.slice(brace);
      try {
        const parsed = JSON.parse(snippet);
        if (parsed.artifacts) {
          candidates.push(parsed.artifacts);
        }
      } catch (err) {
        // ignore parse errors
      }
    }
  }
  if (candidates.length === 0) {
    throw new Error('No artifact map found in generate output.');
  }
  return candidates[candidates.length - 1];
}

const artifacts = extractArtifactPayload(raw);
const outDir = path.resolve('.tmp', 'generated');
fs.rmSync(outDir, { recursive: true, force: true });

Object.entries(artifacts).forEach(([relPath, content]) => {
  const target = path.join(outDir, relPath);
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.writeFileSync(target, content);
});

cp.execSync(`sf project deploy start -o ${alias} -p ${outDir}`, { stdio: 'inherit' });
