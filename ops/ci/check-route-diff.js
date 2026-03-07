const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..', '..');
const openApiPath = path.join(repoRoot, 'contracts', 'openapi', 'huoduoduo-v1.openapi.yaml');
const controllersRoot = path.join(repoRoot, 'apps', 'bff_hdd', 'src', 'modules');

function readOpenApiPaths() {
  const content = fs.readFileSync(openApiPath, 'utf8');
  const lines = content.split(/\r?\n/);
  const paths = new Set();
  for (const line of lines) {
    const match = line.match(/^  (\/[^:]+):\s*$/);
    if (match) {
      paths.add(match[1]);
    }
  }
  return paths;
}

function normalizePath(base, suffix) {
  const raw = `/${[base, suffix].filter(Boolean).join('/')}`
    .replace(/\/+/g, '/')
    .replace(/\/$/, '');
  return raw.replace(/:([A-Za-z0-9_]+)/g, '{$1}');
}

function collectControllerPaths(dir) {
  const paths = new Set();
  const files = walk(dir).filter((f) => f.endsWith('.controller.ts'));
  for (const file of files) {
    const content = fs.readFileSync(file, 'utf8');
    const baseMatch = content.match(/@Controller\('([^']*)'\)/);
    if (!baseMatch) {
      continue;
    }
    const base = baseMatch[1];
    const methodRegex = /@(Get|Post|Delete|Patch|Put)\((?:'([^']*)')?\)/g;
    let methodMatch;
    while ((methodMatch = methodRegex.exec(content)) !== null) {
      const suffix = methodMatch[2] || '';
      paths.add(normalizePath(base, suffix));
    }
  }
  return paths;
}

function walk(dir) {
  const output = [];
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      output.push(...walk(fullPath));
    } else {
      output.push(fullPath);
    }
  }
  return output;
}

const openApiPaths = readOpenApiPaths();
const controllerPaths = collectControllerPaths(controllersRoot);

const missingInControllers = [...openApiPaths].filter((p) => !controllerPaths.has(p));
const missingInOpenApi = [...controllerPaths].filter((p) => !openApiPaths.has(p));

if (missingInControllers.length || missingInOpenApi.length) {
  console.error('Route diff check failed.');
  if (missingInControllers.length) {
    console.error('OpenAPI paths missing in controllers:');
    for (const item of missingInControllers) {
      console.error(`  - ${item}`);
    }
  }
  if (missingInOpenApi.length) {
    console.error('Controller paths missing in OpenAPI:');
    for (const item of missingInOpenApi) {
      console.error(`  - ${item}`);
    }
  }
  process.exit(1);
}

console.log('Route diff check passed.');
