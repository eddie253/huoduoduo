const fs = require('fs');
const path = require('path');

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function pct(value) {
  return Number.isFinite(value) ? value.toFixed(2) : 'n/a';
}

function metricClass(value) {
  if (!Number.isFinite(value)) return 'na';
  if (value >= 80) return 'good';
  if (value >= 60) return 'warn';
  return 'bad';
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

function parseLcovByFile(lcovRaw) {
  const files = [];
  let current = null;

  for (const raw of lcovRaw.split(/\r?\n/)) {
    const line = raw.trim();
    if (line.startsWith('SF:')) {
      const sourceFile = line.slice(3).replace(/\\/g, '/');
      if (sourceFile.endsWith('_test.dart')) {
        current = null;
        continue;
      }
      current = {
        file: sourceFile,
        total: 0,
        hit: 0,
      };
      files.push(current);
      continue;
    }

    if (!current) continue;

    if (line.startsWith('DA:')) {
      const payload = line.slice(3).split(',');
      if (payload.length < 2) continue;
      const hits = Number(payload[1]);
      if (!Number.isFinite(hits)) continue;
      current.total += 1;
      if (hits > 0) current.hit += 1;
      continue;
    }

    if (line === 'end_of_record') {
      current = null;
    }
  }

  return files
    .map((f) => ({
      file: f.file,
      linesTotal: f.total,
      linesHit: f.hit,
      linesPct: f.total === 0 ? 0 : (f.hit / f.total) * 100,
    }))
    .filter((f) => f.linesTotal > 0)
    .sort((a, b) => a.linesPct - b.linesPct);
}

function parseBffSummary(summaryJson) {
  const rows = [];
  for (const [key, value] of Object.entries(summaryJson)) {
    if (key === 'total') continue;
    rows.push({
      file: key,
      linesPct: value?.lines?.pct ?? NaN,
      linesHit: value?.lines?.covered ?? 0,
      linesTotal: value?.lines?.total ?? 0,
    });
  }
  return rows.sort((a, b) => (a.linesPct ?? 0) - (b.linesPct ?? 0));
}

const repoRoot = path.resolve(__dirname, '..', '..');
const reportRoot = path.join(repoRoot, 'reports', 'coverage');
const bffSummaryPath = path.join(reportRoot, 'bff', 'coverage-summary.json');
const mobileLcovPath = path.join(reportRoot, 'mobile', 'lcov.info');
const bffHtmlIndex = path.join(reportRoot, 'bff', 'lcov-report', 'index.html');

if (!fs.existsSync(bffSummaryPath) && !fs.existsSync(mobileLcovPath)) {
  console.error('No coverage inputs found. Run coverage:collect first.');
  process.exit(1);
}

let bffTotal = null;
let bffRows = [];
if (fs.existsSync(bffSummaryPath)) {
  const bffSummary = JSON.parse(fs.readFileSync(bffSummaryPath, 'utf8'));
  bffTotal = bffSummary.total || null;
  bffRows = parseBffSummary(bffSummary);
}

let mobileRows = [];
let mobileTotal = null;
if (fs.existsSync(mobileLcovPath)) {
  const lcov = fs.readFileSync(mobileLcovPath, 'utf8');
  mobileRows = parseLcovByFile(lcov);
  const linesHit = mobileRows.reduce((s, x) => s + x.linesHit, 0);
  const linesTotal = mobileRows.reduce((s, x) => s + x.linesTotal, 0);
  mobileTotal = {
    linesHit,
    linesTotal,
    linesPct: linesTotal === 0 ? 0 : (linesHit / linesTotal) * 100,
  };
}

const bffLink = fs.existsSync(bffHtmlIndex)
  ? './bff/lcov-report/index.html'
  : null;

const html = `<!doctype html>
<html lang="zh-Hant">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Coverage Dashboard</title>
  <style>
    body { font-family: "Segoe UI", Arial, sans-serif; margin: 24px; color: #1f2937; background: #f6f8fb; }
    h1 { margin: 0 0 12px; }
    h2 { margin: 0 0 10px; }
    .muted { color: #64748b; margin-bottom: 20px; }
    .toolbar { display: flex; gap: 10px; flex-wrap: wrap; margin-bottom: 16px; }
    .btn { border: 1px solid #cbd5e1; background: #fff; color: #1e293b; border-radius: 10px; padding: 8px 12px; font-size: 13px; font-weight: 600; cursor: pointer; }
    .btn:hover { background: #f8fafc; }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 14px; margin-bottom: 20px; }
    .card { background: #fff; border: 1px solid #e2e8f0; border-radius: 12px; padding: 14px; box-shadow: 0 2px 8px rgba(15,23,42,0.04); }
    .label { font-size: 13px; color: #64748b; }
    .value { font-size: 28px; font-weight: 700; margin: 6px 0; }
    .pill { display: inline-block; padding: 3px 8px; border-radius: 999px; font-size: 12px; font-weight: 700; }
    .good { background: #dcfce7; color: #166534; }
    .warn { background: #fef3c7; color: #92400e; }
    .bad { background: #fee2e2; color: #991b1b; }
    .na { background: #e2e8f0; color: #334155; }
    .section { margin-bottom: 22px; }
    .section-head { display: flex; align-items: center; justify-content: space-between; gap: 10px; flex-wrap: wrap; margin-bottom: 8px; }
    .section-controls { display: flex; gap: 10px; align-items: center; }
    .section-controls label { font-size: 13px; color: #334155; }
    select { border: 1px solid #cbd5e1; border-radius: 8px; padding: 5px 8px; background: #fff; }
    .count { font-size: 12px; color: #64748b; }
    table { width: 100%; border-collapse: collapse; background: #fff; border: 1px solid #e2e8f0; border-radius: 10px; overflow: hidden; }
    th, td { text-align: left; padding: 10px; border-bottom: 1px solid #eef2f7; font-size: 13px; }
    th { background: #f8fafc; color: #475569; font-weight: 700; }
    td:first-child { max-width: 620px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    a { color: #0f766e; text-decoration: none; }
    @media print {
      .toolbar, .section-controls { display: none !important; }
      body { margin: 10mm; background: #fff; }
      .card, table { box-shadow: none; }
      td:first-child { max-width: none; white-space: normal; }
    }
  </style>
</head>
<body>
  <h1>Coverage Dashboard</h1>
  <div class="muted">Generated at ${formatTaipeiTime()}</div>

  <div class="toolbar">
    <button type="button" class="btn" id="export-pdf">Export PDF</button>
    ${bffLink ? `<a class="btn" href="${bffLink}">Open BFF detailed HTML report</a>` : ''}
  </div>

  <div class="grid">
    <div class="card">
      <div class="label">BFF lines</div>
      <div class="value">${pct(bffTotal?.lines?.pct)}%</div>
      <span class="pill ${metricClass(bffTotal?.lines?.pct)}">${bffTotal ? `${bffTotal.lines.covered}/${bffTotal.lines.total}` : 'n/a'}</span>
    </div>
    <div class="card">
      <div class="label">BFF branches</div>
      <div class="value">${pct(bffTotal?.branches?.pct)}%</div>
      <span class="pill ${metricClass(bffTotal?.branches?.pct)}">${bffTotal ? `${bffTotal.branches.covered}/${bffTotal.branches.total}` : 'n/a'}</span>
    </div>
    <div class="card">
      <div class="label">Flutter lines</div>
      <div class="value">${pct(mobileTotal?.linesPct)}%</div>
      <span class="pill ${metricClass(mobileTotal?.linesPct)}">${mobileTotal ? `${mobileTotal.linesHit}/${mobileTotal.linesTotal}` : 'n/a'}</span>
    </div>
  </div>

  <div class="section">
    <div class="section-head">
      <h2>BFF lowest coverage files</h2>
      <div class="section-controls">
        <label for="bff-mode">Display:</label>
        <select id="bff-mode">
          <option value="20">Top 20</option>
          <option value="all">All</option>
        </select>
        <span id="bff-count" class="count"></span>
      </div>
    </div>
    <table>
      <thead><tr><th>File</th><th>Lines</th><th>Coverage</th></tr></thead>
      <tbody id="bff-body"></tbody>
    </table>
  </div>

  <div class="section">
    <div class="section-head">
      <h2>Flutter lowest coverage files</h2>
      <div class="section-controls">
        <label for="mobile-mode">Display:</label>
        <select id="mobile-mode">
          <option value="20">Top 20</option>
          <option value="all">All</option>
        </select>
        <span id="mobile-count" class="count"></span>
      </div>
    </div>
    <table>
      <thead><tr><th>File</th><th>Lines</th><th>Coverage</th></tr></thead>
      <tbody id="mobile-body"></tbody>
    </table>
  </div>

  <script>
    const bffRows = ${JSON.stringify(bffRows)};
    const mobileRows = ${JSON.stringify(mobileRows)};

    function escapeHtml(str) {
      return String(str)
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
    }

    function metricClassJs(value) {
      if (!Number.isFinite(value)) return 'na';
      if (value >= 80) return 'good';
      if (value >= 60) return 'warn';
      return 'bad';
    }

    function pctJs(value) {
      return Number.isFinite(value) ? value.toFixed(2) : 'n/a';
    }

    function rowHtml(r) {
      return '<tr>' +
        '<td title=\"' + escapeHtml(r.file) + '\">' + escapeHtml(r.file) + '</td>' +
        '<td>' + r.linesHit + '/' + r.linesTotal + '</td>' +
        '<td><span class=\"pill ' + metricClassJs(r.linesPct) + '\">' + pctJs(r.linesPct) + '%</span></td>' +
      '</tr>';
    }

    function renderRows(rows, tbodyId, countId, mode) {
      const limit = mode === 'all' ? rows.length : Number(mode);
      const selected = rows.slice(0, Number.isFinite(limit) ? limit : rows.length);
      document.getElementById(tbodyId).innerHTML = selected.map(rowHtml).join('');
      document.getElementById(countId).textContent = 'Showing ' + selected.length + ' / ' + rows.length;
    }

    function wireTable(rows, selectId, tbodyId, countId) {
      const select = document.getElementById(selectId);
      const rerender = () => renderRows(rows, tbodyId, countId, select.value);
      select.addEventListener('change', rerender);
      rerender();
      return select;
    }

    const bffSelect = wireTable(bffRows, 'bff-mode', 'bff-body', 'bff-count');
    const mobileSelect = wireTable(mobileRows, 'mobile-mode', 'mobile-body', 'mobile-count');

    document.getElementById('export-pdf').addEventListener('click', () => {
      window.print();
    });

    let previousModes = null;
    window.addEventListener('beforeprint', () => {
      previousModes = {
        bff: bffSelect.value,
        mobile: mobileSelect.value,
      };
      bffSelect.value = 'all';
      mobileSelect.value = 'all';
      renderRows(bffRows, 'bff-body', 'bff-count', 'all');
      renderRows(mobileRows, 'mobile-body', 'mobile-count', 'all');
    });

    window.addEventListener('afterprint', () => {
      if (!previousModes) return;
      bffSelect.value = previousModes.bff;
      mobileSelect.value = previousModes.mobile;
      renderRows(bffRows, 'bff-body', 'bff-count', bffSelect.value);
      renderRows(mobileRows, 'mobile-body', 'mobile-count', mobileSelect.value);
    });
  </script>
</body>
</html>`;

ensureDir(reportRoot);
fs.writeFileSync(path.join(reportRoot, 'index.html'), html, 'utf8');
console.log('Generated reports/coverage/index.html');
