#!/usr/bin/env node

import { createHash } from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';
import {
  buildCurrentSnapshot,
  buildDepIndex,
  buildDepMap,
  buildQualityMetrics,
  ciIntent,
  classify,
  collectOwnership,
  compareWs,
  computeMetricsTrend,
  countBy,
  countWorkspaceDeps,
  depMermaid,
  deployFiles,
  deployIntent,
  domainDocPath,
  domainInfo,
  domainKeyFor,
  fmtDelta,
  getManagedWorkspaces,
  getTrackedPackageDirs,
  gitHeadInfo,
  groupByDomain,
  isKeyScript,
  isWorkspaceExcluded,
  listOrDash,
  loadWikiConfig,
  mergeMetricsHistory,
  nestedGitInfo,
  norm,
  normalize,
  orderedCategories,
  parseJenkins,
  parseWorkspaceYaml,
  readJson,
  readPackageWithFallback,
  scanSourceInsights,
  scriptIntent,
  scriptStage,
  table,
  unmanagedReason,
  wikiDocLink,
  wikiLink,
  workspaceDocPath,
} from './lib/facts.mjs';

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(scriptDir, '..', '..');
const isCheckMode = process.argv.includes('--check');
const outputWikiDir = path.resolve(repoRoot, 'docs/wiki-mdx');

const GENERATED_MARKER = '{/* AUTO-GENERATED: Do not edit manually. Use `pnpm run wiki:generate`. */}';

const PAGE_REFS = {
  'README.md': ['package.json', 'pnpm-workspace.yaml', 'turbo.json', 'Jenkinsfile', 'scripts/wiki/generate.mjs'],
  '01-architecture.md': ['package.json', 'pnpm-workspace.yaml', 'turbo.json', 'apps/bob-web-apps-main/package.json', 'scripts/verify/repo-layout.config.json'],
  '02-workspaces.md': ['package.json', 'pnpm-workspace.yaml', 'scripts/verify/repo-layout.config.json'],
  '03-dependency-map.md': ['package.json', 'apps/bob-web-apps-main/package.json', 'tests/e2e-main/package.json'],
  '04-dev-build-test.md': ['package.json', 'tests/e2e-main/package.json', 'turbo.json', 'Jenkinsfile'],
  '05-ci-deploy.md': ['Jenkinsfile', 'deploy/deploy-deployment.yaml', 'deploy/deploy-service.yaml', 'deploy/deploy-ingress.yaml', 'scripts/deploy/Dockerfile', 'scripts/deploy/nginx.conf'],
  '06-governance.md': [
    'scripts/verify/repo-layout.config.json',
    'docs/engineering/1governance/NESTED_GIT_GOVERNANCE.md',
    'docs/engineering/3standards/REPO_DIRECTORY_STANDARD_PLAN.md',
  ],
  '07-troubleshooting.md': ['package.json', 'pnpm-workspace.yaml', 'scripts/verify/repo-layout.config.json', 'scripts/wiki/generate.mjs'],
  '08-runtime-code-map.md': ['pnpm-workspace.yaml', 'apps/bob-web-apps-main/src/router/routes', 'packages', 'scripts/wiki/generate.mjs'],
  '09-ownership-quality.md': ['scripts/wiki/wiki.config.json', 'package.json', 'scripts/wiki/generate.mjs'],
  '10-metrics-trends.md': ['docs/wiki-mdx/metrics/history.json', 'scripts/wiki/generate.mjs', 'scripts/wiki/wiki.config.json'],
};

main();

function main() {
  const context = collectContext();
  const rawPages = new Map([
    ['README.md', buildIndex(context)],
    ['01-architecture.md', buildArchitecture(context)],
    ['02-workspaces.md', buildWorkspaces(context)],
    ['03-dependency-map.md', buildDeps(context)],
    ['04-dev-build-test.md', buildDev(context)],
    ['05-ci-deploy.md', buildCi(context)],
    ['06-governance.md', buildGov(context)],
    ['07-troubleshooting.md', buildTroubleshooting(context)],
    ['08-runtime-code-map.md', buildRuntimeCodeMap(context)],
    ['09-ownership-quality.md', buildOwnershipQuality(context)],
    ['10-metrics-trends.md', buildMetricsTrends(context)],
    ...buildMetricArtifacts(context),
    ...buildWorkspacePages(context),
    ...buildDomainPages(context),
  ]);
  const pages = toMdxPages(rawPages);
  const staleGenerated = listGeneratedMdxFiles().filter((relPath) => !pages.has(relPath));

  if (isCheckMode) {
    const drift = [];
    for (const [fileName, expectedContent] of pages.entries()) {
      const expected = normalize(expectedContent ?? '');
      const absPath = path.resolve(outputWikiDir, fileName);
      if (!fs.existsSync(absPath)) {
        drift.push(`${fileName}: missing`);
        continue;
      }
      const actual = normalize(fs.readFileSync(absPath, 'utf8'));
      if (actual !== expected) drift.push(`${fileName}: outdated`);
    }
    for (const relPath of staleGenerated) drift.push(`${relPath}: stale-generated-file`);
    if (drift.length > 0) {
      console.error('wiki:check 失敗：docs/wiki-mdx 與目前程式碼事實不同步。');
      for (const item of drift) console.error(`- ${item}`);
      console.error('\n請執行 `pnpm run wiki:generate` 並提交更新後的 `docs/wiki-mdx/*`。');
      process.exit(1);
    }
    console.log('wiki:check 通過：docs/wiki-mdx 已與程式碼同步。');
    return;
  }

  fs.mkdirSync(outputWikiDir, { recursive: true });
  for (const relPath of staleGenerated) {
    fs.unlinkSync(path.resolve(outputWikiDir, relPath));
  }
  for (const [fileName, content] of pages.entries()) {
    const absPath = path.resolve(outputWikiDir, fileName);
    fs.mkdirSync(path.dirname(absPath), { recursive: true });
    fs.writeFileSync(absPath, normalize(content ?? ''), 'utf8');
  }
  console.log(`wiki:generate 完成：已更新 docs/wiki-mdx 下 ${pages.size} 份文件。`);
}

