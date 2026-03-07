#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..', '..');
const docPath = path.join(repoRoot, 'contracts', 'legacy', 'error-code-mapping-v1.md');
const bffSrcPath = path.join(repoRoot, 'apps', 'bff_hdd', 'src');
const flutterLibPath = path.join(repoRoot, 'apps', 'mobile_flutter', 'lib');
const uatSmokeScriptPath = path.join(repoRoot, 'scripts', 'run-wave2-uat-smoke.ps1');

function readText(filePath) {
  return fs.readFileSync(filePath, 'utf8');
}

function collectFiles(root, extensions) {
  const results = [];
  const stack = [root];

  while (stack.length > 0) {
    const current = stack.pop();
    const stat = fs.statSync(current);
    if (stat.isDirectory()) {
      for (const entry of fs.readdirSync(current)) {
        stack.push(path.join(current, entry));
      }
      continue;
    }

    if (extensions.some((ext) => current.endsWith(ext))) {
      results.push(current);
    }
  }
  return results;
}

function collectCombinedText(root, extensions) {
  return collectFiles(root, extensions)
    .map((filePath) => readText(filePath))
    .join('\n');
}

function extractCodes(markdown) {
  const matches = markdown.match(/`(LEGACY_[A-Z_]+|BRIDGE_[A-Z_]+|UAT_DATA_BLOCKED)`/g) ?? [];
  return [...new Set(matches.map((value) => value.replace(/`/g, '')))];
}

function main() {
  const docText = readText(docPath);
  const codes = extractCodes(docText);

  const bffText = collectCombinedText(bffSrcPath, ['.ts']);
  const flutterText = collectCombinedText(flutterLibPath, ['.dart']);
  const uatSmokeText = readText(uatSmokeScriptPath);

  const failures = [];
  for (const code of codes) {
    if (code.startsWith('LEGACY_') && !bffText.includes(code)) {
      failures.push(`${code} missing in apps/bff_hdd/src`);
    } else if (code.startsWith('BRIDGE_') && !flutterText.includes(code)) {
      failures.push(`${code} missing in apps/mobile_flutter/lib`);
    } else if (code === 'UAT_DATA_BLOCKED' && !uatSmokeText.includes(code)) {
      failures.push(`${code} missing in scripts/run-wave2-uat-smoke.ps1`);
    }
  }

  if (failures.length > 0) {
    console.error('Error code mapping check failed:');
    for (const failure of failures) {
      console.error(`- ${failure}`);
    }
    process.exit(1);
  }

  console.log(
    `Error code mapping check passed (${codes.length} documented codes verified against source).`
  );
}

main();
