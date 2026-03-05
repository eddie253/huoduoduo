import fs from 'node:fs';
import path from 'node:path';
import { repoRoot, norm, toPosix, safeReadDir } from './io.mjs';

export function scanSourceInsights(managedRows, workspaceByName, wikiCfg) {
  const extSet = new Set(wikiCfg.sourceExtensions.map((ext) => ext.toLowerCase()));
  const importCount = new Map();
  const unresolvedMap = new Map();
  const routeMapProd = new Map();
  const routeMapTest = new Map();
  const apiMapProd = new Map();
  const apiMapTest = new Map();
  const stats = new Map();
  const maxRoutes = wikiCfg.maxSamples.routes;
  const maxApi = wikiCfg.maxSamples.apiEndpoints;

  let scannedFiles = 0;
  let scannedProdFiles = 0;
  let scannedTestFiles = 0;
  let totalLoc = 0;
  let apiAuthSignalProd = 0;
  let apiPublicSignalProd = 0;
  let apiUnknownSignalProd = 0;
  let apiAuthSignalTest = 0;
  let apiPublicSignalTest = 0;
  let apiUnknownSignalTest = 0;
  let apiMiddlewareMarkedProd = 0;
  let apiMiddlewareUnmarkedProd = 0;
  let apiMiddlewareMarkedTest = 0;
  let apiMiddlewareUnmarkedTest = 0;

  for (const ws of managedRows) {
    stats.set(ws.name, {
      sourceFiles: 0,
      sourceLoc: 0,
      testFiles: 0,
      todoCount: 0,
      routeCountProd: 0,
      routeCountTest: 0,
      apiEndpointCountProd: 0,
      apiEndpointCountTest: 0,
    });
    const files = listWorkspaceSourceFiles(ws.relPath, extSet);
    for (const relFile of files) {
      scannedFiles += 1;
      const isTestFile = isLikelyTestFile(relFile);
      if (isTestFile) scannedTestFiles += 1;
      else scannedProdFiles += 1;

      const raw = fs.readFileSync(path.resolve(repoRoot, relFile), 'utf8');
      const loc = lineCount(raw);
      totalLoc += loc;

      const st = stats.get(ws.name);
      if (!st) continue;
      st.sourceFiles += 1;
      st.sourceLoc += loc;
      if (isTestFile) st.testFiles += 1;
      st.todoCount += countTodo(raw);
      const ownerModule = inferOwnerModule(relFile);

      const specs = extractModuleSpecs(raw);
      for (const specRaw of specs) {
        const target = asWorkspaceModuleSpec(specRaw, workspaceByName);
        if (target && target !== ws.name) {
          const k = `${ws.name}\u0000${target}`;
          if (!importCount.has(k)) {
            importCount.set(k, { from: ws.name, to: target, count: 0, prodCount: 0, testCount: 0 });
          }
          const entry = importCount.get(k);
          if (!entry) continue;
          entry.count += 1;
          if (isTestFile) entry.testCount += 1;
          else entry.prodCount += 1;
          continue;
        }
        if (looksLikeInternalPackageSpec(specRaw)) {
          const k = `${ws.name}\u0000${specRaw}\u0000${relFile}`;
          if (!unresolvedMap.has(k)) unresolvedMap.set(k, { workspace: ws.name, spec: specRaw, file: relFile });
        }
      }

      if (matchesAnyPath(relFile, wikiCfg.routePathPatterns)) {
        for (const routePath of extractRoutePaths(raw)) {
          if (isTestFile) st.routeCountTest += 1;
          else st.routeCountProd += 1;
          if (!isTestFile && routeMapProd.size < maxRoutes) {
            const k = `${ws.name}\u0000${routePath}\u0000${relFile}`;
            if (!routeMapProd.has(k)) routeMapProd.set(k, { workspace: ws.name, path: routePath, file: relFile });
          }
          if (isTestFile && routeMapTest.size < maxRoutes) {
            const k = `${ws.name}\u0000${routePath}\u0000${relFile}`;
            if (!routeMapTest.has(k)) routeMapTest.set(k, { workspace: ws.name, path: routePath, file: relFile });
          }
        }
      }

      for (const api of extractApiEndpoints(raw, { relFile, isTestFile })) {
        if (isTestFile) st.apiEndpointCountTest += 1;
        else st.apiEndpointCountProd += 1;

        if (isTestFile) {
          if (api.authMarker === 'auth-signal') apiAuthSignalTest += 1;
          else if (api.authMarker === 'public-signal') apiPublicSignalTest += 1;
          else apiUnknownSignalTest += 1;
          if (api.authMiddleware !== '-') apiMiddlewareMarkedTest += 1;
          else apiMiddlewareUnmarkedTest += 1;
        } else {
          if (api.authMarker === 'auth-signal') apiAuthSignalProd += 1;
          else if (api.authMarker === 'public-signal') apiPublicSignalProd += 1;
          else apiUnknownSignalProd += 1;
          if (api.authMiddleware !== '-') apiMiddlewareMarkedProd += 1;
          else apiMiddlewareUnmarkedProd += 1;
        }

        if (!isTestFile && apiMapProd.size < maxApi) {
          const k = `${ws.name}\u0000${api.method}\u0000${api.endpoint}\u0000${relFile}\u0000${api.caller}`;
          if (!apiMapProd.has(k)) apiMapProd.set(k, {
            workspace: ws.name,
            method: api.method,
            endpoint: api.endpoint,
            caller: api.caller,
            ownerModule,
            authMarker: api.authMarker,
            authMiddleware: api.authMiddleware,
            authSignals: api.authSignals,
            file: relFile,
          });
        }
        if (isTestFile && apiMapTest.size < maxApi) {
          const k = `${ws.name}\u0000${api.method}\u0000${api.endpoint}\u0000${relFile}\u0000${api.caller}`;
          if (!apiMapTest.has(k)) apiMapTest.set(k, {
            workspace: ws.name,
            method: api.method,
            endpoint: api.endpoint,
            caller: api.caller,
            ownerModule,
            authMarker: api.authMarker,
            authMiddleware: api.authMiddleware,
            authSignals: api.authSignals,
            file: relFile,
          });
        }
      }
    }
  }

  const workspaceImportEdges = [...importCount.values()]
    .sort((a, b) => a.from.localeCompare(b.from) || a.to.localeCompare(b.to));

  const unresolvedWorkspaceImports = [...unresolvedMap.values()]
    .sort((a, b) => a.workspace.localeCompare(b.workspace) || a.spec.localeCompare(b.spec) || a.file.localeCompare(b.file));
  const routeSamplesProd = [...routeMapProd.values()]
    .sort((a, b) => a.workspace.localeCompare(b.workspace) || a.path.localeCompare(b.path) || a.file.localeCompare(b.file));
  const routeSamplesTest = [...routeMapTest.values()]
    .sort((a, b) => a.workspace.localeCompare(b.workspace) || a.path.localeCompare(b.path) || a.file.localeCompare(b.file));
  const apiEndpointSamplesProd = [...apiMapProd.values()]
    .sort((a, b) => a.workspace.localeCompare(b.workspace) || a.endpoint.localeCompare(b.endpoint) || a.file.localeCompare(b.file));
  const apiEndpointSamplesTest = [...apiMapTest.values()]
    .sort((a, b) => a.workspace.localeCompare(b.workspace) || a.endpoint.localeCompare(b.endpoint) || a.file.localeCompare(b.file));

  return {
    scannedFiles,
    scannedProdFiles,
    scannedTestFiles,
    totalLoc,
    workspaceStats: stats,
    workspaceImportEdges,
    unresolvedWorkspaceImports,
    routeSamplesProd,
    routeSamplesTest,
    apiEndpointSamplesProd,
    apiEndpointSamplesTest,
    apiAuthSignalProd,
    apiPublicSignalProd,
    apiUnknownSignalProd,
    apiAuthSignalTest,
    apiPublicSignalTest,
    apiUnknownSignalTest,
    apiMiddlewareMarkedProd,
    apiMiddlewareUnmarkedProd,
    apiMiddlewareMarkedTest,
    apiMiddlewareUnmarkedTest,
  };
}

