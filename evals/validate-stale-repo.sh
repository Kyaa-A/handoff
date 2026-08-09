#!/usr/bin/env bash
set -euo pipefail
fixture_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/fixtures" && pwd)"
output="$(bash "$fixture_dir/setup-stale-repo.sh")"
repo_path="$(printf '%s\n' "$output" | sed -n 's/^REPO_PATH=//p')"
cleanup() { case "$repo_path" in "${TMPDIR:-/tmp}"/handoff-stale-eval.*) rm -rf -- "$repo_path";; esac; }
trap cleanup EXIT HUP INT TERM
test "$(git -C "$repo_path" branch --show-current)" = fix/export-timeout-v2
test ! -e "$repo_path/src/export/run-export.ts"
grep -Fq 'fetchBatch({ signal })' "$repo_path/src/exports/export-runner.ts"
test -f "$repo_path/src/exports/export-runner.test.ts"
test -z "$(git -C "$repo_path" status --short)"