function collectContext() {
  const wikiCfg = loadWikiConfig();
  const root = readJson('package.json');
  const turbo = readJson('turbo.json');
  const layout = readJson('scripts/verify/repo-layout.config.json');
  const wsCfg = parseWorkspaceYaml(fs.readFileSync(path.resolve(repoRoot, 'pnpm-workspace.yaml'), 'utf8'));
  const jenkinsRaw = fs.readFileSync(path.resolve(repoRoot, 'Jenkinsfile'), 'utf8');
  const managed = getManagedWorkspaces();
  const trackedPkgDirs = getTrackedPackageDirs();

  const allPkgs = trackedPkgDirs
    .map((relPath) => ({ relPath, category: classify(relPath), ...readPackageWithFallback(path.resolve(repoRoot, relPath, 'package.json')) }))
    .sort(compareWs);

  const managedRowsAll = managed
    .map((w) => {
      const relPath = norm(w.relPath);
      const absPkg = path.resolve(repoRoot, relPath, 'package.json');
      if (!fs.existsSync(absPkg)) {
        return {
          name: w.name ?? '(unknown)',
          version: w.version ?? '(unknown)',
          private: Boolean(w.private),
          relPath,
          category: classify(relPath),
          parseMode: 'missing',
          scripts: {},
          dependencies: {},
          devDependencies: {},
          peerDependencies: {},
          optionalDependencies: {},
        };
      }

      const parsed = readPackageWithFallback(absPkg);
      return {
        name: w.name ?? parsed.name,
        version: w.version ?? parsed.version,
        private: w.private ?? parsed.private,
        relPath,
        category: classify(relPath),
        parseMode: parsed.parseMode,
        scripts: parsed.scripts,
        dependencies: parsed.dependencies,
        devDependencies: parsed.devDependencies,
        peerDependencies: parsed.peerDependencies,
        optionalDependencies: parsed.optionalDependencies,
      };
    })
    .sort(compareWs);

  const managedRows = managedRowsAll.filter((w) => !isWorkspaceExcluded(w, wikiCfg));
  const managedSet = new Set(managedRowsAll.map((w) => w.relPath));
  const unmanagedRows = allPkgs
    .filter((p) => !managedSet.has(p.relPath))
    .map((p) => ({ ...p, reason: unmanagedReason(p.relPath, wsCfg) }))
    .sort(compareWs);

  const fallbackRows = managedRows.filter((w) => w.parseMode !== 'json');
  const depMap = buildDepMap(managedRows);
  const depIndex = buildDepIndex(depMap.edges);
  const jenkins = parseJenkins(jenkinsRaw);
  const nested = nestedGitInfo(layout);
  const counts = countBy(managedRows, (w) => w.category);
  const domainGroups = groupByDomain(managedRows, wikiCfg);
  const workspaceByName = new Map(managedRows.map((w) => [w.name, w]));
  const sourceInsights = scanSourceInsights(managedRows, workspaceByName, wikiCfg);
  const ownership = collectOwnership(managedRows);
  const quality = buildQualityMetrics(managedRows, depIndex, sourceInsights, ownership);
  const head = gitHeadInfo();
  const snapshot = buildCurrentSnapshot(head, managedRows, sourceInsights, quality);
  const metricsHistory = mergeMetricsHistory(snapshot);
  const metricsTrend = computeMetricsTrend(metricsHistory.entries, snapshot.commitHash);

  return {
    wikiCfg,
    head,
    root,
    turbo,
    layout,
    wsCfg,
    managedRowsAll,
    managedRows,
    unmanagedRows,
    fallbackRows,
    depMap,
    depIndex,
    jenkins,
    nested,
    counts,
    domainGroups,
    workspaceByName,
    sourceInsights,
    ownership,
    quality,
    metricsHistory,
    metricsTrend,
    snapshot,
  };
}

function buildIndex(ctx) {
  const catRows = orderedCategories(ctx.counts).map((k) => [k, String(ctx.counts[k])]);
  const guideRows = [
    ['README.md', '入口頁與維護契約'],
    ['01-architecture.md', '架構分層與工具契約'],
    ['02-workspaces.md', 'workspace 清單與覆蓋範圍'],
    ['03-dependency-map.md', 'workspace:* 相依拓撲'],
    ['04-dev-build-test.md', '日常開發與測試流程'],
    ['05-ci-deploy.md', 'CI Gate 與部署路徑'],
    ['06-governance.md', 'nested git 與治理稽核'],
    ['07-troubleshooting.md', '常見異常處理手冊'],
    ['08-runtime-code-map.md', '程式碼語義地圖（import/routes/api）'],
    ['09-ownership-quality.md', '維護責任與品質風險指標'],
    ['10-metrics-trends.md', '週期快照與趨勢變化'],
    ['workspaces/README.md', '每個 workspace 的詳細工程頁（自動生成）'],
    ['domains/README.md', '按領域聚合的架構/相依觀測頁（自動生成）'],
  ];
  const chapterDocRows = guideRows.map(([file]) => [file, wikiDocLink('README.md', file)]);
  return [
    ...docHeader('README.md', 'Monorepo Wiki 首頁', '本 Wiki 由程式碼事實自動生成，並由 CI 強制檢查同步。', [
      ['重點摘要', '#重點摘要'],
      ['快速入口', '#快速入口'],
      ['文件導覽', '#文件導覽'],
      ['Workspace 指標', '#workspace-指標'],
      ['更新契約', '#更新契約'],
    ], undefined, chapterDocRows),
    '## 重點摘要',
    `- 已納管 workspace：**${ctx.managedRows.length}**`,
    `- 生成基線工作區（含被排除）：**${ctx.managedRowsAll.length}**`,
    `- 生成 workspace 詳細頁：**${ctx.managedRows.length}**`,
    `- 生成領域頁：**${ctx.domainGroups.length}**`,
    `- 程式碼掃描檔案：**${ctx.sourceInsights.scannedFiles}**（production: ${ctx.sourceInsights.scannedProdFiles} / test: ${ctx.sourceInsights.scannedTestFiles}）`,
    `- 未納管 package 目錄：**${ctx.unmanagedRows.length}**`,
    `- 解析警示（fallback/missing）：**${ctx.fallbackRows.length}**`,
    '- CI Gate 已納入 `wiki:check`，防止文件過期。',
    '',
    '## 快速入口',
    `- [Workspace 詳細索引](${wikiDocLink('README.md', 'workspaces/README.md')})`,
    `- [領域索引](${wikiDocLink('README.md', 'domains/README.md')})`,
    `- [程式碼語義地圖](${wikiDocLink('README.md', '08-runtime-code-map.md')})`,
    '',
    '## 文件導覽',
    ...table(['文件', '用途'], guideRows.map(([file, summary]) => [`[${file}](${wikiDocLink('README.md', file)})`, summary])),
    '',
    '## Workspace 指標',
    ...table(['分類', '數量'], catRows.length ? catRows : [['(none)', '0']]),
    '',
    '## 更新契約',
    '1. 產生文件：`pnpm run wiki:generate`',
    '2. 驗證同步：`pnpm run wiki:check`',
    '3. 任何影響事實來源的 PR，需一併提交 `docs/wiki-mdx/*`',
  ].join('\n');
}

