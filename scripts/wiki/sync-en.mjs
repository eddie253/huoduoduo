#!/usr/bin/env node

import { createHash } from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(scriptDir, '..', '..');
const zhRoot = path.resolve(repoRoot, 'docs/wiki-mdx');
const enRoot = path.resolve(repoRoot, 'docs/wiki-mdx/en-US');
const marker =
  '{/* AUTO-GENERATED: Do not edit manually. Use `pnpm run wiki:sync:en` after `pnpm run wiki:generate`. */}';
const isCheckMode = process.argv.includes('--check');

main();

function main() {
  if (!fs.existsSync(zhRoot)) {
    console.error('wiki:sync:en missing zh wiki root: docs/wiki-mdx. Run `pnpm run wiki:generate` first.');
    process.exit(1);
  }

  const zhFiles = listFiles(zhRoot, '.mdx')
    .filter((rel) => !rel.startsWith('en-US/'))
    .sort((a, b) => a.localeCompare(b));
  const expected = new Map();
  const timestamp = '2026-03-01T00:00:00Z';

  for (const rel of zhFiles) {
    const zhAbs = path.resolve(zhRoot, rel);
    const { frontmatter: zhFm, content: zhContent } = splitFrontmatter(fs.readFileSync(zhAbs, 'utf8'));
    const sourceHash = computeSourceHash(zhContent);
    const docId = String(zhFm.doc_id ?? makeWikiDocId(rel));
    const source = String(zhFm.source ?? rel.replace(/\.mdx$/i, '.md'));
    const title = String(zhFm.title ?? extractTitle(zhContent, rel));
    const enTitle = `[EN DRAFT] ${title}`;

    const outFrontmatter = [
      '---',
      `title: "${escapeYaml(enTitle)}"`,
      `source: "${escapeYaml(source)}"`,
      'generated: true',
      `doc_id: "${escapeYaml(docId)}"`,
      'lang: "en-US"',
      'source_of_truth: "zh-TW"',
      'translation_status: "draft"',
      `source_hash: "${sourceHash}"`,
      'owner: "bob"',
      `last_synced_utc: "${timestamp}"`,
      '---',
      '',
    ].join('\n');

    const relativeZhPath = path.posix.join('..', rel);
    const note = [
      marker,
      '',
      '> Auto-generated English skeleton.',
      `> Source (zh-TW): \`${relativeZhPath}\``,
      '> Translation mode: draft (manual translation required).',
      '',
    ].join('\n');
    const output = `${outFrontmatter}${note}${zhContent}`;
    expected.set(rel, normalize(output));
  }

  const stale = listGeneratedEnFiles(enRoot).filter((rel) => !expected.has(rel));
  if (isCheckMode) {
    const drift = [];
    for (const [rel, expectedContent] of expected.entries()) {
      const abs = path.resolve(enRoot, rel);
      if (!fs.existsSync(abs)) {
        drift.push(`${rel}: missing`);
        continue;
      }
      const actual = normalize(fs.readFileSync(abs, 'utf8'));
      if (actual !== expectedContent) {
        drift.push(`${rel}: outdated`);
      }
    }
    for (const rel of stale) {
      drift.push(`${rel}: stale-generated-file`);
    }

    if (drift.length > 0) {
      console.error('wiki:sync:en check failed. English mirror drift detected.');
      for (const item of drift) {
        console.error(`- ${item}`);
      }
      console.error('\nRun: `pnpm run wiki:sync:en`.');
      process.exit(1);
    }
    console.log('wiki:sync:en check passed.');
    return;
  }

  fs.mkdirSync(enRoot, { recursive: true });
  for (const rel of stale) {
    fs.unlinkSync(path.resolve(enRoot, rel));
  }
  for (const [rel, output] of expected.entries()) {
    const abs = path.resolve(enRoot, rel);
    fs.mkdirSync(path.dirname(abs), { recursive: true });
    fs.writeFileSync(abs, output, 'utf8');
  }

  console.log(`wiki:sync:en wrote ${expected.size} file(s) to docs/wiki-mdx/en-US.`);
}

function listFiles(rootDir, ext) {
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
      if (!entry.isFile() || !entry.name.endsWith(ext)) continue;
      out.push(toPosix(path.relative(rootDir, abs)));
    }
  }
  return out;
}

function listGeneratedEnFiles(rootDir) {
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
      if (!entry.isFile() || !entry.name.endsWith('.mdx')) continue;
      const raw = fs.readFileSync(abs, 'utf8');
      if (!raw.includes(marker)) continue;
      out.push(toPosix(path.relative(rootDir, abs)));
    }
  }
  return out.sort((a, b) => a.localeCompare(b));
}

function splitFrontmatter(raw) {
  const source = normalizeNewlines(raw);
  if (!source.startsWith('---\n')) return { frontmatter: {}, content: source };
  const end = source.indexOf('\n---\n', 4);
  if (end < 0) return { frontmatter: {}, content: source };
  const block = source.slice(4, end);
  const content = source.slice(end + 5);
  const frontmatter = {};
  for (const line of block.split('\n')) {
    const match = line.match(/^([A-Za-z0-9_-]+)\s*:\s*(.*)$/);
    if (!match) continue;
    const key = match[1];
    let value = match[2].trim();
    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    }
    frontmatter[key] = value;
  }
  return { frontmatter, content };
}

function extractTitle(markdown, relPath) {
  const match = String(markdown).match(/^#\s+(.+)$/m);
  return match?.[1]?.trim() || path.posix.basename(toPosix(relPath), '.mdx');
}

function makeWikiDocId(relMdxPath) {
  return `wiki-${String(relMdxPath).replace(/\.mdx$/i, '').replace(/[\\/]/g, '--')}`;
}

function computeSourceHash(content) {
  return createHash('sha256').update(normalizeNewlines(content).trimEnd(), 'utf8').digest('hex');
}

function normalize(s) {
  return normalizeNewlines(s).replace(/\s*$/, '\n');
}

function normalizeNewlines(input) {
  return String(input).replaceAll('\r\n', '\n').replaceAll('\r', '\n');
}

function escapeYaml(value) {
  return String(value).replaceAll('\\', '\\\\').replaceAll('"', '\\"');
}

function toPosix(input) {
  return String(input).replaceAll('\\', '/');
}
