import fs from 'node:fs';
import path from 'node:path';
import { repoRoot, wikiDir, norm, regEsc, runWithFallback } from './io.mjs';
import { globToRegExp } from './deps.mjs';

export function collectOwnership(managedRows) {
  const rules = parseCodeownersRules();
  const rows = managedRows.map((ws) => {
    const ownerRule = findCodeownerForPath(`${norm(ws.relPath)}/`, rules);
    const last = gitLastCommitInfo(ws.relPath);
    const top = gitTopContributors(ws.relPath, 3);
    return {
      workspace: ws.name,
      ownerRule: ownerRule?.owners?.join(' ') ?? '-',
      ownerPattern: ownerRule?.pattern ?? '-',
      lastCommitAuthor: last.author ?? '-',
      lastCommitDate: last.date ?? '-',
      primaryContributors: top.length ? top.map((t) => `${t.name}(${t.count})`).join(', ') : '-',
      lastCommitEpochDay: last.epochDay,
    };
  });
  const byWorkspace = new Map(rows.map((r) => [r.workspace, r]));
  return { rows, byWorkspace };
}

export function buildQualityMetrics(managedRows, depIndex, sourceInsights, ownership) {
  const rows = managedRows.map((ws) => {
    const st = sourceInsights.workspaceStats.get(ws.name) ?? {
      sourceFiles: 0,
      sourceLoc: 0,
      testFiles: 0,
      todoCount: 0,
      routeCountProd: 0,
      routeCountTest: 0,
      apiEndpointCountProd: 0,
      apiEndpointCountTest: 0,
    };
    const outDeps = (depIndex.byFrom.get(ws.name) ?? []).length;
    const inDeps = (depIndex.byTo.get(ws.name) ?? []).length;
    const own = ownership.byWorkspace.get(ws.name);
    const ageDays = own?.lastCommitEpochDay != null ? Math.max(0, epochDayNow() - own.lastCommitEpochDay) : null;

    let riskScore = 0;
    const reasons = [];
    if (st.testFiles === 0) { riskScore += 15; reasons.push('無測試檔'); }
    if (st.todoCount >= 10) { riskScore += 15; reasons.push('TODO/FIXME 偏高'); }
    else if (st.todoCount > 0) { riskScore += 5; reasons.push('存在 TODO/FIXME'); }
    if (st.sourceLoc >= 5000) { riskScore += 10; reasons.push('程式行數偏大'); }
    if (outDeps >= 12) { riskScore += 10; reasons.push('Outbound 相依偏多'); }
    if (inDeps >= 15) { riskScore += 10; reasons.push('Inbound 相依偏多'); }
    if (ws.parseMode !== 'json') { riskScore += 20; reasons.push(`解析模式 ${ws.parseMode}`); }
    if (ageDays != null && ageDays >= 180) { riskScore += 10; reasons.push(`最近提交 ${ageDays} 天前`); }

    const riskLevel = riskScore >= 35 ? 'high' : riskScore >= 20 ? 'medium' : 'low';
    return {
      workspace: ws.name,
      sourceFiles: st.sourceFiles,
      sourceLoc: st.sourceLoc,
      testFiles: st.testFiles,
      todoCount: st.todoCount,
      routeCountProd: st.routeCountProd,
      routeCountTest: st.routeCountTest,
      apiEndpointCountProd: st.apiEndpointCountProd,
      apiEndpointCountTest: st.apiEndpointCountTest,
      outboundWorkspaceDeps: outDeps,
      inboundWorkspaceDeps: inDeps,
      riskScore,
      riskLevel,
      riskReason: reasons.join('、') || '低風險訊號',
    };
  });
  rows.sort((a, b) => a.workspace.localeCompare(b.workspace));
  return { rows };
}

