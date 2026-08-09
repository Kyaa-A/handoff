#!/usr/bin/env bash
set -euo pipefail

fixture_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/fixtures" && pwd)"
setup_output="$(bash "$fixture_dir/setup-cross-machine-repos.sh")"
root_path=""
destination_path=""
feature_sha=""

while IFS='=' read -r key value; do
  case "$key" in
    SOURCE_PATH) root_path="${value%/source-search-api}" ;;
    DESTINATION_PATH) destination_path="$value" ;;
    FEATURE_SHA) feature_sha="$value" ;;
  esac
done <<< "$setup_output"

cleanup() {
  local temp_root="${TMPDIR:-/tmp}"
  if [[ -n "$root_path" && -d "$root_path" && "$root_path" == "$temp_root"/handoff-cross-machine-eval.* ]]; then
    rm -rf -- "$root_path"
  fi
}
trap cleanup EXIT

[[ -n "$destination_path" && -d "$destination_path/.git" ]]
[[ "$feature_sha" =~ ^[0-9a-f]{40}$ ]]
[[ "$(git -C "$destination_path" branch --show-current)" == "main" ]]
[[ -z "$(git -C "$destination_path" status --short)" ]]

if git -C "$destination_path" cat-file -e "$feature_sha^{commit}" 2>/dev/null; then
  echo "feature commit unexpectedly available before fetch" >&2
  exit 1
fi

git -C "$destination_path" fetch -q origin feat/document-cursors
[[ "$(git -C "$destination_path" rev-parse FETCH_HEAD)" == "$feature_sha" ]]
git -C "$destination_path" cat-file -e "$feature_sha^{commit}"
git -C "$destination_path" switch -q -c feat/document-cursors "$feature_sha"
[[ ! -e "$destination_path/tmp/page-debug.json" ]]

test_output="$(cd "$destination_path" && pnpm test src/documents/cursor.test.ts 2>&1)"
printf '%s\n' "$test_output"
grep -Eq 'pass(ed)?[[:space:]]+9|9 passed' <<< "$test_output"
grep -Eq 'fail(ed)?[[:space:]]+0|0 failed' <<< "$test_output"
