import { execSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
export const repoRoot = path.resolve(scriptDir, '..', '..', '..');
export const wikiDir = path.resolve(repoRoot, 'docs/wiki');
export const GENERATED_MARKER = '<!-- AUTO-GENERATED: Do not edit manually. Use `pnpm run wiki:generate`. -->';

export function wikiLink(repoPath, fromDocFile = 'README.md') {
  const fromDir = path.dirname(path.resolve(wikiDir, fromDocFile));
  let rel = toPosix(path.relative(fromDir, path.resolve(repoRoot, repoPath)));
  if (!rel.startsWith('.')) rel = `./${rel}`;
  return rel;
}

export function wikiDocLink(fromDocFile, targetDocFile) {
  const fromDir = path.dirname(path.resolve(wikiDir, fromDocFile));
  let rel = toPosix(path.relative(fromDir, path.resolve(wikiDir, targetDocFile)));
  if (!rel.startsWith('.')) rel = `./${rel}`;
  return rel;
}

export function listGeneratedWikiFiles() {
  if (!fs.existsSync(wikiDir)) return [];
  const files = [];
  const stack = [wikiDir];
  while (stack.length) {
    const dir = stack.pop();
    if (!dir) continue;
    for (const entry of safeReadDir(dir)) {
      const abs = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        stack.push(abs);
        continue;
      }
      if (!entry.isFile() || !entry.name.endsWith('.md')) continue;
      const raw = fs.readFileSync(abs, 'utf8');
      if (!raw.startsWith(GENERATED_MARKER)) continue;
      files.push(toPosix(path.relative(wikiDir, abs)));
    }
  }
  return files.sort((a, b) => a.localeCompare(b));
}

export function table(headers, rows) {
  const out = [];
  out.push(`| ${headers.map(cell).join(' | ')} |`);
  out.push(`| ${headers.map(() => '---').join(' | ')} |`);
  for (const r of rows) out.push(`| ${r.map(cell).join(' | ')} |`);
  return out;
}

export function cell(v) {
  return String(v ?? '-').replaceAll('|', '\\|').replaceAll('\n', '<br/>');
}

export function countBy(items, keyFn) {
  const m = {};
  for (const i of items) {
    const k = keyFn(i);
    m[k] = (m[k] ?? 0) + 1;
  }
  return m;
}

export function listOrDash(v) {
  return Array.isArray(v) && v.length ? v.join(', ') : '-';
}

export function mLabel(v) { return String(v).replaceAll('"', '\\"'); }

export function runWithFallback(cmds) {
  let lastErr = null;
  for (const cmd of cmds) {
    try {
      return execSync(cmd, { cwd: repoRoot, encoding: 'utf8', shell: true, stdio: ['ignore', 'pipe', 'pipe'] });
    } catch (e) {
      lastErr = e;
      if (!notFound(e)) break;
    }
  }
  if (lastErr) throw lastErr;
  throw new Error('No command candidates available.');
}

export function notFound(err) {
  if (!err || typeof err !== 'object') return false;
  const code = err.code;
  if (code === 'ENOENT' || code === 'UNKNOWN') return true;
  const stderr = String(err.stderr ?? '').toLowerCase();
  return stderr.includes('not recognized') || stderr.includes('not found');
}

export function readJson(rel) {
  const raw = fs.readFileSync(path.resolve(repoRoot, rel), 'utf8');
  const normalized = raw.charCodeAt(0) === 0xfeff ? raw.slice(1) : raw;
  return JSON.parse(normalized);
}

export function strMap(v) {
  if (!v || typeof v !== 'object' || Array.isArray(v)) return {};
  const out = {};
  for (const [k, val] of Object.entries(v)) if (typeof val === 'string') out[k] = val;
  return out;
}

export function matchString(raw, key) {
  const m = new RegExp(`\"${regEsc(key)}\"\\s*:\\s*\"([^\"]*)\"`).exec(raw);
  return m ? m[1] : null;
}

export function matchBool(raw, key) {
  const m = new RegExp(`\"${regEsc(key)}\"\\s*:\\s*(true|false)`).exec(raw);
  return m ? m[1] === 'true' : null;
}

export function matchObject(raw, key) {
  const start = new RegExp(`\"${regEsc(key)}\"\\s*:\\s*\\{`).exec(raw);
  if (!start) return {};
  const i0 = raw.indexOf('{', start.index);
  if (i0 < 0) return {};

  let depth = 0;
  let inStr = false;
  let esc = false;
  for (let i = i0; i < raw.length; i += 1) {
    const ch = raw[i];
    if (inStr) {
      if (esc) { esc = false; continue; }
      if (ch === '\\') { esc = true; continue; }
      if (ch === '"') inStr = false;
      continue;
    }
    if (ch === '"') { inStr = true; continue; }
    if (ch === '{') { depth += 1; continue; }
    if (ch === '}') {
      depth -= 1;
      if (depth === 0) {
        const body = raw.slice(i0 + 1, i);
        const out = {};
        const r = /\"([^\"]+)\"\\s*:\\s*\"([^\"]*)\"/g;
        let m = r.exec(body);
        while (m) { out[m[1]] = m[2]; m = r.exec(body); }
        return out;
      }
    }
  }
  return {};
}

export function normalize(s) { return String(s).replaceAll('\r\n', '\n').replaceAll('\r', '\n').replace(/\s*$/, '\n'); }

export function normalizeDrive(p) { return path.normalize(p).toLowerCase(); }

export function norm(p) { return toPosix(String(p ?? '').trim()); }

export function toPosix(p) { return String(p).replaceAll('\\', '/'); }

export function safeReadDir(abs) { try { return fs.readdirSync(abs, { withFileTypes: true }); } catch { return []; } }

export function unquote(v) { const t = v.trim(); return ((t.startsWith('"') && t.endsWith('"')) || (t.startsWith("'") && t.endsWith("'"))) ? t.slice(1, -1) : t; }

export function regEsc(v) { return String(v).replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); }

export function arr(v) {
  return Array.isArray(v) ? v : [];
}

export function intOr(v, d) {
  const n = Number(v);
  return Number.isFinite(n) && n > 0 ? Math.floor(n) : d;
}

export function fmtDelta(n) {
  const value = Number(n ?? 0);
  if (!Number.isFinite(value) || value === 0) return '0';
  return value > 0 ? `+${value}` : `${value}`;
}

