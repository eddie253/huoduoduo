#!/usr/bin/env bash
set -euo pipefail

if [[ "${ALLOW_LEGACY_BASELINE_CHANGE:-0}" == "1" ]]; then
  echo "Legacy baseline read-only guard bypassed by ALLOW_LEGACY_BASELINE_CHANGE=1."
  exit 0
fi

if [[ "${GITHUB_EVENT_NAME:-}" == "pull_request" ]]; then
  base_ref="${GITHUB_BASE_REF:-main}"
  git fetch origin "${base_ref}" --depth=1
  diff_range="origin/${base_ref}...HEAD"
else
  if git rev-parse --verify HEAD~1 >/dev/null 2>&1; then
    diff_range="HEAD~1..HEAD"
  else
    echo "No previous commit found. Skip legacy baseline guard."
    exit 0
  fi
fi

changed_files="$(git diff --name-only "${diff_range}")"

blocked_files="$(echo "${changed_files}" | grep -E '^(app/|zbarlibary/)' || true)"
if [[ -n "${blocked_files}" ]]; then
  echo "Legacy baseline is read-only. Changes detected in frozen paths:"
  echo "${blocked_files}"
  echo "If this change is intentional, set ALLOW_LEGACY_BASELINE_CHANGE=1 explicitly."
  exit 1
fi

echo "Legacy baseline read-only check passed."
