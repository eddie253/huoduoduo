import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import {
  repoRoot,
  arr,
  intOr,
  norm,
  readJson,
  regEsc,
  runWithFallback,
  safeReadDir,
  strMap,
  matchString,
  matchBool,
  matchObject,
  mLabel,
  normalizeDrive,
  toPosix,
  unquote,
  wikiLink,
} from './io.mjs';

const CATEGORY_ORDER = { apps: 1, internal: 2, packages: 3, scripts: 4, tests: 5, other: 99 };
const WIKI_CONFIG_PATH = 'scripts/wiki/wiki.config.json';
const DEFAULT_WIKI_CONFIG = {
  excludeWorkspaceNames: [],
  excludeWorkspacePaths: [],
  sourceExtensions: ['.ts', '.tsx', '.js', '.jsx', '.mts', '.cts', '.vue'],
  routePathPatterns: ['/router/', '/routes/'],
  maxSamples: {
    routes: 120,
    apiEndpoints: 120,
    sourceImportEdges: 400,
  },
  domainRules: [
    { key: 'application-shell', title: '應用殼層（Apps）', summary: '對外可部署應用與主要執行入口。', order: 1, prefixes: ['apps/'] },
    { key: 'internal-infrastructure', title: '內部基礎設施（Internal）', summary: 'Lint、Vite、Tailwind、Node 工具等共享基礎。', order: 2, prefixes: ['internal/'] },
    { key: 'core-base', title: 'Core Base', summary: '@core/base 與基礎型別、設計系統。', order: 3, prefixes: ['packages/@core/base/'] },
    { key: 'core-ui-kit', title: 'Core UI Kit', summary: '@core/ui-kit 元件與介面層模組。', order: 4, prefixes: ['packages/@core/ui-kit/'] },
    { key: 'core-runtime', title: 'Core Runtime', summary: '@core 其他執行期能力（composables/preferences）。', order: 5, prefixes: ['packages/@core/'] },
    { key: 'effects-extensions', title: 'Effects 擴充層', summary: 'effects/* 套件（access/layout/request/plugins 等）。', order: 6, prefixes: ['packages/effects/'] },
    { key: 'jnpf-business-core', title: 'JNPF 業務核心', summary: 'jnpf hooks/ui/utils 等業務核心能力。', order: 7, prefixes: ['packages/jnpf/'] },
    { key: 'jnpf-plugins', title: 'JNPF 插件域', summary: 'jnpf/plugins 下的插件型 workspace。', order: 8, prefixes: ['packages/jnpf/plugins/'] },
    { key: 'shared-packages', title: '共享套件', summary: 'constants/locales/types/utils 等跨域共享模組。', order: 9, prefixes: ['packages/'] },
    { key: 'developer-toolchain', title: '開發工具鏈（Scripts）', summary: 'turbo-run、vsh、wiki generator 等開發維運工具。', order: 10, prefixes: ['scripts/'] },
    { key: 'quality-assurance', title: '品質驗證（Tests）', summary: 'E2E、smoke 等自動化驗證工作區。', order: 11, prefixes: ['tests/'] },
  ],
  defaultDomain: { key: 'other', title: '其他', summary: '未歸類 workspace。', order: 99 },
};

export function getManagedWorkspaces() {
  const raw = runWithFallback(['pnpm -r list --depth -1 --json', 'corepack pnpm -r list --depth -1 --json']);
  const list = JSON.parse(raw);
  if (!Array.isArray(list)) throw new Error('Unexpected pnpm list output.');

  return list
    .filter((i) => i?.path && normalizeDrive(i.path) !== normalizeDrive(repoRoot))
    .map((i) => ({
      name: i.name ?? '(unknown)',
      version: i.version ?? '(unknown)',
      private: Boolean(i.private),
      relPath: toPosix(path.relative(repoRoot, i.path)),
      category: classify(toPosix(path.relative(repoRoot, i.path))),
    }))
    .sort(compareWs);
}

