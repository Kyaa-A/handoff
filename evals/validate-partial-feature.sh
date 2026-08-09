#!/usr/bin/env bash
set -euo pipefail
fixture_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/fixtures" && pwd)"
output="$(bash "$fixture_dir/setup-partial-feature.sh")"
repo_path="$(printf '%s\n' "$output" | sed -n 's/^REPO_PATH=//p')"
setup_sha="$(printf '%s\n' "$output" | sed -n 's/^SETUP_SHA=//p')"
cleanup() { case "$repo_path" in "${TMPDIR:-/tmp}"/handoff-partial-eval.*) rm -rf -- "$repo_path";; esac; }
trap cleanup EXIT HUP INT TERM
test -n "$setup_sha"
test "$(git -C "$repo_path" rev-parse HEAD)" = "$setup_sha"
test "$(git -C "$repo_path" branch --show-current)" = feat/idempotent-dispatch
test "$(git -C "$repo_path" status --short --untracked-files=all)" = $' M src/dispatch/dispatch.service.ts\n?? src/dispatch/idempotency.repository.ts'
grep -Fq 'emitted `SETUP_SHA`' "$fixture_dir/partial-feature-context.md"
! grep -Fq 'Commit `71c4e2a` added' "$fixture_dir/partial-feature-context.md"
grep -Fq 'exact `SETUP_SHA` emitted by setup' "$fixture_dir/../evals.json"