function buildArchitecture(ctx) {
  const tasks = Object.entries(ctx.turbo.tasks ?? {}).sort(([a], [b]) => a.localeCompare(b)).map(([name, task]) => [
    name,
    listOrDash(task.dependsOn),
    listOrDash(task.outputs),
    task.cache === false ? 'disabled' : 'enabled/default',
    task.persistent ? 'true' : 'false',
  ]);

  return [
    ...docHeader('01-architecture.md', '架構與建置系統', '定義 monorepo 分層、workspace 規則、Turbo 任務契約。', [
      ['架構原則', '#架構原則'],
      ['分層責任矩陣', '#分層責任矩陣'],
      ['Workspace 規則', '#workspace-規則'],
      ['Turbo 任務契約', '#turbo-任務契約'],
      ['系統示意圖', '#系統示意圖'],
    ]),
    '## 架構原則',
    '- 已納管 workspace 以 `pnpm -r list --depth -1 --json` 為唯一事實來源。',
    '- `turbo.json` 定義任務拓撲、快取與輸出契約。',
    '- `scripts/verify/repo-layout.config.json` 定義 nested git 邊界與治理責任。',
    '',
    '## 分層責任矩陣',
    ...table(['路徑', '責任'], [
      ['apps/', '可部署應用與執行入口'],
      ['packages/', '可重用模組與業務套件'],
      ['internal/', '共享 lint/build/config 基礎設施'],
      ['scripts/', 'repo 維運工具與治理腳本'],
      ['tests/', '跨 workspace E2E / 整合驗證'],
      ['deploy/', 'Kubernetes 部署清單'],
      ['docs/', '治理與知識文件'],
    ]),
    '',
    '## Workspace 規則',
    '### Include Patterns',
    ...table(['規則'], (ctx.wsCfg.includes ?? []).map((i) => [i])),
    '',
    '### Exclude Patterns',
    ...table(['規則'], (ctx.wsCfg.excludes ?? []).length ? ctx.wsCfg.excludes.map((i) => [i]) : [['(none)']]),
    '',
    '## Turbo 任務契約',
    ...table(['任務', 'dependsOn', 'outputs', 'cache', 'persistent'], tasks.length ? tasks : [['(none)', '-', '-', '-', '-']]),
    '',
    '## 系統示意圖',
    '```mermaid',
    'graph TB',
    '  Root["Root Configs\\npackage.json / pnpm-workspace.yaml / turbo.json"]',
    '  Apps["apps/*"]',
    '  Packages["packages/*"]',
    '  Internal["internal/*"]',
    '  Scripts["scripts/*"]',
    '  Tests["tests/*"]',
    '  Deploy["deploy/*"]',
    '  Docs["docs/*"]',
    '  Root --> Apps',
    '  Root --> Packages',
    '  Root --> Internal',
    '  Root --> Scripts',
    '  Root --> Tests',
    '  Scripts --> Deploy',
    '  Scripts --> Docs',
    '```',
    '',
    '## Mermaid Workflow',
    '```mermaid',
    'flowchart LR',
    '  A["Edit Source"] --> B["pnpm run wiki:generate"]',
    '  B --> C["docs/wiki-mdx/*.mdx + metrics/*.json"]',
    '  C --> D["pnpm run wiki:build:site"]',
    '  D --> E["apps/bob-web-apps-main/public/wiki-site/*.html"]',
    '  E --> F["pnpm run wiki:check / wiki:check:site"]',
    '```',
    '',
    '## File Structure',
    '```text',
    '.',
    '|-- docs/',
    '|   |-- engineering/',
    '|   `-- wiki-mdx/',
    '|       |-- *.mdx',
    '|       |-- workspaces/',
    '|       |-- domains/',
    '|       |-- metrics/',
    '|       `-- en-US/',
    '|-- scripts/',
    '|   `-- wiki/',
    '|       |-- generate.mjs',
    '|       |-- sync-en.mjs',
    '|       `-- build-site.mjs',
    '`-- apps/',
    '    `-- bob-web-apps-main/public/wiki-site/',
    '```',
  ].join('\n');
}

function buildWorkspaces(ctx) {
  const inventory = ctx.managedRows.map((w) => [
    w.category,
    w.name,
    w.version,
    w.private ? 'private' : 'public',
    w.parseMode,
    w.relPath,
    `[查看](${wikiDocLink('02-workspaces.md', workspaceDocPath(w))})`,
  ]);
  const fallback = ctx.fallbackRows.map((w) => [w.name, w.relPath]);
  const unmanaged = ctx.unmanagedRows.map((w) => [w.name, w.relPath, w.reason]);
  const catRows = orderedCategories(ctx.counts).map((k) => [k, String(ctx.counts[k])]);

  return [
    ...docHeader('02-workspaces.md', 'Workspace 清單與覆蓋範圍', '提供 deterministic 的 workspace 清冊，含 fallback 與未納管診斷。', [
      ['覆蓋摘要', '#覆蓋摘要'],
      ['已納管 Workspace 清冊', '#已納管-workspace-清冊'],
      ['解析警示（Fallback/Missing）', '#解析警示fallbackmissing'],
      ['未納管 Package 目錄', '#未納管-package-目錄'],
    ]),
    '## 覆蓋摘要',
    `- 已納管 workspace：**${ctx.managedRows.length}**`,
    `- 未納管 package 目錄：**${ctx.unmanagedRows.length}**`,
    `- 解析警示（fallback/missing）：**${ctx.fallbackRows.length}**`,
    '',
    ...table(['分類', '數量'], catRows.length ? catRows : [['(none)', '0']]),
    '',
    '## 已納管 Workspace 清冊',
    ...table(['分類', '名稱', '版本', '可見性', '解析模式', '路徑', '詳細頁'], inventory.length ? inventory : [['(none)', '-', '-', '-', '-', '-', '-']]),
    '',
    '## 解析警示（Fallback/Missing）',
    ...(fallback.length ? table(['名稱', '路徑'], fallback) : ['- 無解析警示。']),
    '',
    '## 未納管 Package 目錄',
    ...(unmanaged.length ? table(['名稱', '路徑', '原因'], unmanaged) : ['- 未發現未納管 package 目錄。']),
  ].join('\n');
}
function buildDeps(ctx) {
  const edges = ctx.depMap.edges;
  const workspaceProtocolEdges =
    ctx.depMap.workspaceProtocolEdges ?? edges.filter((e) => String(e.spec).startsWith('workspace:'));
  const nonWorkspaceLocal = ctx.depMap.nonWorkspaceLocal ?? [];
  const unresolved = ctx.depMap.unresolved;
  const hubs = ctx.depMap.hubs;
  const graph = depMermaid(edges, hubs);

  return [
    ...docHeader('03-dependency-map.md', 'Workspace Dependency Map', 'Covers local workspace dependencies, including workspace protocol and non-workspace protocol specs.', [
      ['Dependency Summary', '#dependency-summary'],
      ['Hub Nodes', '#hub-nodes'],
      ['Mermaid Graph', '#mermaid-graph'],
      ['Local Workspace Edges', '#local-workspace-edges'],
      ['Local Edges Without Workspace Protocol', '#local-edges-without-workspace-protocol'],
      ['Unresolved Workspace Protocol Edges', '#unresolved-workspace-protocol-edges'],
    ]),
    '## Dependency Summary',
    `- Local workspace edges: **${edges.length}**`,
    `- Workspace protocol edges (\`workspace:*\`): **${workspaceProtocolEdges.length}**`,
    `- Local edges without workspace protocol: **${nonWorkspaceLocal.length}**`,
    `- Unresolved workspace protocol edges: **${unresolved.length}**`,
    `- Hub nodes shown: **${hubs.length}**`,
    '',
    '## Hub Nodes',
    ...table(['Workspace', 'Outbound', 'Inbound'], hubs.map((h) => [h.name, String(h.outbound), String(h.inbound)])),
    '',
    '## Mermaid Graph',
    ...(graph.length ? graph : ['- No workspace dependency edges found.']),
    '',
    '## Local Workspace Edges',
    ...(edges.length ? table(['From', 'To', 'Section', 'Spec'], edges.map((e) => [e.from, e.to, e.section, e.spec])) : ['- No local workspace dependency edges found.']),
    '',
    '## Local Edges Without Workspace Protocol',
    ...(nonWorkspaceLocal.length
      ? table(['From', 'To', 'Section', 'Spec'], nonWorkspaceLocal.map((e) => [e.from, e.to, e.section, e.spec]))
      : ['- None.']),
    '',
    '## Unresolved Workspace Protocol Edges',
    ...(unresolved.length
      ? table(['From', 'To', 'Section', 'Spec'], unresolved.map((e) => [e.from, e.to, e.section, e.spec]))
      : ['- None.']),
  ].join('\n');
}

