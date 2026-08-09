#!/usr/bin/env bash
set -euo pipefail

fixture_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/fixtures" && pwd)"
setup_output="$(bash "$fixture_dir/setup-same-day-conflict.sh")"
repo_path="$(printf '%s\n' "$setup_output" | sed -n 's/^REPO_PATH=//p')"
old_sha="$(printf '%s\n' "$setup_output" | sed -n 's/^OLD_SHA=//p')"
current_sha="$(printf '%s\n' "$setup_output" | sed -n 's/^CURRENT_SHA=//p')"

cleanup() {
  local temp_root="${TMPDIR:-/tmp}"
  if [[ -n "$repo_path" && -f "$repo_path/.eval-root" && "$repo_path" == "$temp_root"/handoff-same-day-eval.* ]]; then
    rm -rf -- "$repo_path"
  fi
}
trap cleanup EXIT

[[ "$(git -C "$repo_path" branch --show-current)" == "feat/payment-retry-v2" ]]
[[ "$(git -C "$repo_path" rev-parse HEAD)" == "$current_sha" ]]
[[ "$old_sha" != "$current_sha" ]]
[[ -z "$(git -C "$repo_path" status --short --untracked-files=all)" ]]
[[ -f "$repo_path/src/payments/retry.test.ts" ]]
[[ ! -e "$repo_path/src/payments/legacy-retry.ts" ]]
[[ "$repo_path/.handoffs/2026-08-09-payment-zeta.md" -nt "$repo_path/.handoffs/2026-08-09-payment-alpha.md" ]]
[[ "$(find "$repo_path/.handoffs" -maxdepth 1 -type f -printf '%f\n' | sort | tail -1)" == "2026-08-09-payment-zeta.md" ]]
