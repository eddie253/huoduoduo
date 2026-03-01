const fs = require('fs');
const path = require('path');

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function copyIfExists(src, dest) {
  if (!src || !fs.existsSync(src)) {
    return false;
  }
  ensureDir(path.dirname(dest));
  fs.copyFileSync(src, dest);
  return true;
}

function copyDirIfExists(src, dest) {
  if (!src || !fs.existsSync(src)) {
    return false;
  }

  const stat = fs.statSync(src);
  if (!stat.isDirectory()) {
    return false;
  }

  ensureDir(dest);
  for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
    const from = path.join(src, entry.name);
    const to = path.join(dest, entry.name);
    if (entry.isDirectory()) {
      copyDirIfExists(from, to);
    } else {
      ensureDir(path.dirname(to));
      fs.copyFileSync(from, to);
    }
  }
  return true;
}

function argValue(name) {
  const token = `--${name}`;
  const idx = process.argv.indexOf(token);
  if (idx === -1) return null;
  return process.argv[idx + 1] || null;
}

function parseMobileLcov(lcovPath) {
  if (!fs.existsSync(lcovPath)) {
    return null;
  }

  const raw = fs.readFileSync(lcovPath, 'utf8');
  let total = 0;
  let hit = 0;

  for (const line of raw.split(/\r?\n/)) {
    if (!line.startsWith('DA:')) continue;
    const payload = line.slice(3).split(',');
    if (payload.length < 2) continue;
    const hits = Number(payload[1]);
    if (!Number.isFinite(hits)) continue;
    total += 1;
    if (hits > 0) hit += 1;
  }

  return {
    total,
    hit,
    pct: total === 0 ? 0 : (hit / total) * 100,
  };
}

function readBffSummary(summaryPath) {
  if (!fs.existsSync(summaryPath)) {
    return null;
  }

  const json = JSON.parse(fs.readFileSync(summaryPath, 'utf8'));
  return json.total || null;
}

function formatTaipeiTime(date = new Date()) {
  const base = new Intl.DateTimeFormat('sv-SE', {
    timeZone: 'Asia/Taipei',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false,
  }).format(date);
  return `${base} (Asia/Taipei, UTC+8)`;
}

const component = (argValue('component') || 'summary').toLowerCase();
const repoRoot = path.resolve(__dirname, '..', '..');
const reportRoot = path.join(repoRoot, 'reports', 'coverage');

const sourceBffDir = path.join(repoRoot, 'apps', 'bff_gateway', 'coverage');
const sourceMobileDir = path.join(repoRoot, 'apps', 'mobile_flutter', 'coverage');

const reportBffDir = path.join(reportRoot, 'bff');
const reportMobileDir = path.join(reportRoot, 'mobile');

ensureDir(reportRoot);

let copiedBff = false;
let copiedMobile = false;

if (component === 'bff' || component === 'all') {
  copiedBff = copyIfExists(
    path.join(sourceBffDir, 'lcov.info'),
    path.join(reportBffDir, 'lcov.info')
  );
  copiedBff =
    copyIfExists(
      path.join(sourceBffDir, 'coverage-summary.json'),
      path.join(reportBffDir, 'coverage-summary.json')
    ) || copiedBff;
  copyDirIfExists(
    path.join(sourceBffDir, 'lcov-report'),
    path.join(reportBffDir, 'lcov-report')
  );

  if (!copiedBff) {
    console.error('No BFF coverage artifacts found to collect.');
    process.exit(1);
  }
}

if (component === 'mobile' || component === 'all') {
  copiedMobile = copyIfExists(
    path.join(sourceMobileDir, 'lcov.info'),
    path.join(reportMobileDir, 'lcov.info')
  );

  if (!copiedMobile) {
    console.error('No mobile coverage artifacts found to collect.');
    process.exit(1);
  }
}

const bffSummaryPath = path.join(reportBffDir, 'coverage-summary.json');
const mobileLcovPath = path.join(reportMobileDir, 'lcov.info');

const bffSummary = readBffSummary(bffSummaryPath);
const mobileSummary = parseMobileLcov(mobileLcovPath);

const lines = [
  '# Coverage Summary',
  '',
  `Generated at: ${formatTaipeiTime()}`,
  '',
  '## BFF (Jest v8)',
];

if (bffSummary) {
  lines.push(
    `- lines: ${bffSummary.lines?.pct ?? 'n/a'}% (${bffSummary.lines?.covered ?? 'n/a'}/${bffSummary.lines?.total ?? 'n/a'})`,
    `- statements: ${bffSummary.statements?.pct ?? 'n/a'}% (${bffSummary.statements?.covered ?? 'n/a'}/${bffSummary.statements?.total ?? 'n/a'})`,
    `- functions: ${bffSummary.functions?.pct ?? 'n/a'}% (${bffSummary.functions?.covered ?? 'n/a'}/${bffSummary.functions?.total ?? 'n/a'})`,
    `- branches: ${bffSummary.branches?.pct ?? 'n/a'}% (${bffSummary.branches?.covered ?? 'n/a'}/${bffSummary.branches?.total ?? 'n/a'})`
  );
} else {
  lines.push('- No BFF coverage summary found.');
}

lines.push('', '## Mobile Flutter (LCOV line coverage)');

if (mobileSummary) {
  lines.push(
    `- lines: ${mobileSummary.pct.toFixed(2)}% (${mobileSummary.hit}/${mobileSummary.total})`
  );
} else {
  lines.push('- No mobile coverage summary found.');
}

lines.push('');

fs.writeFileSync(path.join(reportRoot, 'summary.md'), `${lines.join('\n')}\n`, 'utf8');

if (component === 'summary') {
  if (!bffSummary && !mobileSummary) {
    console.error('No coverage artifacts available for summary generation.');
    process.exit(1);
  }
}

console.log('Coverage artifacts collected at reports/coverage');
