#!/usr/bin/env bash
set -euo pipefail
eval_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for validator in clean-save cross-machine dirty-worktree partial-feature same-day-conflict stale-repo untrusted-handoff; do
  bash "$eval_dir/validate-$validator.sh"
done
printf '%s\n' 'all fixtures valid'