export function gitHeadInfo() {
  try {
    const out = execFileSync('git', ['show', '-s', '--format=%H|%h|%ad', '--date=short', 'HEAD'], {
      cwd: repoRoot,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe'],
    }).trim();
    const [hash = '', shortHash = '', commitDate = ''] = out.split('|');
    return { hash, shortHash: shortHash || hash.slice(0, 7), commitDate: commitDate || '1970-01-01' };
  } catch {
    return { hash: 'unknown', shortHash: 'unknown', commitDate: '1970-01-01' };
  }
}

export function buildCurrentSnapshot(head, managedRows, sourceInsights, quality) {
  const todoTotal = quality.rows.reduce((acc, row) => acc + row.todoCount, 0);
  const riskHigh = quality.rows.filter((row) => row.riskLevel === 'high').length;
  const riskMedium = quality.rows.filter((row) => row.riskLevel === 'medium').length;
  const riskLow = quality.rows.filter((row) => row.riskLevel === 'low').length;
  const sourceFiles = quality.rows.reduce((acc, row) => acc + row.sourceFiles, 0);

  return {
    commitHash: head.hash,
    shortHash: head.shortHash,
    commitDate: head.commitDate,
    workspaceCount: managedRows.length,
    scannedFiles: sourceInsights.scannedFiles,
    scannedProdFiles: sourceInsights.scannedProdFiles,
    scannedTestFiles: sourceInsights.scannedTestFiles,
    sourceFiles,
    sourceLoc: sourceInsights.totalLoc,
    todoTotal,
    importEdgeCount: sourceInsights.workspaceImportEdges.length,
    routeSampleProd: sourceInsights.routeSamplesProd.length,
    routeSampleTest: sourceInsights.routeSamplesTest.length,
    apiSampleProd: sourceInsights.apiEndpointSamplesProd.length,
    apiSampleTest: sourceInsights.apiEndpointSamplesTest.length,
    unresolvedWorkspaceImports: sourceInsights.unresolvedWorkspaceImports.length,
    riskHigh,
    riskMedium,
    riskLow,
  };
}

export function mergeMetricsHistory(snapshot) {
  const abs = path.resolve(wikiDir, 'metrics/history.json');
  let historyEntries = [];
  if (fs.existsSync(abs)) {
    try {
      const raw = fs.readFileSync(abs, 'utf8').replace(/^\uFEFF/, '');
      const parsed = JSON.parse(raw);
      historyEntries = arr(parsed?.entries).filter((item) => item && typeof item === 'object');
    } catch {
      historyEntries = [];
    }
  }

  const byCommit = new Map();
  for (const entry of historyEntries) {
    const hash = String(entry.commitHash ?? '').trim();
    if (!hash) continue;
    byCommit.set(hash, entry);
  }
  byCommit.set(snapshot.commitHash, snapshot);

  const entries = [...byCommit.values()]
    .map((item) => ({
      commitHash: String(item.commitHash ?? ''),
      shortHash: String(item.shortHash ?? '').trim() || String(item.commitHash ?? '').slice(0, 7),
      commitDate: String(item.commitDate ?? '1970-01-01'),
      workspaceCount: Number(item.workspaceCount ?? 0),
      scannedFiles: Number(item.scannedFiles ?? 0),
      scannedProdFiles: Number(item.scannedProdFiles ?? 0),
      scannedTestFiles: Number(item.scannedTestFiles ?? 0),
      sourceFiles: Number(item.sourceFiles ?? 0),
      sourceLoc: Number(item.sourceLoc ?? 0),
      todoTotal: Number(item.todoTotal ?? 0),
      importEdgeCount: Number(item.importEdgeCount ?? 0),
      routeSampleProd: Number(item.routeSampleProd ?? 0),
      routeSampleTest: Number(item.routeSampleTest ?? 0),
      apiSampleProd: Number(item.apiSampleProd ?? 0),
      apiSampleTest: Number(item.apiSampleTest ?? 0),
      unresolvedWorkspaceImports: Number(item.unresolvedWorkspaceImports ?? 0),
      riskHigh: Number(item.riskHigh ?? 0),
      riskMedium: Number(item.riskMedium ?? 0),
      riskLow: Number(item.riskLow ?? 0),
    }))
    .sort((a, b) => a.commitDate.localeCompare(b.commitDate) || a.commitHash.localeCompare(b.commitHash))
    .slice(-260);

  return { entries };
}

