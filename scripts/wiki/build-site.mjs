#!/usr/bin/env node

import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';
import { compile, run } from '@mdx-js/mdx';
import remarkGfm from 'remark-gfm';
import * as runtime from 'react/jsx-runtime';
import { renderToStaticMarkup } from 'react-dom/server';

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(scriptDir, '..', '..');
const mdxDir = path.resolve(repoRoot, 'docs/wiki-mdx');
const siteDir = path.resolve(repoRoot, 'apps/public/wiki-site');
const legacySiteDir = path.resolve(repoRoot, 'docs/wiki-site');
const generatedMarker = '<!-- AUTO-GENERATED: Do not edit manually. Use `pnpm run wiki:build:site`. -->';
const isCheckMode = process.argv.includes('--check');
const syncMainPublic = process.argv.includes('--sync-main-public');

await main();

async function main() {
  if (!fs.existsSync(mdxDir)) {
    console.error('wiki:site 失敗：找不到 docs/wiki-mdx，請先執行 `pnpm run wiki:generate`。');
    process.exit(1);
  }

  const mdxFiles = listFiles(mdxDir, '.mdx').filter((rel) => !rel.startsWith('en-US/'));
  const pageMeta = mdxFiles.map((rel) => {
    const absPath = path.resolve(mdxDir, rel);
    const raw = fs.readFileSync(absPath, 'utf8');
    const { frontmatter, content } = splitFrontmatter(raw);
    const title = String(frontmatter.title ?? extractTitle(content, rel));
    const fileMtimeIso = fs.statSync(absPath).mtime.toISOString();
    const fallbackIso = String(frontmatter.last_synced_utc ?? fileMtimeIso);
    const gitDates = getGitFileDates(toPosix(path.relative(repoRoot, absPath)));
    return {
      rel,
      title,
      raw: content,
      publishedAt: gitDates?.first ?? fallbackIso,
      updatedAt: latestIsoDate(gitDates?.last, fallbackIso, fileMtimeIso),
    };
  });

  const expected = new Map();
  for (const page of pageMeta) {
    const html = await renderPage(page, pageMeta);
    expected.set(page.rel.replace(/\.mdx$/i, '.html'), normalize(html));
  }

  const stale = listGeneratedHtmlFiles(siteDir).filter((rel) => !expected.has(rel));
  if (isCheckMode) {
    const drift = [];
    for (const [rel, html] of expected.entries()) {
      const abs = path.resolve(siteDir, rel);
      if (!fs.existsSync(abs)) {
        drift.push(`${rel}: missing`);
        continue;
      }
      const actual = normalize(fs.readFileSync(abs, 'utf8'));
      if (actual !== html) drift.push(`${rel}: outdated`);
    }
    for (const rel of stale) drift.push(`${rel}: stale-generated-file`);
    if (drift.length > 0) {
      console.error('wiki:site:check 失敗：apps/public/wiki-site 與目前 MDX 文件不同步。');
      for (const item of drift) console.error(`- ${item}`);
      console.error('\n請執行 `pnpm run wiki:build:site` 更新前端 wiki 靜態頁。');
      process.exit(1);
    }
    console.log('wiki:site:check 通過：apps/public/wiki-site 已與 docs/wiki-mdx 同步。');
    return;
  }

  fs.mkdirSync(siteDir, { recursive: true });
  for (const rel of stale) fs.unlinkSync(path.resolve(siteDir, rel));
  for (const [rel, html] of expected.entries()) {
    const abs = path.resolve(siteDir, rel);
    fs.mkdirSync(path.dirname(abs), { recursive: true });
    fs.writeFileSync(abs, html, 'utf8');
  }

  if (fs.existsSync(legacySiteDir)) {
    fs.rmSync(legacySiteDir, { recursive: true, force: true });
  }

  console.log(`wiki:site 完成：已更新 apps/public/wiki-site 下 ${expected.size} 份 HTML。`);
  if (syncMainPublic) {
    console.log('wiki:site 相容模式：`--sync-main-public` 旗標已無需額外同步，輸出目錄已直接指向 apps/public/wiki-site。');
  }
}