export function listWorkspaceSourceFiles(workspaceRelPath, extSet) {
  const root = path.resolve(repoRoot, workspaceRelPath);
  if (!fs.existsSync(root)) return [];
  const out = [];
  const skipDirs = new Set(['node_modules', '.git', 'dist', 'build', 'coverage', 'output', '.turbo', '.qoder', 'target', '.pnpm-store']);
  const stack = [root];
  while (stack.length) {
    const dir = stack.pop();
    if (!dir) continue;
    for (const entry of safeReadDir(dir)) {
      const abs = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        if (!skipDirs.has(entry.name)) stack.push(abs);
        continue;
      }
      if (!entry.isFile()) continue;
      const ext = path.extname(entry.name).toLowerCase();
      if (!extSet.has(ext)) continue;
      out.push(toPosix(path.relative(repoRoot, abs)));
    }
  }
  out.sort((a, b) => a.localeCompare(b));
  return out;
}

export function extractModuleSpecs(raw) {
  const specs = new Set();
  const patterns = [
    /\bimport\s+[^'"]*?\s+from\s*['"]([^'"]+)['"]/g,
    /\bexport\s+[^'"]*?\s+from\s*['"]([^'"]+)['"]/g,
    /\brequire\s*\(\s*['"]([^'"]+)['"]\s*\)/g,
    /\bimport\s*\(\s*['"]([^'"]+)['"]\s*\)/g,
  ];
  for (const reg of patterns) {
    reg.lastIndex = 0;
    let m = reg.exec(raw);
    while (m) {
      const spec = String(m[1] ?? '').trim();
      if (spec) specs.add(spec);
      m = reg.exec(raw);
    }
  }
  return [...specs].sort((a, b) => a.localeCompare(b));
}