function buildDev(ctx) {
  const rootScripts = ctx.root.scripts ?? {};
  const scriptRows = Object.entries(rootScripts)
    .filter(([name]) => isKeyScript(name))
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([name, cmd]) => [scriptStage(name), name, cmd, scriptIntent(name)]);

  const e2e = ctx.managedRows.find((w) => w.name === '@jnpf/e2e-main')?.scripts ?? {};
  const e2eRows = Object.entries(e2e).sort(([a], [b]) => a.localeCompare(b));

  return [
    ...docHeader('04-dev-build-test.md', '開發、建置與測試流程', '整理日常開發、品質閘、E2E 的可執行命令矩陣。', [
      ['Root 指令矩陣', '#root-指令矩陣'],
      ['E2E Workspace 指令', '#e2e-workspace-指令'],
      ['建議本地流程', '#建議本地流程'],
    ]),
    '## Root 指令矩陣',
    ...table(['階段', 'Script', 'Command', '用途'], scriptRows.length ? scriptRows : [['(none)', '-', '-', '-']]),
    '',
    '## E2E Workspace 指令',
    ...table(['Script', 'Command'], e2eRows.length ? e2eRows : [['(none)', '-']]),
    '',
    '## 建議本地流程',
    '1. `pnpm install --frozen-lockfile`',
    '2. `pnpm run dev:main`（或對應 app 的 dev script）',
    '3. 提交 PR 前先跑 `pnpm run ci:main:gate:fast`',
    '4. 變更 repo 事實來源後執行 `pnpm run wiki:generate`',
    '5. push 前執行 `pnpm run wiki:check`',
  ].join('\n');
}

function buildCi(ctx) {
  const stages = ctx.jenkins.stages.map((name, idx) => [String(idx + 1), name]);
  const commands = ctx.jenkins.commands.map((cmd) => [cmd, ciIntent(cmd)]);
  const deploy = deployFiles().map((file) => [file, deployIntent(file)]);

  return [
    ...docHeader('05-ci-deploy.md', 'CI 與部署拓撲', '整理 Jenkins Stage、關鍵命令與部署產物責任邊界。', [
      ['Jenkins Stage 流程', '#jenkins-stage-流程'],
      ['關鍵 CI 指令', '#關鍵-ci-指令'],
      ['部署產物', '#部署產物'],
      ['CI Gate 契約', '#ci-gate-契約'],
    ]),
    '## Jenkins Stage 流程',
    ...table(['順序', 'Stage'], stages.length ? stages : [['-', '(none)']]),
    '',
    '## 關鍵 CI 指令',
    ...table(['Command', '用途'], commands.length ? commands : [['(none)', '-']]),
    '',
    '## 部署產物',
    ...table(['檔案', '角色'], deploy.length ? deploy : [['(none)', '-']]),
    '',
    '## CI Gate 契約',
    '- `ci:main:gate:fast` 已納入 `wiki:check`；文件漂移即失敗。',
    '- Gate 綠燈代表程式、測試與 wiki 同步。',
    '- Deploy stage 依賴 Jenkins 憑證與 `deploy/*.yaml` 清單。',
  ].join('\n');
}

function buildGov(ctx) {
  const review = ctx.layout.governanceReview ?? {};
  const entries = (ctx.layout.nestedGitGovernance ?? [])
    .slice()
    .sort((a, b) => String(a.path).localeCompare(String(b.path)))
    .map((e) => [e.path ?? '-', e.mode ?? '-', e.owner ?? '-', e.status ?? '-', e.targetState ?? '-', e.syncCadence ?? '-']);

  return [
    ...docHeader('06-governance.md', 'Repo 治理與邊界', '追蹤 nested git 責任歸屬、政策漂移與檢視頻率。', [
      ['治理設定', '#治理設定'],
      ['治理指標', '#治理指標'],
      ['已登記 Nested Git', '#已登記-nested-git'],
      ['漂移報告', '#漂移報告'],
    ]),
    '## 治理設定',
    `- team: ${review.team ?? 'unset'}`,
    `- lastReviewedOn: ${review.lastReviewedOn ?? 'unset'}`,
    `- cadenceDays: ${review.cadenceDays ?? 'unset'}`,
    '',
    '## 治理指標',
    ...table(['指標', '數值'], [
      ['已登記 nested git 條目', String(entries.length)],
      ['實際偵測 nested git 目錄', String(ctx.nested.detected.length)],
      ['未登記 nested git 目錄', String(ctx.nested.unknown.length)],
      ['設定存在但未偵測到', String(ctx.nested.missing.length)],
    ]),
    '',
    '## 已登記 Nested Git',
    ...table(['Path', 'Mode', 'Owner', 'Status', 'TargetState', 'SyncCadence'], entries.length ? entries : [['(none)', '-', '-', '-', '-', '-']]),
    '',
    '## 漂移報告',
    '### 未登記的 nested `.git` 目錄',
    ...(ctx.nested.unknown.length ? table(['Path'], ctx.nested.unknown.map((p) => [p])) : ['- 無。']),
    '',
    '### 設定有登記但未被偵測',
    ...(ctx.nested.missing.length ? table(['Path'], ctx.nested.missing.map((p) => [p])) : ['- 無。']),
    '',
    '## 常用治理指令',
    '1. `pnpm run verify:repo:layout`',
    '2. `pnpm run verify:repo:governance`',
  ].join('\n');
}

function buildTroubleshooting(ctx) {
  const rows = [
    ['`wiki:check` 失敗', '執行 `pnpm run wiki:check` 查看漂移檔案。', '文件內容已落後於程式碼事實。', '執行 `pnpm run wiki:generate` 並提交 `docs/wiki-mdx/*`。'],
    ['Workspace 未出現在清冊', '比對 `pnpm -r list --depth -1 --json` 與 `pnpm-workspace.yaml`。', 'include/exclude 規則或目錄位置不一致。', '調整 workspace 規則或修正目錄位置。'],
    ['Fallback/Missing 解析警示', '檢查目標 `package.json` 是否可被 JSON.parse。', 'JSON 格式錯誤或檔案缺失。', '修正 JSON 或補齊檔案後重生 wiki。'],
    ['Nested git 漂移', '執行 `pnpm run verify:repo:governance`。', '實際 `.git` 邊界與治理設定不一致。', '更新 `scripts/verify/repo-layout.config.json` 或移除非預期 nested repo。'],
    ['Gate 通過但部署失敗', '檢查 Jenkins deploy log 與 manifest 代換。', '憑證、tag、manifest 內容不一致。', '修正部署參數後重新觸發 pipeline。'],
  ];

  return [
    ...docHeader('07-troubleshooting.md', '疑難排解手冊', '提供可執行的診斷路徑與修復動作，降低 Gate/部署回歸風險。', [
      ['事件矩陣', '#事件矩陣'],
      ['快速指令索引', '#快速指令索引'],
      ['Repo 現況訊號', '#repo-現況訊號'],
    ]),
    '## 事件矩陣',
    ...table(['症狀', '診斷', '可能原因', '修復方式'], rows),
    '',
    '## 快速指令索引',
    '1. `pnpm run wiki:generate`',
    '2. `pnpm run wiki:check`',
    '3. `pnpm run verify:repo:layout`',
    '4. `pnpm run verify:repo:governance`',
    '5. `pnpm run ci:main:gate:fast`',
    '',
    '## Repo 現況訊號',
    `- 解析警示數（fallback/missing）：**${ctx.fallbackRows.length}**`,
    `- 未登記 nested git 數量：**${ctx.nested.unknown.length}**`,
    `- 設定存在但未偵測數量：**${ctx.nested.missing.length}**`,
  ].join('\n');
}