export function computeMetricsTrend(entries, currentCommitHash) {
  const idx = entries.findIndex((item) => item.commitHash === currentCommitHash);
  const current = idx >= 0 ? entries[idx] : null;
  const previous = idx > 0 ? entries[idx - 1] : null;
  const base = current ?? {
    workspaceCount: 0, sourceLoc: 0, todoTotal: 0, importEdgeCount: 0, riskHigh: 0, riskMedium: 0, riskLow: 0,
  };
  return {
    current,
    previous,
    delta: {
      workspaceCount: base.workspaceCount - (previous?.workspaceCount ?? base.workspaceCount),
      sourceLoc: base.sourceLoc - (previous?.sourceLoc ?? base.sourceLoc),
      todoTotal: base.todoTotal - (previous?.todoTotal ?? base.todoTotal),
      importEdgeCount: base.importEdgeCount - (previous?.importEdgeCount ?? base.importEdgeCount),
      riskHigh: base.riskHigh - (previous?.riskHigh ?? base.riskHigh),
      riskMedium: base.riskMedium - (previous?.riskMedium ?? base.riskMedium),
      riskLow: base.riskLow - (previous?.riskLow ?? base.riskLow),
    },
  };
}

export function parseCodeownersRules() {
  const candidates = ['CODEOWNERS', '.github/CODEOWNERS', 'docs/CODEOWNERS']
    .map((p) => path.resolve(repoRoot, p))
    .filter((p) => fs.existsSync(p));
  if (!candidates.length) return [];
  const file = candidates[0];
  const lines = fs.readFileSync(file, 'utf8').split(/\r?\n/);
  const rules = [];
  for (const line of lines) {
    const t = line.trim();
    if (!t || t.startsWith('#')) continue;
    const parts = t.split(/\s+/).filter(Boolean);
    if (parts.length < 2) continue;
    const pattern = norm(parts[0]);
    const owners = parts.slice(1);
    rules.push({ pattern, owners, regex: codeownerPatternToRegex(pattern) });
  }
  return rules;
}

export function findCodeownerForPath(relPath, rules) {
  const p = norm(relPath);
  let found = null;
  for (const rule of rules) {
    if (rule.regex.test(p)) found = rule;
  }
  return found;
}

export function codeownerPatternToRegex(pattern) {
  let p = norm(pattern);
  if (p.startsWith('/')) p = p.slice(1);
  if (p.endsWith('/')) p = `${p}**`;
  if (!p.includes('/')) p = `**/${p}`;
  return globToRegExp(p);
}

export function gitLastCommitInfo(relPath) {
  try {
    const out = execFileSync('git', ['log', '-1', '--date=short', '--pretty=format:%an|%ad', '--', relPath], {
      cwd: repoRoot,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe'],
    }).trim();
    if (!out) return {};
    const [author, date] = out.split('|');
    const epochDay = date ? Math.floor(new Date(`${date}T00:00:00Z`).getTime() / 86400000) : null;
    return { author: author ?? '', date: date ?? '', epochDay: Number.isFinite(epochDay) ? epochDay : null };
  } catch {
    return {};
  }
}

export function gitTopContributors(relPath, limit = 3) {
  try {
    const out = execFileSync('git', ['shortlog', '-sn', 'HEAD', '--', relPath], {
      cwd: repoRoot,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    const rows = [];
    for (const line of out.split(/\r?\n/)) {
      const t = line.trim();
      if (!t) continue;
      const m = /^(\d+)\s+(.+)$/.exec(t);
      if (!m) continue;
      rows.push({ count: Number(m[1]), name: m[2] });
      if (rows.length >= limit) break;
    }
    return rows;
  } catch {
    return [];
  }
}

export function epochDayNow() {
  return Math.floor(Date.now() / 86400000);
}