export function getTrackedPackageDirs() {
  const raw = execFileSync('git', ['ls-files', '-z'], { cwd: repoRoot, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
  const allowed = ['apps/', 'packages/', 'internal/', 'tests/', 'scripts/', '.bob-tools/'];
  return [...new Set(raw.split('\0').filter(Boolean)
    .filter((f) => f.endsWith('/package.json'))
    .filter((f) => allowed.some((a) => f.startsWith(a)))
    .map((f) => f.slice(0, -'/package.json'.length)))].sort((a, b) => a.localeCompare(b));
}

export function readPackageWithFallback(absPath) {
  const raw = fs.readFileSync(absPath, 'utf8');
  try {
    const p = JSON.parse(raw);
    return {
      name: p.name ?? '(unknown)',
      version: p.version ?? '(unknown)',
      private: Boolean(p.private),
      parseMode: 'json',
      scripts: strMap(p.scripts),
      dependencies: strMap(p.dependencies),
      devDependencies: strMap(p.devDependencies),
      peerDependencies: strMap(p.peerDependencies),
      optionalDependencies: strMap(p.optionalDependencies),
    };
  } catch {
    return {
      name: matchString(raw, 'name') ?? '(unknown)',
      version: matchString(raw, 'version') ?? '(unknown)',
      private: matchBool(raw, 'private') ?? false,
      parseMode: 'fallback',
      scripts: matchObject(raw, 'scripts'),
      dependencies: matchObject(raw, 'dependencies'),
      devDependencies: matchObject(raw, 'devDependencies'),
      peerDependencies: matchObject(raw, 'peerDependencies'),
      optionalDependencies: matchObject(raw, 'optionalDependencies'),
    };
  }
}

export function buildDepMap(workspaces) {
  const names = new Set(workspaces.map((w) => w.name));
  const sections = ['dependencies', 'devDependencies', 'peerDependencies', 'optionalDependencies'];
  const edges = [];
  const workspaceProtocolEdges = [];
  const nonWorkspaceLocal = [];
  const unresolved = [];

  for (const ws of workspaces) {
    for (const sec of sections) {
      const deps = ws[sec] ?? {};
      for (const [dep, rawSpec] of Object.entries(deps)) {
        if (typeof rawSpec !== 'string') continue;
        const spec = rawSpec.trim();
        const isWorkspaceProtocol = spec.startsWith('workspace:');
        const edge = { from: ws.name, to: dep, section: sec, spec };

        if (names.has(dep)) {
          edges.push(edge);
          if (isWorkspaceProtocol) workspaceProtocolEdges.push(edge);
          else nonWorkspaceLocal.push(edge);
          continue;
        }

        if (isWorkspaceProtocol) {
          unresolved.push(edge);
        }
      }
    }
  }

  const key = (e) => `${e.from}\u0000${e.to}\u0000${e.section}\u0000${e.spec}`;
  edges.sort((a, b) => key(a).localeCompare(key(b)));
  workspaceProtocolEdges.sort((a, b) => key(a).localeCompare(key(b)));
  nonWorkspaceLocal.sort((a, b) => key(a).localeCompare(key(b)));
  unresolved.sort((a, b) => key(a).localeCompare(key(b)));

  const inCount = new Map();
  const outCount = new Map();
  for (const ws of workspaces) {
    inCount.set(ws.name, 0);
    outCount.set(ws.name, 0);
  }
  for (const e of edges) {
    outCount.set(e.from, (outCount.get(e.from) ?? 0) + 1);
    inCount.set(e.to, (inCount.get(e.to) ?? 0) + 1);
  }

  const hubs = workspaces
    .map((ws) => ({ name: ws.name, outbound: outCount.get(ws.name) ?? 0, inbound: inCount.get(ws.name) ?? 0 }))
    .sort((a, b) => (b.inbound - a.inbound) || (b.outbound - a.outbound) || a.name.localeCompare(b.name))
    .slice(0, 15);

  return { edges, workspaceProtocolEdges, nonWorkspaceLocal, unresolved, hubs };
}

export function buildDepIndex(edges) {
  const byFrom = new Map();
  const byTo = new Map();
  for (const edge of edges) {
    if (!byFrom.has(edge.from)) byFrom.set(edge.from, []);
    if (!byTo.has(edge.to)) byTo.set(edge.to, []);
    byFrom.get(edge.from).push(edge);
    byTo.get(edge.to).push(edge);
  }
  for (const list of byFrom.values()) list.sort((a, b) => `${a.to}\u0000${a.section}\u0000${a.spec}`.localeCompare(`${b.to}\u0000${b.section}\u0000${b.spec}`));
  for (const list of byTo.values()) list.sort((a, b) => `${a.from}\u0000${a.section}\u0000${a.spec}`.localeCompare(`${b.from}\u0000${b.section}\u0000${b.spec}`));
  return { byFrom, byTo };
}

export function depMermaid(edges, hubs) {
  if (!edges.length || !hubs.length) return [];
  const focus = new Set(hubs.slice(0, 10).map((h) => h.name));
  const selected = edges.filter((e) => focus.has(e.from) || focus.has(e.to)).slice(0, 28);
  if (!selected.length) return [];

  const nodes = [...new Set(selected.flatMap((e) => [e.from, e.to]))].sort((a, b) => a.localeCompare(b));
  const id = new Map(nodes.map((n, i) => [n, `N${i + 1}`]));

  const lines = ['```mermaid', 'graph LR'];
  for (const n of nodes) lines.push(`  ${id.get(n)}["${mLabel(n)}"]`);
  for (const e of selected) lines.push(`  ${id.get(e.from)} -->|${mLabel(e.section)}| ${id.get(e.to)}`);
  lines.push('```');
  return lines;
}

export function parseJenkins(raw) {
  const stages = [];
  const r = /stage\('([^']+)'\)/g;
  let m = r.exec(raw);
  while (m) {
    stages.push(m[1]);
    m = r.exec(raw);
  }

  const patterns = [/pnpm run [^\n'\"]+/g, /pnpm --filter [^\n'\"]+/g, /docker build [^\n'\"]+/g, /docker push [^\n'\"]+/g, /kubectl apply -f -/g];
  const commands = new Set();
  for (const p of patterns) {
    for (const item of raw.match(p) ?? []) commands.add(item.trim());
  }

  return { stages, commands: [...commands].sort((a, b) => a.localeCompare(b)) };
}

export function nestedGitInfo(layout) {
  const configured = new Set((layout.nestedGitGovernance ?? []).map((e) => norm(e.path)));
  const skip = new Set([...(layout.walkSkipDirectories ?? []), 'node_modules', '.git', '.turbo', '.qoder', 'dist', 'output']);
  const found = [];

  const stack = [repoRoot];
  while (stack.length) {
    const dir = stack.pop();
    if (!dir) continue;
    const entries = safeReadDir(dir);
    for (const entry of entries) {
      const abs = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        if (entry.name === '.git') {
          const rel = toPosix(path.relative(repoRoot, abs));
          if (rel !== '.git') found.push(rel);
          continue;
        }
        if (!skip.has(entry.name)) stack.push(abs);
      }
    }
  }

  const detected = [...new Set(found)].sort((a, b) => a.localeCompare(b));
  const unknown = detected.filter((p) => !configured.has(p)).sort((a, b) => a.localeCompare(b));
  const missing = [...configured].filter((p) => !detected.includes(p)).sort((a, b) => a.localeCompare(b));
  return { detected, unknown, missing };
}

export function parseWorkspaceYaml(raw) {
  const lines = raw.split(/\r?\n/);
  const patterns = [];
  let inPackages = false;

  for (const line of lines) {
    const t = line.trim();
    if (!inPackages) {
      if (t === 'packages:') inPackages = true;
      continue;
    }
    if (!line.startsWith(' ') && !line.startsWith('\t') && !t.startsWith('-')) break;
    if (!t.startsWith('- ')) continue;
    const value = unquote(t.slice(2).trim());
    if (value) patterns.push(value);
  }

  return {
    includes: patterns.filter((p) => !p.startsWith('!')),
    excludes: patterns.filter((p) => p.startsWith('!')).map((p) => p.slice(1)),
  };
}

export function unmanagedReason(relPath, wsCfg) {
  if (matchGlobAny(norm(relPath), wsCfg.excludes)) return '符合 pnpm-workspace.yaml 的 exclude 規則';
  if (!matchGlobAny(norm(relPath), wsCfg.includes)) return '未符合 pnpm-workspace.yaml 的 include 規則';
  return '未出現在 pnpm 納管 workspace 清單';
}

export function matchGlobAny(value, patterns) {
  return patterns.some((p) => globToRegExp(norm(p)).test(value));
}

export function globToRegExp(glob) {
  const esc = regEsc(glob).replaceAll('**', '__DS__').replaceAll('*', '[^/]*').replaceAll('__DS__', '.*').replaceAll('?', '[^/]');
  return new RegExp(`^${esc}$`);
}

export function classify(relPath) {
  const p = norm(relPath);
  if (p.startsWith('apps/')) return 'apps';
  if (p.startsWith('internal/')) return 'internal';
  if (p.startsWith('packages/')) return 'packages';
  if (p.startsWith('scripts/')) return 'scripts';
  if (p.startsWith('tests/')) return 'tests';
  return 'other';
}

export function domainKeyFor(relPath, wikiCfg) {
  const p = norm(relPath);
  let best = null;
  for (const rule of wikiCfg.domainRules) {
    for (const prefix of rule.prefixes ?? []) {
      const px = norm(prefix);
      if (!p.startsWith(px)) continue;
      const candidate = { key: rule.key, order: rule.order, prefixLength: px.length };
      if (!best || candidate.prefixLength > best.prefixLength || (candidate.prefixLength === best.prefixLength && candidate.order < best.order)) {
        best = candidate;
      }
    }
  }
  return best ? best.key : wikiCfg.defaultDomain.key;
}

export function domainInfo(domainKey, wikiCfg) {
  const rule = wikiCfg.domainRules.find((item) => item.key === domainKey);
  if (rule) return { key: rule.key, title: rule.title, summary: rule.summary, order: rule.order };
  return { key: wikiCfg.defaultDomain.key, title: wikiCfg.defaultDomain.title, summary: wikiCfg.defaultDomain.summary, order: wikiCfg.defaultDomain.order };
}

export function groupByDomain(workspaces, wikiCfg) {
  const groups = new Map();
  for (const ws of workspaces) {
    const key = domainKeyFor(ws.relPath, wikiCfg);
    if (!groups.has(key)) {
      const info = domainInfo(key, wikiCfg);
      groups.set(key, { key, title: info.title, summary: info.summary, order: info.order, workspaces: [] });
    }
    groups.get(key).workspaces.push(ws);
  }
  for (const group of groups.values()) group.workspaces.sort(compareWs);
  return [...groups.values()].sort((a, b) => (a.order - b.order) || a.key.localeCompare(b.key));
}

export function compareWs(a, b) {
  const c = (CATEGORY_ORDER[a.category] ?? 99) - (CATEGORY_ORDER[b.category] ?? 99);
  if (c) return c;
  const n = String(a.name).localeCompare(String(b.name));
  if (n) return n;
  return String(a.relPath).localeCompare(String(b.relPath));
}

export function orderedCategories(counts) {
  return Object.keys(CATEGORY_ORDER).filter((k) => counts[k] != null);
}

export function deployFiles() {
  const root = path.resolve(repoRoot, 'deploy');
  if (!fs.existsSync(root)) return [];
  const files = [];
  const stack = [root];
  while (stack.length) {
    const dir = stack.pop();
    if (!dir) continue;
    for (const e of safeReadDir(dir)) {
      const abs = path.join(dir, e.name);
      if (e.isDirectory()) stack.push(abs);
      if (e.isFile()) files.push(toPosix(path.relative(repoRoot, abs)));
    }
  }
  return files.sort((a, b) => a.localeCompare(b));
}

export function workspaceDocPath(ws) {
  return `workspaces/${workspaceSlug(ws.relPath)}.md`;
}

export function workspaceSlug(relPath) {
  return norm(relPath).replaceAll('/', '--').replace(/[^a-zA-Z0-9._-]/g, '-');
}

export function domainDocPath(domainKey) {
  return `domains/${domainKey}.md`;
}

export function countWorkspaceDeps(deps) {
  return Object.values(deps).filter((value) => typeof value === 'string' && value.startsWith('workspace:')).length;
}

export function scriptStage(name) {
  if (name.startsWith('dev')) return '開發';
  if (name.startsWith('build')) return '建置';
  if (name.startsWith('check') || name.startsWith('verify')) return '品質';
  if (name.startsWith('ci:')) return 'ci';
  if (name.startsWith('test:')) return '測試';
  if (name.startsWith('wiki:')) return '文件';
  return '其他';
}

export function scriptIntent(name) {
  const d = {
    'wiki:generate': '依 repo 事實重建 docs/wiki-mdx',
    'wiki:check': '檢查 docs/wiki-mdx 是否同步',
    'ci:main:gate:fast': 'Jenkins 使用的快速品質閘',
    'ci:main:gate:full': '包含 smoke 的完整品質閘',
  };
  return d[name] ?? 'Repo 工作流命令';
}

export function isKeyScript(name) {
  return name.startsWith('dev') || name.startsWith('build') || name.startsWith('check') || name.startsWith('verify') || name.startsWith('ci:') || name.startsWith('test:e2e:main') || name.startsWith('wiki:');
}

export function ciIntent(cmd) {
  if (cmd.includes('wiki:check')) return '驗證 Wiki 是否同步';
  if (cmd.includes('verify:main:config')) return '驗證主應用設定';
  if (cmd.includes('verify:repo:layout')) return '驗證 repo 目錄規範';
  if (cmd.includes('verify:repo:governance')) return '驗證治理邊界';
  if (cmd.includes('verify:main:lint')) return '執行 lint';
  if (cmd.includes('verify:main:typecheck')) return '執行型別檢查';
  if (cmd.includes('verify:main:build')) return '建置主應用';
  if (cmd.startsWith('docker build')) return '建置發布映像';
  if (cmd.startsWith('docker push')) return '推送映像到 Registry';
  if (cmd.includes('kubectl apply')) return '套用 Kubernetes 清單';
  return 'Pipeline 命令';
}

export function deployIntent(file) {
  if (file.endsWith('deploy-deployment.yaml')) return 'Kubernetes Deployment 清單';
  if (file.endsWith('deploy-service.yaml')) return 'Kubernetes Service 清單';
  if (file.endsWith('deploy-ingress.yaml')) return 'Kubernetes Ingress 清單';
  if (file.endsWith('deploy-cm.yaml')) return 'Kubernetes ConfigMap 清單';
  if (file.endsWith('Dockerfile')) return '容器建置規格';
  if (file.endsWith('nginx.conf')) return '執行期 Web Server 設定';
  return '部署相關產物';
}

export function loadWikiConfig() {
  const absPath = path.resolve(repoRoot, WIKI_CONFIG_PATH);
  let userCfg = {};
  if (fs.existsSync(absPath)) {
    try {
      const raw = fs.readFileSync(absPath, 'utf8').replace(/^\uFEFF/, '');
      userCfg = JSON.parse(raw);
    } catch (error) {
      throw new Error(`Failed to parse ${WIKI_CONFIG_PATH}: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  const cfg = {
    excludeWorkspaceNames: [...new Set([...(DEFAULT_WIKI_CONFIG.excludeWorkspaceNames ?? []), ...arr(userCfg.excludeWorkspaceNames)])],
    excludeWorkspacePaths: [...new Set([...(DEFAULT_WIKI_CONFIG.excludeWorkspacePaths ?? []), ...arr(userCfg.excludeWorkspacePaths)].map(norm))],
    sourceExtensions: [...new Set([...(DEFAULT_WIKI_CONFIG.sourceExtensions ?? []), ...arr(userCfg.sourceExtensions)].map((i) => String(i).trim()).filter(Boolean))],
    routePathPatterns: [...new Set([...(DEFAULT_WIKI_CONFIG.routePathPatterns ?? []), ...arr(userCfg.routePathPatterns)].map(norm))],
    maxSamples: {
      routes: intOr(userCfg?.maxSamples?.routes, DEFAULT_WIKI_CONFIG.maxSamples.routes),
      apiEndpoints: intOr(userCfg?.maxSamples?.apiEndpoints, DEFAULT_WIKI_CONFIG.maxSamples.apiEndpoints),
      sourceImportEdges: intOr(userCfg?.maxSamples?.sourceImportEdges, DEFAULT_WIKI_CONFIG.maxSamples.sourceImportEdges),
    },
    domainRules: [],
    defaultDomain: {
      ...DEFAULT_WIKI_CONFIG.defaultDomain,
      ...(userCfg.defaultDomain && typeof userCfg.defaultDomain === 'object' ? userCfg.defaultDomain : {}),
    },
  };

  const mergedRules = [...arr(DEFAULT_WIKI_CONFIG.domainRules), ...arr(userCfg.domainRules)];
  const seen = new Set();
  for (const item of mergedRules) {
    if (!item || typeof item !== 'object') continue;
    const key = String(item.key ?? '').trim();
    if (!key || seen.has(key)) continue;
    seen.add(key);
    cfg.domainRules.push({
      key,
      title: String(item.title ?? key),
      summary: String(item.summary ?? ''),
      order: intOr(item.order, 99),
      prefixes: arr(item.prefixes).map(norm).filter(Boolean),
    });
  }
  cfg.domainRules.sort((a, b) => (a.order - b.order) || a.key.localeCompare(b.key));
  return cfg;
}

export function isWorkspaceExcluded(ws, wikiCfg) {
  if (wikiCfg.excludeWorkspaceNames.includes(ws.name)) return true;
  if (wikiCfg.excludeWorkspacePaths.includes(norm(ws.relPath))) return true;
  return matchGlobAny(norm(ws.relPath), wikiCfg.excludeWorkspacePaths);
}