function buildRuntimeCodeMap(ctx) {
  const insight = ctx.sourceInsights;
  const importRows = insight.workspaceImportEdges
    .slice(0, ctx.wikiCfg.maxSamples.sourceImportEdges)
    .map((e) => {
      const fromWs = ctx.workspaceByName.get(e.from);
      const link = fromWs ? `[查看](${wikiDocLink('08-runtime-code-map.md', workspaceDocPath(fromWs))})` : '-';
      return [e.from, e.to, String(e.count), String(e.prodCount), String(e.testCount), link];
    });
  const routeRowsProd = insight.routeSamplesProd.map((r) => [r.workspace, r.path, r.file]);
  const routeRowsTest = insight.routeSamplesTest.map((r) => [r.workspace, r.path, r.file]);
  const apiRowsProd = insight.apiEndpointSamplesProd.map((a) => [a.workspace, a.method, a.endpoint, a.caller, a.ownerModule, a.authMarker, a.authMiddleware, a.authSignals, a.file]);
  const apiRowsTest = insight.apiEndpointSamplesTest.map((a) => [a.workspace, a.method, a.endpoint, a.caller, a.ownerModule, a.authMarker, a.authMiddleware, a.authSignals, a.file]);
  const unresolvedImportRows = insight.unresolvedWorkspaceImports.map((e) => [e.workspace, e.spec, e.file]);

  return [
    ...docHeader('08-runtime-code-map.md', '程式碼語義地圖', '基於 src 掃描結果，盤點 workspace import 關係、路由樣本與 API 端點樣本。', [
      ['掃描摘要', '#掃描摘要'],
      ['Workspace Import 邊', '#workspace-import-邊'],
      ['路由樣本（Production）', '#路由樣本production'],
      ['路由樣本（Test）', '#路由樣本test'],
      ['API 端點樣本（Production）', '#api-端點樣本production'],
      ['API 端點樣本（Test）', '#api-端點樣本test'],
      ['未解析 Workspace Import', '#未解析-workspace-import'],
    ]),
    '## 掃描摘要',
    ...table(['指標', '數值'], [
      ['掃描檔案數', String(insight.scannedFiles)],
      ['掃描 production 檔案數', String(insight.scannedProdFiles)],
      ['掃描 test 檔案數', String(insight.scannedTestFiles)],
      ['掃描程式行數', String(insight.totalLoc)],
      ['Workspace import 邊（去重）', String(insight.workspaceImportEdges.length)],
      ['路由樣本數（production）', String(insight.routeSamplesProd.length)],
      ['路由樣本數（test）', String(insight.routeSamplesTest.length)],
      ['API 端點樣本數（production）', String(insight.apiEndpointSamplesProd.length)],
      ['API 端點樣本數（test）', String(insight.apiEndpointSamplesTest.length)],
      ['API 授權標記（Prod auth/public/unknown）', `${insight.apiAuthSignalProd}/${insight.apiPublicSignalProd}/${insight.apiUnknownSignalProd}`],
      ['API 授權標記（Test auth/public/unknown）', `${insight.apiAuthSignalTest}/${insight.apiPublicSignalTest}/${insight.apiUnknownSignalTest}`],
      ['API 授權中介層標記（Prod 標記/無標記）', `${insight.apiMiddlewareMarkedProd}/${insight.apiMiddlewareUnmarkedProd}`],
      ['API 授權中介層標記（Test 標記/無標記）', `${insight.apiMiddlewareMarkedTest}/${insight.apiMiddlewareUnmarkedTest}`],
      ['未解析 workspace import', String(insight.unresolvedWorkspaceImports.length)],
    ]),
    '',
    '## Workspace Import 邊',
    ...(importRows.length ? table(['From', 'To', 'Count', 'Prod', 'Test', 'From 詳細頁'], importRows) : ['- 無 workspace import 邊。']),
    '',
    '## 路由樣本（Production）',
    ...(routeRowsProd.length ? table(['Workspace', 'Path', 'File'], routeRowsProd) : ['- 無 production 路由樣本。']),
    '',
    '## 路由樣本（Test）',
    ...(routeRowsTest.length ? table(['Workspace', 'Path', 'File'], routeRowsTest) : ['- 無 test 路由樣本。']),
    '',
    '## API 端點樣本（Production）',
    ...(apiRowsProd.length ? table(['Workspace', 'Method', 'Endpoint', 'Caller', 'OwnerModule', 'AuthMarker', 'AuthMiddleware', 'AuthSignals', 'File'], apiRowsProd) : ['- 無 production API 樣本。']),
    '',
    '## API 端點樣本（Test）',
    ...(apiRowsTest.length ? table(['Workspace', 'Method', 'Endpoint', 'Caller', 'OwnerModule', 'AuthMarker', 'AuthMiddleware', 'AuthSignals', 'File'], apiRowsTest) : ['- 無 test API 樣本。']),
    '',
    '## 未解析 Workspace Import',
    ...(unresolvedImportRows.length ? table(['Workspace', 'Import Spec', 'File'], unresolvedImportRows) : ['- 無未解析 workspace import。']),
  ].join('\n');
}

function buildOwnershipQuality(ctx) {
  const ownerRows = ctx.ownership.rows.map((r) => [r.workspace, r.ownerRule, r.lastCommitAuthor, r.lastCommitDate, r.primaryContributors]);
  const qualityRows = ctx.quality.rows.map((r) => [
    r.workspace,
    String(r.sourceFiles),
    String(r.sourceLoc),
    String(r.testFiles),
    String(r.todoCount),
    String(r.routeCountProd),
    String(r.routeCountTest),
    String(r.apiEndpointCountProd),
    String(r.apiEndpointCountTest),
    String(r.outboundWorkspaceDeps),
    String(r.inboundWorkspaceDeps),
    String(r.riskScore),
    r.riskLevel,
  ]);
  const riskTop = ctx.quality.rows
    .slice()
    .sort((a, b) => (b.riskScore - a.riskScore) || a.workspace.localeCompare(b.workspace))
    .slice(0, 15)
    .map((r) => [r.workspace, String(r.riskScore), r.riskLevel, r.riskReason]);

  return [
    ...docHeader('09-ownership-quality.md', 'Ownership 與品質指標', '彙整 workspace 責任歸屬（CODEOWNERS + git）與靜態品質風險指標。', [
      ['Ownership 摘要', '#ownership-摘要'],
      ['Ownership 清單', '#ownership-清單'],
      ['品質指標', '#品質指標'],
      ['風險 Top 清單', '#風險-top-清單'],
    ]),
    '## Ownership 摘要',
    ...table(['指標', '數值'], [
      ['workspace 數量', String(ctx.managedRows.length)],
      ['有 CODEOWNERS 規則', String(ownerRows.filter((r) => r[1] !== '-').length)],
      ['可解析最近提交作者', String(ownerRows.filter((r) => r[2] !== '-').length)],
    ]),
    '',
    '## Ownership 清單',
    ...(ownerRows.length ? table(['Workspace', 'CODEOWNERS', 'Last Commit Author', 'Last Commit Date', 'Top Contributors'], ownerRows) : ['- 無 ownership 資料。']),
    '',
    '## 品質指標',
    ...(qualityRows.length
      ? table(['Workspace', 'SourceFiles', 'LOC', 'TestFiles', 'TODO', 'RoutesProd', 'RoutesTest', 'ApiProd', 'ApiTest', 'OutDeps', 'InDeps', 'RiskScore', 'RiskLevel'], qualityRows)
      : ['- 無品質指標資料。']),
    '',
    '## 風險 Top 清單',
    ...(riskTop.length ? table(['Workspace', 'RiskScore', 'RiskLevel', 'Reason'], riskTop) : ['- 無風險資料。']),
  ].join('\n');
}

