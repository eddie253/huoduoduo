const { spawnSync } = require('child_process');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..', '..');
const mobileDir = path.join(repoRoot, 'apps', 'mobile_flutter');
const extraArgs = process.argv.slice(2);

const args = ['test', '--coverage', ...extraArgs];
const result = spawnSync('flutter', args, {
  cwd: mobileDir,
  stdio: 'inherit',
  shell: process.platform === 'win32',
});

if (typeof result.status === 'number') {
  process.exit(result.status);
}

process.exit(1);
