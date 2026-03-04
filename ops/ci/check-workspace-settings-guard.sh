#!/usr/bin/env bash
set -euo pipefail

protected_file=".vscode/settings.json"

if [[ "${ALLOW_WORKSPACE_SETTINGS_CHANGE:-0}" == "1" ]]; then
  echo "Workspace settings guard bypassed by ALLOW_WORKSPACE_SETTINGS_CHANGE=1."
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
    echo "No previous commit found. Skip workspace settings guard."
    exit 0
  fi
fi

changed_files="$(git diff --name-only "${diff_range}")"
changed_target="$(echo "${changed_files}" | grep -E "^${protected_file}$" || true)"

if [[ -z "${changed_target}" ]]; then
  echo "Workspace settings guard passed. No changes in ${protected_file}."
  exit 0
fi

allowed_actors_csv="${ALLOWED_WORKSPACE_SETTINGS_ACTORS:-eddie253}"
actor="${GITHUB_ACTOR:-}"

is_allowed_actor="0"
IFS=',' read -r -a allowed_actor_arr <<< "${allowed_actors_csv}"
for raw in "${allowed_actor_arr[@]}"; do
  allowed="$(echo "${raw}" | xargs)"
  if [[ -n "${allowed}" && "${actor}" == "${allowed}" ]]; then
    is_allowed_actor="1"
    break
  fi
done

if [[ "${is_allowed_actor}" == "1" ]]; then
  echo "Protected file changed by allowed actor '${actor}'."
  echo "Changed file: ${protected_file}"
  exit 0
fi

echo "Protected workspace settings file changed: ${protected_file}"
echo "Actor '${actor}' is not in ALLOWED_WORKSPACE_SETTINGS_ACTORS='${allowed_actors_csv}'."
echo "Use CODEOWNERS review + allowed actor or explicit bypass env only for emergency."
exit 1