function buildMetricArtifacts(ctx) {
  const historyPayload = {
    version: 1,
    generatedBy: 'scripts/wiki/generate.mjs',
    entries: ctx.metricsHistory.entries,
  };
  return [
    ['metrics/current.json', `${JSON.stringify(ctx.snapshot, null, 2)}\n`],
    ['metrics/history.json', `${JSON.stringify(historyPayload, null, 2)}\n`],
  ];
}

function buildMetricsTrends(ctx) {
  const t = ctx.metricsTrend;
  const c = ctx.snapshot;
  const prevLabel = t.previous ? `${t.previous.shortHash} (${t.previous.commitDate})` : 'N/A';
  const recentRows = ctx.metricsHistory.entries
    .slice()
    .reverse()
    .slice(0, 20)
    .map((e) => [
      e.shortHash,
      e.commitDate,
      String(e.workspaceCount),
      String(e.sourceLoc),
      String(e.todoTotal),
      String(e.importEdgeCount),
      String(e.riskHigh),
      String(e.riskMedium),
      String(e.riskLow),
    ]);

  return [
    ...docHeader('10-metrics-trends.md', '週期快照與趨勢', '將每次生成的核心工程指標落盤，支援跨提交趨勢觀測。', [
      ['目前快照', '#目前快照'],
      ['相對前一版變化', '#相對前一版變化'],
      ['近期歷史（最近 20 筆）', '#近期歷史最近-20-筆'],
      ['指標檔案', '#指標檔案'],
    ]),
    '## 目前快照',
    ...table(['指標', '值'], [
      ['Commit', `${c.shortHash} (${c.commitDate})`],
      ['Workspace 數', String(c.workspaceCount)],
      ['掃描檔案（Prod/Test）', `${c.scannedProdFiles}/${c.scannedTestFiles}`],
      ['掃描 LOC', String(c.sourceLoc)],
      ['TODO/FIXME/HACK 總數', String(c.todoTotal)],
      ['Import 邊數', String(c.importEdgeCount)],
      ['Route 樣本（Prod/Test）', `${c.routeSampleProd}/${c.routeSampleTest}`],
      ['API 樣本（Prod/Test）', `${c.apiSampleProd}/${c.apiSampleTest}`],
      ['風險（High/Medium/Low）', `${c.riskHigh}/${c.riskMedium}/${c.riskLow}`],
    ]),
    '',
    '## 相對前一版變化',
    ...table(['比較基準', 'Workspace', 'LOC', 'TODO', 'ImportEdges', 'RiskHigh', 'RiskMedium', 'RiskLow'], [[
      prevLabel,
      fmtDelta(t.delta.workspaceCount),
      fmtDelta(t.delta.sourceLoc),
      fmtDelta(t.delta.todoTotal),
      fmtDelta(t.delta.importEdgeCount),
      fmtDelta(t.delta.riskHigh),
      fmtDelta(t.delta.riskMedium),
      fmtDelta(t.delta.riskLow),
    ]]),
    '',
    '## 近期歷史（最近 20 筆）',
    ...(recentRows.length
      ? table(['Commit', 'Date', 'Workspaces', 'LOC', 'TODO', 'ImportEdges', 'RiskHigh', 'RiskMedium', 'RiskLow'], recentRows)
      : ['- 無歷史資料。']),
    '',
    '## 指標檔案',
    '- [metrics/current.json](./metrics/current.json)',
    '- [metrics/history.json](./metrics/history.json)',
  ].join('\n');
}

