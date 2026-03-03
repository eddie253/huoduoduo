const fs = require('fs');
const path = require('path');

function parseLineCoverage(lcovRaw) {
  let total = 0;
  let hit = 0;
  let includeCurrentFile = false;

  for (const line of lcovRaw.split(/\r?\n/)) {
    if (line.startsWith('SF:')) {
      const sourceFile = line.slice(3).replace(/\\/g, '/');
      includeCurrentFile =
        !sourceFile.endsWith('_test.dart') &&
        !sourceFile.includes('/test_helpers/');
      continue;
    }

    if (line === 'end_of_record') {
      includeCurrentFile = false;
      continue;
    }

    if (!includeCurrentFile) continue;
    if (!line.startsWith('DA:')) continue;
    const payload = line.slice(3).split(',');
    if (payload.length < 2) continue;
    const hits = Number(payload[1]);
    if (!Number.isFinite(hits)) continue;
    total += 1;
    if (hits > 0) {
      hit += 1;
    }
  }

  return {
    total,
    hit,
    percent: total === 0 ? 0 : (hit / total) * 100,
  };
}

const targetPath = process.argv[2] || 'apps/mobile_flutter/coverage/lcov.info';
const thresholdRaw = process.argv[3] || process.env.FLUTTER_COVERAGE_MIN_LINES || '80';
const threshold = Number(thresholdRaw);

if (!Number.isFinite(threshold) || threshold < 0 || threshold > 100) {
  console.error(`Invalid coverage threshold: ${thresholdRaw}`);
  process.exit(2);
}

const repoRoot = path.resolve(__dirname, '..', '..');
const lcovPath = path.resolve(repoRoot, targetPath);

if (!fs.existsSync(lcovPath)) {
  console.error(`LCOV file not found: ${lcovPath}`);
  process.exit(2);
}

const lcovRaw = fs.readFileSync(lcovPath, 'utf8');
const coverage = parseLineCoverage(lcovRaw);

console.log(
  `Flutter line coverage: ${coverage.percent.toFixed(2)}% (${coverage.hit}/${coverage.total}), threshold: ${threshold}%`
);

if (coverage.percent < threshold) {
  process.exit(1);
}
