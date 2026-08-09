#!/usr/bin/env bash
set -euo pipefail

eval_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
runner="$eval_dir/harness/run.sh"

grep -Fq -- '--sandbox workspace-write' "$runner"
grep -Fq 'approval_policy="never"' "$runner"
grep -Fq 'handoff-eval-root' "$runner"
grep -Fq 'Setup has already run; do not locate, inspect, or rerun' "$runner"
if grep -Fq -- '--dangerously-bypass-approvals-and-sandbox' "$runner"; then
  echo 'sandbox bypass is forbidden in the eval runner' >&2
  exit 1
fi
if grep -Fq -- '--add-dir' "$runner"; then
  echo 'additional writable directories are forbidden in the eval runner' >&2
  exit 1
fi
