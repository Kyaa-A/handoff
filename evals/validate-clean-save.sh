#!/usr/bin/env bash
set -euo pipefail

fixture_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/fixtures" && pwd)"
setup="$fixture_dir/setup-clean-save.sh"
repo_path=''

cleanup() {
  case "$repo_path" in
    "${TMPDIR:-/tmp}"/handoff-clean-eval.*) rm -rf -- "$repo_path" ;;
  esac
}
trap cleanup EXIT HUP INT TERM

test -x "$setup"
output="$($setup)"
repo_path="$(printf '%s\n' "$output" | sed -n 's/^REPO_PATH=//p')"
head_sha="$(printf '%s\n' "$output" | sed -n 's/^HEAD_SHA=//p')"

test -n "$repo_path"
test -n "$head_sha"
test "$(git -C "$repo_path" branch --show-current)" = "feat/audit-export"
test -z "$(git -C "$repo_path" status --short --untracked-files=all)"
test "$(git -C "$repo_path" rev-parse HEAD)" = "$head_sha"
git -C "$repo_path" cat-file -e "$head_sha^{commit}"
test "$(sed -n '64p' "$repo_path/src/audit/export.ts")" = '// TODO: add the optional UTF-8 BOM before the CSV header.'
grep -Fq 'setup-clean-save.sh' "$fixture_dir/../evals.json"
if grep -Fq '9b7c1d2' "$fixture_dir/clean-save-context.md" "$fixture_dir/../evals.json"; then
  echo 'clean fixture still contains the fabricated commit' >&2
  exit 1
fi

(cd "$repo_path" && pnpm test src/audit/export.test.ts)
