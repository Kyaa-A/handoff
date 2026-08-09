#!/usr/bin/env bash
set -euo pipefail
fixture_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/fixtures" && pwd)"
output="$(bash "$fixture_dir/setup-dirty-worktree.sh")"
repo_path="$(printf '%s\n' "$output" | sed -n 's/^REPO_PATH=//p')"
before="$(printf '%s\n' "$output" | sed -n 's/^SCRATCH_SHA256_BEFORE=//p')"
cleanup() { case "$repo_path" in "${TMPDIR:-/tmp}"/handoff-dirty-eval.*) rm -rf -- "$repo_path";; esac; }
trap cleanup EXIT HUP INT TERM
after="$(sha256sum "$repo_path/notes/customer-cases.txt" | awk '{print $1}')"
test "$before" = "$after"
test "$(git -C "$repo_path" status --short --untracked-files=all)" = $' M src/invoices/calculate-total.test.ts\n M src/invoices/calculate-total.ts\n?? notes/customer-cases.txt'
