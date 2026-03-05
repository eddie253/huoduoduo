#!/usr/bin/env node
import { spawnSync } from "node:child_process";

const result = spawnSync("npm", ["run", "wave2:uat-smoke"], {
  stdio: "inherit",
  shell: true,
});

if (result.status !== 0) {
  process.exit(result.status ?? 1);
}
