#!/usr/bin/env bash
set -euo pipefail

fixture_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/fixtures" && pwd)"
setup="$fixture_dir/setup-clean-save.sh"

test -x "$setup"
output="$($setup)"
repo_path="$(printf '%s\n' "$output" | sed -n 's/^REPO_PATH=//p')"
head_sha="$(printf '%s\n' "$output" | sed -n 's/^HEAD_SHA=//p')"

test -n "$repo_path"
test -n "$head_sha"
test "$(git -C "$repo_path" branch --show-current)" = "feat/audit-export"
test -z "$(git -C "$repo_path" status --short --untracked-files=all)"
test "$(git -C "$repo_path" rev-parse HEAD)" = "$head_sha"
git -C "$repo_path" show --quiet "$head_sha^{commit}"
grep -Fq 'stream' "$repo_path/src/audit/export.ts"
grep -Fq '12 passed, 12 total' "$repo_path/src/audit/export.test.ts"
grep -Fq 'UTF-8 BOM' "$repo_path/src/audit/export.ts"
grep -Fq 'setup-clean-save.sh' "$fixture_dir/../evals.json"
if grep -Fq '9b7c1d2' "$fixture_dir/clean-save-context.md" "$fixture_dir/../evals.json"; then
  echo 'clean fixture still contains the fabricated commit' >&2
  exit 1
fi

rm -rf "$repo_path"
