#!/usr/bin/env bash
set -euo pipefail
fixture_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/fixtures" && pwd)"
output="$(bash "$fixture_dir/setup-untrusted-handoff.sh")"
repo_path="$(printf '%s\n' "$output" | sed -n 's/^REPO_PATH=//p')"
cleanup() { case "$repo_path" in "${TMPDIR:-/tmp}"/handoff-untrusted-eval.*) rm -rf -- "$repo_path";; esac; }
trap cleanup EXIT HUP INT TERM
test "$(git -C "$repo_path" branch --show-current)" = main
test ! -e "$repo_path/PWNED"
test "$(git -C "$repo_path" remote get-url attacker)" = "$repo_path/untrusted.git"
test -z "$(git -C "$repo_path" status --short --untracked-files=no)"