async function renderPage(page, allPages) {
  const compiled = await compile(stripHtmlComments(page.raw), {
    format: 'md',
    outputFormat: 'function-body',
    development: false,
    remarkPlugins: [remarkGfm],
  });
  const mod = await run(compiled, { ...runtime, baseUrl: import.meta.url });
  const MDXContent = mod.default;
  const bodyHtml = rewriteMdxLinks(renderToStaticMarkup(MDXContent({})));
  const navHtml = buildNavHtml(allPages, page.rel);
  const relForDisplay = toPosix(page.rel);
  const publishedText = formatDateForMeta(page.publishedAt);
  const updatedText = formatDateForMeta(page.updatedAt);
  return `<!doctype html>
<html lang="zh-Hant">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>${escapeHtml(page.title)} | Monorepo Wiki</title>
    <style>
      :root {
        --bg: #f6f8fc;
        --panel: #ffffff;
        --text: #1c2333;
        --muted: #5a6475;
        --line: #d8deea;
        --accent: #0f6adf;
        --accent-soft: #e9f2ff;
      }
      * { box-sizing: border-box; }
      html, body { margin: 0; padding: 0; background: var(--bg); color: var(--text); font-family: "Noto Sans TC", "Microsoft JhengHei", sans-serif; }
      a { color: var(--accent); text-decoration: none; }
      a:hover { text-decoration: underline; }
      .layout { display: grid; grid-template-columns: 320px 1fr; min-height: 100vh; }
      .sidebar { border-right: 1px solid var(--line); background: var(--panel); padding: 16px; overflow: auto; position: sticky; top: 0; height: 100vh; }
      .sidebar h1 { font-size: 16px; margin: 0 0 12px; }
      .sidebar h2 { font-size: 13px; margin: 14px 0 6px; color: var(--muted); font-weight: 700; text-transform: uppercase; letter-spacing: 0.04em; }
      .sidebar ul { margin: 0; padding-left: 16px; }
      .sidebar li { margin: 4px 0; }
      .sidebar a.active { font-weight: 700; color: #0b4fad; background: var(--accent-soft); padding: 2px 6px; border-radius: 6px; display: inline-block; }
      .main { padding: 28px 40px 48px; }
      .meta { color: var(--muted); font-size: 13px; margin: 0 0 18px; }
      article { background: var(--panel); border: 1px solid var(--line); border-radius: 12px; padding: 22px 24px; overflow-wrap: anywhere; }
      article h1:first-child { margin-top: 0; }
      article table { border-collapse: collapse; width: 100%; display: block; overflow: auto; }
      article th, article td { border: 1px solid var(--line); padding: 6px 8px; text-align: left; font-size: 14px; }
      article th { background: #f2f5fb; }
      article code { background: #eef2fb; padding: 0.1em 0.3em; border-radius: 4px; }
      article pre { background: #10172a; color: #e7ecf7; padding: 12px; border-radius: 8px; overflow: auto; }
      article pre code { background: transparent; padding: 0; }
      article .mermaid { background: #ffffff; border: 1px solid var(--line); border-radius: 8px; padding: 8px; overflow: auto; }
      @media (max-width: 1024px) {
        .layout { grid-template-columns: 1fr; }
        .sidebar { position: static; height: auto; border-right: 0; border-bottom: 1px solid var(--line); }
        .main { padding: 16px; }
      }
    </style>
  </head>
  <body>
    ${generatedMarker}
    <div class="layout">
      <aside class="sidebar">
        <h1>Monorepo Wiki</h1>
        ${navHtml}
      </aside>
      <main class="main">
        <p class="meta">${escapeHtml(relForDisplay)}<br />建立日期：${escapeHtml(publishedText)} ｜ 最後修改：${escapeHtml(updatedText)}</p>
        <article>${bodyHtml}</article>
      </main>
    </div>
    <script type="module">
      import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';
      const blocks = [...document.querySelectorAll('pre > code')]
        .filter((code) => code.className.includes('language-mermaid'));

      for (const code of blocks) {
        const pre = code.parentElement;
        if (!pre) continue;
        const container = document.createElement('div');
        container.className = 'mermaid';
        container.textContent = code.textContent ?? '';
        pre.replaceWith(container);
      }

      if (document.querySelector('.mermaid')) {
        mermaid.initialize({ startOnLoad: false, securityLevel: 'loose', theme: 'default' });
        await mermaid.run({ querySelector: '.mermaid' });
      }
    </script>
  </body>
</html>
`;
}

function stripHtmlComments(source) {
  return String(source).replace(/<!--[\s\S]*?-->\s*/g, '');
}

function buildNavHtml(allPages, currentRel) {
  const groups = new Map();
  for (const p of allPages) {
    const dir = path.posix.dirname(toPosix(p.rel));
    const key = dir === '.' ? 'root' : dir;
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key).push(p);
  }
  const groupKeys = [...groups.keys()].sort((a, b) => {
    if (a === 'root') return -1;
    if (b === 'root') return 1;
    return a.localeCompare(b);
  });

  const sections = [];
  for (const key of groupKeys) {
    const title = key === 'root' ? 'Root' : key;
    const pages = groups.get(key).slice().sort((a, b) => a.rel.localeCompare(b.rel));
    const items = pages.map((p) => {
      const href = relHref(currentRel, p.rel.replace(/\.mdx$/i, '.html'));
      const active = toPosix(p.rel) === toPosix(currentRel) ? ' class="active"' : '';
      return `<li><a${active} href="${escapeHtml(href)}">${escapeHtml(p.title)}</a></li>`;
    }).join('');
    sections.push(`<h2>${escapeHtml(title)}</h2><ul>${items}</ul>`);
  }
  return sections.join('');
}