export function asWorkspaceModuleSpec(spec, workspaceByName) {
  if (workspaceByName.has(spec)) return spec;
  const maybe = moduleNameOf(spec);
  if (maybe && workspaceByName.has(maybe)) return maybe;
  return null;
}

export function moduleNameOf(spec) {
  const s = String(spec ?? '').trim();
  if (!s) return null;
  if (s.startsWith('@')) {
    const parts = s.split('/');
    return parts.length >= 2 ? `${parts[0]}/${parts[1]}` : s;
  }
  const parts = s.split('/');
  return parts[0] || null;
}

export function looksLikeInternalPackageSpec(spec) {
  const s = String(spec ?? '').trim();
  return s.startsWith('@jnpf/') || s.startsWith('@vben') || s.startsWith('@repo/');
}

export function extractRoutePaths(raw) {
  const out = new Set();
  const reg = /\bpath\s*:\s*['"`]([^'"`\r\n]+)['"`]/g;
  let m = reg.exec(raw);
  while (m) {
    const value = String(m[1] ?? '').trim();
    if (value.startsWith('/')) out.add(value);
    m = reg.exec(raw);
  }
  return [...out].sort((a, b) => a.localeCompare(b));
}

export function extractApiEndpoints(raw, options = {}) {
  const relFile = String(options?.relFile ?? '');
  const isTestFile = Boolean(options?.isTestFile);
  const out = new Map();
  const seenEndpoint = new Set();
  const add = (method, endpoint, index) => {
    const m = String(method ?? 'UNKNOWN').toUpperCase();
    const e = String(endpoint ?? '').trim();
    if (!e.startsWith('/api/')) return;
    const caller = findNearestFunctionName(raw, index);
    const auth = detectAuthMarker(raw, index, e, relFile, isTestFile);
    const key = `${m}\u0000${e}\u0000${caller}`;
    if (!out.has(key)) {
      out.set(key, {
        method: m,
        endpoint: e,
        caller,
        authMarker: auth.marker,
        authMiddleware: auth.middleware,
        authSignals: auth.signals.join(', ') || '-',
      });
    }
    seenEndpoint.add(e);
  };

  const callReg = /\.\s*(get|post|put|delete|patch|options|head)\s*\(\s*['"`](\/api\/[^'"`\s?#]*)['"`]/gi;
  let m = callReg.exec(raw);
  while (m) {
    add(m[1], m[2], m.index);
    m = callReg.exec(raw);
  }

  const objReg1 = /method\s*:\s*['"`](get|post|put|delete|patch|options|head)['"`][^}]*?url\s*:\s*['"`](\/api\/[^'"`\s?#]*)['"`]/gis;
  m = objReg1.exec(raw);
  while (m) {
    add(m[1], m[2], m.index);
    m = objReg1.exec(raw);
  }

  const objReg2 = /url\s*:\s*['"`](\/api\/[^'"`\s?#]*)['"`][^}]*?method\s*:\s*['"`](get|post|put|delete|patch|options|head)['"`]/gis;
  m = objReg2.exec(raw);
  while (m) {
    add(m[2], m[1], m.index);
    m = objReg2.exec(raw);
  }

  const fallback = /['"`](\/api\/[^'"`\s?#]*)['"`]/g;
  m = fallback.exec(raw);
  while (m) {
    const endpoint = String(m[1] ?? '').trim();
    if (!seenEndpoint.has(endpoint)) add('UNKNOWN', endpoint, m.index);
    m = fallback.exec(raw);
  }

  return [...out.values()].sort((a, b) => a.endpoint.localeCompare(b.endpoint) || a.method.localeCompare(b.method) || a.caller.localeCompare(b.caller));
}

export function findNearestFunctionName(raw, index) {
  const head = raw.slice(0, Math.max(0, index));
  const patterns = [
    /function\s+([A-Za-z_$][\w$]*)\s*\(/g,
    /(?:const|let|var)\s+([A-Za-z_$][\w$]*)\s*=\s*(?:async\s*)?\([^)]*\)\s*=>/g,
    /(?:const|let|var)\s+([A-Za-z_$][\w$]*)\s*=\s*(?:async\s*)?function\b/g,
    /([A-Za-z_$][\w$]*)\s*:\s*(?:async\s*)?\([^)]*\)\s*=>/g,
    /([A-Za-z_$][\w$]*)\s*:\s*(?:async\s*)?function\b/g,
  ];
  let best = null;
  for (const reg of patterns) {
    reg.lastIndex = 0;
    let m = reg.exec(head);
    while (m) {
      const name = String(m[1] ?? '').trim();
      if (name) best = { name, idx: m.index };
      m = reg.exec(head);
    }
  }
  return best?.name ?? '(top-level)';
}

export function detectAuthMarker(raw, index, endpoint, relFile = '', isTestFile = false) {
  const start = Math.max(0, index - 300);
  const end = Math.min(raw.length, index + 300);
  const local = raw.slice(start, end);
  const filePrefix = raw.slice(0, Math.min(raw.length, 1000));
  const signals = [];
  const middlewares = [];
  const addSignal = (flag, label) => { if (flag && !signals.includes(label)) signals.push(label); };
  const addMiddleware = (flag, label) => { if (flag && !middlewares.includes(label)) middlewares.push(label); };

  addSignal(/authorization/i.test(local), 'Authorization');
  addSignal(/bearer/i.test(local), 'Bearer');
  addSignal(/\b(access|refresh)?token\b/i.test(local), 'token');
  addSignal(/useUserStore|getAccessToken|setAccessToken|useAccessToken/i.test(local), 'auth-store');
  addSignal(/auth/i.test(endpoint), 'endpoint-auth');
  addSignal(/login|logout|captcha|public|sso|oauth/i.test(endpoint), 'public-endpoint');
  addSignal(/authorization|bearer|token/i.test(filePrefix), 'file-auth-import');

  addMiddleware(/\binterceptors?\s*\.\s*request\s*\.\s*use\b/i.test(raw), 'axios-request-interceptor');
  addMiddleware(/\binterceptors?\s*\.\s*response\s*\.\s*use\b/i.test(raw), 'axios-response-interceptor');
  addMiddleware(/\bheaders?\s*:\s*\{[^}]*authorization/i.test(local) || /\b(setRequestHeaders|setToken)\b/i.test(local), 'header-token-injector');
  addMiddleware(/\buseUserStore|getAccessToken|setAccessToken|useAccessToken\b/i.test(raw), 'auth-store-helper');
  addMiddleware(/\bbeforeEach\s*\(/i.test(raw) && /router|guard/i.test(relFile), 'router-guard');
  addMiddleware(isTestFile || /\bmock\b/i.test(relFile), 'test-mock');

  const hasAuthSignal = signals.includes('Authorization')
    || signals.includes('Bearer')
    || signals.includes('token')
    || signals.includes('auth-store')
    || signals.includes('file-auth-import');
  const hasPublicSignal = signals.includes('public-endpoint');
  const hasAuthMiddleware = middlewares.some((m) => m !== 'test-mock');
  const middleware = middlewares.length ? middlewares.join(', ') : '-';

  if (hasAuthSignal || hasAuthMiddleware) return { marker: 'auth-signal', middleware, signals };
  if (hasPublicSignal) return { marker: 'public-signal', middleware, signals };
  return { marker: 'unknown', middleware, signals };
}

export function inferOwnerModule(relFile) {
  const p = norm(relFile);
  const idx = p.indexOf('/src/');
  if (idx < 0) return path.dirname(p);
  const sub = p.slice(idx + '/src/'.length);
  const parts = sub.split('/').filter(Boolean);
  if (!parts.length) return '(src-root)';
  if (parts[0] === 'api') {
    if (parts.length >= 3) return `api/${parts[1]}`;
    if (parts.length >= 2) return `api/${stripCodeFileSuffix(parts[1])}`;
    return 'api';
  }
  if (parts.length >= 2) return `${parts[0]}/${stripCodeFileSuffix(parts[1])}`;
  return parts[0];
}

export function stripCodeFileSuffix(name) {
  return String(name ?? '')
    .replace(/\.[a-z0-9]+$/i, '')
    .replace(/\.(test|spec)$/i, '');
}

export function matchesAnyPath(relPath, patterns) {
  const p = norm(relPath);
  return patterns.some((pattern) => p.includes(norm(pattern)));
}

export function isLikelyTestFile(relPath) {
  const p = norm(relPath);
  const base = path.basename(p);
  return p.includes('/__tests__/') || /\.test\.[a-z0-9]+$/i.test(base) || /\.spec\.[a-z0-9]+$/i.test(base);
}

export function lineCount(raw) {
  if (!raw) return 0;
  return raw.split(/\r?\n/).length;
}

export function countTodo(raw) {
  const matches = raw.match(/\b(TODO|FIXME|HACK)\b/gi);
  return matches ? matches.length : 0;
}