function buildWorkspacePages(ctx) {
  const pages = [];
  const workspaces = ctx.managedRows.slice().sort(compareWs);
  const categoryRows = orderedCategories(countBy(workspaces, (w) => w.category)).map((k) => [k, String(workspaces.filter((w) => w.category === k).length)]);

  pages.push([
    'workspaces/README.md',
    [
      ...docHeader('workspaces/README.md', 'Workspace 詳細索引', '每個 workspace 皆有獨立文件，提供腳本、相依與風險觀測。', [
        ['摘要', '#摘要'],
        ['分類分布', '#分類分布'],
        ['Workspace 詳細頁清單', '#workspace-詳細頁清單'],
      ], ['pnpm-workspace.yaml', 'scripts/wiki/generate.mjs', 'package.json']),
      '## 摘要',
      `- Workspace 文件數：**${workspaces.length}**`,
      '- 每頁皆為 AUTO-GENERATED，變更請回到程式碼與生成器。',
      '',
      '## 分類分布',
      ...table(['分類', '數量'], categoryRows.length ? categoryRows : [['(none)', '0']]),
      '',
      '## Workspace 詳細頁清單',
      ...table(
        ['分類', '名稱', '版本', '路徑', '詳細頁'],
        workspaces.map((w) => [w.category, w.name, w.version, w.relPath, `[查看](./${path.basename(workspaceDocPath(w))})`]),
      ),
    ].join('\n'),
  ]);

  for (const ws of workspaces) {
    const fileName = workspaceDocPath(ws);
    const outEdges = ctx.depIndex.byFrom.get(ws.name) ?? [];
    const inEdges = ctx.depIndex.byTo.get(ws.name) ?? [];
    const unresolved = ctx.depMap.unresolved.filter((e) => e.from === ws.name);
    const scripts = Object.entries(ws.scripts ?? {}).sort(([a], [b]) => a.localeCompare(b));
    const domain = domainInfo(domainKeyFor(ws.relPath, ctx.wikiCfg), ctx.wikiCfg);
    const st = ctx.sourceInsights.workspaceStats.get(ws.name) ?? {
      sourceFiles: 0,
      sourceLoc: 0,
      testFiles: 0,
      todoCount: 0,
      routeCountProd: 0,
      routeCountTest: 0,
      apiEndpointCountProd: 0,
      apiEndpointCountTest: 0,
    };
    const own = ctx.ownership.byWorkspace.get(ws.name) ?? {
      lastCommitAuthor: '-',
      lastCommitDate: '-',
      ownerRule: '-',
    };

    const outRows = outEdges.map((e) => {
      const target = ctx.workspaceByName.get(e.to);
      const toCell = target ? `[${e.to}](${wikiDocLink(fileName, workspaceDocPath(target))})` : e.to;
      return [toCell, e.section, e.spec];
    });
    const inRows = inEdges.map((e) => {
      const source = ctx.workspaceByName.get(e.from);
      const fromCell = source ? `[${e.from}](${wikiDocLink(fileName, workspaceDocPath(source))})` : e.from;
      return [fromCell, e.section, e.spec];
    });
    const depSummaryRows = [
      ['dependencies', String(Object.keys(ws.dependencies ?? {}).length), String(countWorkspaceDeps(ws.dependencies ?? {}))],
      ['devDependencies', String(Object.keys(ws.devDependencies ?? {}).length), String(countWorkspaceDeps(ws.devDependencies ?? {}))],
      ['peerDependencies', String(Object.keys(ws.peerDependencies ?? {}).length), String(countWorkspaceDeps(ws.peerDependencies ?? {}))],
      ['optionalDependencies', String(Object.keys(ws.optionalDependencies ?? {}).length), String(countWorkspaceDeps(ws.optionalDependencies ?? {}))],
    ];

    pages.push([
      fileName,
      [
        ...docHeader(fileName, `Workspace：${ws.name}`, '單一 workspace 的工程事實頁，供開發與維運快速定位。', [
          ['基本資訊', '#基本資訊'],
          ['腳本清單', '#腳本清單'],
          ['相依摘要', '#相依摘要'],
          ['Workspace Outbound', '#workspace-outbound'],
          ['Workspace Inbound', '#workspace-inbound'],
          ['未解析相依', '#未解析相依'],
        ], [`${ws.relPath}/package.json`, 'pnpm-workspace.yaml', 'scripts/wiki/generate.mjs']),
        '## 基本資訊',
        ...table(['欄位', '值'], [
          ['名稱', ws.name],
          ['版本', ws.version],
          ['分類', ws.category],
          ['領域', domain.title],
          ['路徑', ws.relPath],
          ['可見性', ws.private ? 'private' : 'public'],
          ['解析模式', ws.parseMode],
          ['CODEOWNERS', own.ownerRule],
          ['最近提交作者', own.lastCommitAuthor],
          ['最近提交日期', own.lastCommitDate],
          ['Source Files', String(st.sourceFiles)],
          ['Source LOC', String(st.sourceLoc)],
          ['Test Files', String(st.testFiles)],
          ['TODO/FIXME/HACK', String(st.todoCount)],
          ['Route Samples (Prod)', String(st.routeCountProd)],
          ['Route Samples (Test)', String(st.routeCountTest)],
          ['API Endpoint Samples (Prod)', String(st.apiEndpointCountProd)],
          ['API Endpoint Samples (Test)', String(st.apiEndpointCountTest)],
          ['領域頁', `[${domain.title}](${wikiDocLink(fileName, domainDocPath(domain.key))})`],
        ]),
        '',
        '## 腳本清單',
        ...(scripts.length ? table(['Script', 'Command'], scripts.map(([name, cmd]) => [name, cmd])) : ['- 無腳本。']),
        '',
        '## 相依摘要',
        ...table(['區段', '總數', 'workspace:*'], depSummaryRows),
        '',
        '## Workspace Outbound',
        ...(outRows.length ? table(['To', 'Section', 'Spec'], outRows) : ['- 無 outbound workspace 相依。']),
        '',
        '## Workspace Inbound',
        ...(inRows.length ? table(['From', 'Section', 'Spec'], inRows) : ['- 無 inbound workspace 相依。']),
        '',
        '## 未解析相依',
        ...(unresolved.length
          ? table(['To', 'Section', 'Spec'], unresolved.map((e) => [e.to, e.section, e.spec]))
          : ['- 無未解析 workspace 相依。']),
      ].join('\n'),
    ]);
  }

  return pages;
}

function buildDomainPages(ctx) {
  const pages = [];
  const groups = ctx.domainGroups;
  const nameToDomain = new Map();
  for (const group of groups) {
    for (const ws of group.workspaces) nameToDomain.set(ws.name, group.key);
  }

  pages.push([
    'domains/README.md',
    [
      ...docHeader('domains/README.md', '領域索引（Domain Index）', '依領域聚合 workspace，提供架構視角與相依觀測。', [
        ['摘要', '#摘要'],
        ['領域清單', '#領域清單'],
      ], ['pnpm-workspace.yaml', 'scripts/wiki/generate.mjs', 'package.json']),
      '## 摘要',
      `- 領域數量：**${groups.length}**`,
      `- 涵蓋 workspace：**${ctx.managedRows.length}**`,
      '',
      '## 領域清單',
      ...table(
        ['領域', 'Key', 'Workspace 數', '摘要', '詳細頁'],
        groups.map((g) => [g.title, g.key, String(g.workspaces.length), g.summary, `[查看](./${path.basename(domainDocPath(g.key))})`]),
      ),
    ].join('\n'),
  ]);

  for (const group of groups) {
    const fileName = domainDocPath(group.key);
    const unresolvedRows = [];
    let inboundTotal = 0;
    let outboundTotal = 0;
    let internalEdges = 0;
    let crossInbound = 0;
    let crossOutbound = 0;
    const outboundByDomain = {};
    const inboundByDomain = {};

    for (const ws of group.workspaces) {
      const outEdges = ctx.depIndex.byFrom.get(ws.name) ?? [];
      const inEdges = ctx.depIndex.byTo.get(ws.name) ?? [];
      outboundTotal += outEdges.length;
      inboundTotal += inEdges.length;

      for (const e of outEdges) {
        const targetDomain = nameToDomain.get(e.to) ?? ctx.wikiCfg.defaultDomain.key;
        if (targetDomain === group.key) {
          internalEdges += 1;
        } else {
          crossOutbound += 1;
          outboundByDomain[targetDomain] = (outboundByDomain[targetDomain] ?? 0) + 1;
        }
      }
      for (const e of inEdges) {
        const sourceDomain = nameToDomain.get(e.from) ?? ctx.wikiCfg.defaultDomain.key;
        if (sourceDomain !== group.key) {
          crossInbound += 1;
          inboundByDomain[sourceDomain] = (inboundByDomain[sourceDomain] ?? 0) + 1;
        }
      }

      for (const e of ctx.depMap.unresolved) {
        if (e.from === ws.name) unresolvedRows.push([ws.name, e.to, e.section, e.spec]);
      }
    }

    const workspaceRows = group.workspaces.map((w) => [
      w.category,
      w.name,
      w.version,
      w.relPath,
      `[查看](${wikiDocLink(fileName, workspaceDocPath(w))})`,
    ]);
    const outboundRows = Object.entries(outboundByDomain)
      .map(([domainKey, count]) => [domainInfo(domainKey, ctx.wikiCfg).title, domainKey, String(count)])
      .sort((a, b) => Number(b[2]) - Number(a[2]) || a[1].localeCompare(b[1]));
    const inboundRows = Object.entries(inboundByDomain)
      .map(([domainKey, count]) => [domainInfo(domainKey, ctx.wikiCfg).title, domainKey, String(count)])
      .sort((a, b) => Number(b[2]) - Number(a[2]) || a[1].localeCompare(b[1]));

    pages.push([
      fileName,
      [
        ...docHeader(fileName, `領域：${group.title}`, group.summary, [
          ['領域摘要', '#領域摘要'],
          ['Workspace 清單', '#workspace-清單'],
          ['跨領域 Outbound', '#跨領域-outbound'],
          ['跨領域 Inbound', '#跨領域-inbound'],
          ['未解析相依', '#未解析相依'],
        ], ['pnpm-workspace.yaml', 'scripts/wiki/generate.mjs', 'package.json']),
        '## 領域摘要',
        ...table(['指標', '數值'], [
          ['Workspace 數量', String(group.workspaces.length)],
          ['Outbound workspace 邊', String(outboundTotal)],
          ['Inbound workspace 邊', String(inboundTotal)],
          ['領域內部邊', String(internalEdges)],
          ['跨領域 Outbound 邊', String(crossOutbound)],
          ['跨領域 Inbound 邊', String(crossInbound)],
        ]),
        '',
        '## Workspace 清單',
        ...table(['分類', '名稱', '版本', '路徑', '詳細頁'], workspaceRows),
        '',
        '## 跨領域 Outbound',
        ...(outboundRows.length ? table(['目標領域', 'Key', '邊數'], outboundRows) : ['- 無跨領域 outbound。']),
        '',
        '## 跨領域 Inbound',
        ...(inboundRows.length ? table(['來源領域', 'Key', '邊數'], inboundRows) : ['- 無跨領域 inbound。']),
        '',
        '## 未解析相依',
        ...(unresolvedRows.length ? table(['From', 'To', 'Section', 'Spec'], unresolvedRows) : ['- 無未解析 workspace 相依。']),
      ].join('\n'),
    ]);
  }

  return pages;
}