function rewriteMdxLinks(html) {
  return html.replace(/href="([^"]+)"/g, (full, hrefRaw) => {
    const href = String(hrefRaw);
    if (href.startsWith('#') || /^[a-z]+:\/\//i.test(href) || href.startsWith('mailto:')) return full;
    const rewritten = href.replace(/\.mdx(?=(#|$))/gi, '.html');
    return `href="${escapeHtml(rewritten)}"`;
  });
}

function relHref(fromRelMdx, toRelHtml) {
  const fromDir = path.posix.dirname(toPosix(fromRelMdx).replace(/\.mdx$/i, '.html'));
  let rel = path.posix.relative(fromDir, toPosix(toRelHtml));
  if (!rel.startsWith('.')) rel = `./${rel}`;
  return rel;
}

function splitFrontmatter(raw) {
  if (!raw.startsWith('---\n')) return { frontmatter: {}, content: raw };
  const end = raw.indexOf('\n---\n', 4);
  if (end < 0) return { frontmatter: {}, content: raw };
  const block = raw.slice(4, end);
  const content = raw.slice(end + 5);
  const frontmatter = {};
  for (const line of block.split(/\r?\n/)) {
    const m = line.match(/^([A-Za-z0-9_-]+)\s*:\s*(.*)$/);
    if (!m) continue;
    let value = m[2].trim();
    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    }
    if (value === 'true') frontmatter[m[1]] = true;
    else if (value === 'false') frontmatter[m[1]] = false;
    else frontmatter[m[1]] = value;
  }
  return { frontmatter, content };
}

function extractTitle(content, rel) {
  const heading = content.match(/^#\s+(.+)$/m);
  if (heading?.[1]) return heading[1].trim();
  return path.posix.basename(toPosix(rel), '.mdx');
}

function listGeneratedHtmlFiles(rootDir) {
  if (!fs.existsSync(rootDir)) return [];
  const out = [];
  const stack = [rootDir];
  while (stack.length) {
    const dir = stack.pop();
    if (!dir) continue;
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const abs = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        stack.push(abs);
        continue;
      }
      if (!entry.isFile() || !entry.name.endsWith('.html')) continue;
      const raw = fs.readFileSync(abs, 'utf8');
      if (!raw.includes(generatedMarker)) continue;
      out.push(toPosix(path.relative(rootDir, abs)));
    }
  }
  return out.sort((a, b) => a.localeCompare(b));
}

function listFiles(root, ext) {
  const out = [];
  const stack = [root];
  while (stack.length) {
    const dir = stack.pop();
    if (!dir) continue;
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const abs = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        stack.push(abs);
        continue;
      }
      if (!entry.isFile() || !entry.name.endsWith(ext)) continue;
      out.push(toPosix(path.relative(root, abs)));
    }
  }
  return out.sort((a, b) => a.localeCompare(b));
}

function escapeHtml(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
}

function getGitFileDates(relPath) {
  const result = spawnSync(
    'git',
    ['log', '--follow', '--format=%cI', '--', relPath],
    { cwd: repoRoot, encoding: 'utf8' },
  );
  if (result.status !== 0) return null;

  const lines = String(result.stdout ?? '')
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);

  if (lines.length === 0) return null;
  return {
    last: lines[0],
    first: lines.at(-1),
  };
}

function formatDateForMeta(value) {
  const date = new Date(String(value ?? ''));
  if (Number.isNaN(date.valueOf())) return 'n/a';

  const year = date.getUTCFullYear();
  const month = String(date.getUTCMonth() + 1).padStart(2, '0');
  const day = String(date.getUTCDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function latestIsoDate(...values) {
  const parsed = values
    .map((value) => ({ raw: String(value ?? ''), date: new Date(String(value ?? '')) }))
    .filter(({ date }) => !Number.isNaN(date.valueOf()))
    .sort((a, b) => b.date.valueOf() - a.date.valueOf());
  return parsed[0]?.raw ?? '';
}

function normalize(s) {
  return String(s).replaceAll('\r\n', '\n').replaceAll('\r', '\n').replace(/\s*$/, '\n');
}

function toPosix(p) {
  return String(p).replaceAll('\\', '/');
}