function docHeader(fileName, title, summary, toc, refsOverride, tocDocs) {
  const refs = Array.isArray(refsOverride) ? refsOverride : (PAGE_REFS[fileName] ?? []);
  const generateCmd = '`node scripts/wiki/generate.mjs --mdx`';
  const checkCmd = '`node scripts/wiki/generate.mjs --check --mdx`';
  const outputRange = '`docs/wiki-mdx/*`';
  return [
    GENERATED_MARKER,
    `# ${title}`,
    '',
    '## 文件定位',
    summary,
    '',
    '## 更新摘要',
    '- 本文件由程式碼與設定檔事實自動生成，不依賴人工手寫敘述。',
    '- 排序與格式固定，確保重複生成輸出一致（deterministic）。',
    '- CI Gate 使用 `wiki:check` 驗證文件是否與程式碼同步。',
    '',
    '## 文件中繼資料',
    ...table(['欄位', '內容'], [
      ['產生器', generateCmd],
      ['驗證指令', checkCmd],
      ['輸出範圍', outputRange],
      ['核心來源', '`package.json`, `pnpm-workspace.yaml`, `turbo.json`, `Jenkinsfile`'],
    ]),
    '',
    '## 引用檔案',
    ...(refs.length ? refs.map((p) => `- [${p}](${wikiLink(p, fileName)})`) : ['- (none)']),
    '',
    '## 章節目錄',
    ...toc.map(([label, href], i) => `${i + 1}. [${label}](${href})`),
    ...(tocDocs?.length
      ? [
          '',
          '### 文件清單',
          ...tocDocs.map(([label, href], i) => `${i + 1}. [${label}](${href})`),
        ]
      : []),
    '',
  ];
}

function toMdxPages(rawPages) {
  const mdPages = new Set([...rawPages.keys()].filter((p) => p.endsWith('.md')));
  const out = new Map();
  for (const [fileName, content] of rawPages.entries()) {
    if (!fileName.endsWith('.md')) {
      out.set(fileName, content);
      continue;
    }
    const mdxName = `${fileName.slice(0, -3)}.mdx`;
    out.set(mdxName, toMdxContent(fileName, String(content ?? ''), mdPages));
  }
  return out;
}

function toMdxContent(fromMdFile, markdown, mdPages) {
  const title = extractTitle(markdown, fromMdFile);
  const linked = rewriteMdLinksForMdx(markdown, fromMdFile, mdPages);
  const docId = makeWikiDocId(fromMdFile);
  const sourceHash = computeSourceHash(linked);
  const frontmatter = [
    '---',
    `title: "${escapeYaml(title)}"`,
    `source: "${escapeYaml(fromMdFile)}"`,
    'generated: true',
    `doc_id: "${escapeYaml(docId)}"`,
    'lang: "zh-TW"',
    'source_of_truth: "zh-TW"',
    'translation_status: "source"',
    `source_hash: "${sourceHash}"`,
    'owner: "bob"',
    'last_synced_utc: "2026-03-01T00:00:00Z"',
    '---',
    '',
  ].join('\n');
  return `${frontmatter}${linked}`;
}

function extractTitle(markdown, fromMdFile) {
  const match = markdown.match(/^#\s+(.+)$/m);
  return match?.[1]?.trim() || path.basename(fromMdFile, '.md');
}

function rewriteMdLinksForMdx(markdown, fromMdFile, mdPages) {
  const fromDir = path.posix.dirname(fromMdFile.replaceAll('\\', '/'));
  return markdown.replace(/\]\(([^)\s]+)\)/g, (full, targetRaw) => {
    const target = String(targetRaw);
    if (/^[a-z]+:\/\//i.test(target) || target.startsWith('mailto:')) return full;
    const hashIndex = target.indexOf('#');
    const targetPath = hashIndex >= 0 ? target.slice(0, hashIndex) : target;
    const targetHash = hashIndex >= 0 ? target.slice(hashIndex) : '';
    if (!targetPath.endsWith('.md')) return full;

    const resolved = path.posix.normalize(path.posix.join(fromDir, targetPath));
    if (!mdPages.has(resolved)) return full;

    let rel = path.posix.relative(fromDir, `${resolved.slice(0, -3)}.mdx`);
    if (!rel.startsWith('.')) rel = `./${rel}`;
    return `](${rel}${targetHash})`;
  });
}

function escapeYaml(value) {
  return String(value).replaceAll('\\', '\\\\').replaceAll('"', '\\"');
}

function computeSourceHash(content) {
  return createHash('sha256')
    .update(String(content).replaceAll('\r\n', '\n').replaceAll('\r', '\n').trimEnd(), 'utf8')
    .digest('hex');
}

function makeWikiDocId(fromMdFile) {
  return `wiki-${String(fromMdFile).replace(/\.md$/i, '').replace(/[\\/]/g, '--')}`;
}

function listGeneratedMdxFiles() {
  if (!fs.existsSync(outputWikiDir)) return [];
  const files = [];
  const stack = [outputWikiDir];
  while (stack.length) {
    const dir = stack.pop();
    if (!dir) continue;
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const abs = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        stack.push(abs);
        continue;
      }
      if (!entry.isFile() || !entry.name.endsWith('.mdx')) continue;
      const raw = fs.readFileSync(abs, 'utf8');
      if (!raw.includes(GENERATED_MARKER)) continue;
      const rel = norm(path.relative(outputWikiDir, abs));
      if (rel.startsWith('en-US/')) continue;
      files.push(rel);
    }
  }
  return files.sort((a, b) => a.localeCompare(b));
}

