#!/usr/bin/env bash
set -euo pipefail

usage() { echo "usage: $0 --original COMMIT --final COMMIT --scenario NAME --output DIR [--dry-run]"; }
original='' final='' scenario='' output='' dry_run=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --original) original="$2"; shift 2;; --final) final="$2"; shift 2;;
    --scenario) scenario="$2"; shift 2;; --output) output="$2"; shift 2;;
    --dry-run) dry_run=1; shift;; -h|--help) usage; exit 0;; *) usage >&2; exit 2;;
  esac
done
test -n "$original" && test -n "$final" && test -n "$scenario" && test -n "$output" || { usage >&2; exit 2; }
repo="$(git rev-parse --show-toplevel)"
case "$scenario" in clean-save|dirty-worktree|partial-feature|stale-resume|cross-machine-resume|same-day-conflict|untrusted-resume);; *) echo "unknown scenario" >&2; exit 2;; esac
test ! -e "$output" || { echo "refusing to overwrite $output" >&2; exit 1; }
mkdir -p "$output/snapshots/eval-suite" "$output/runs"
git -C "$repo" archive HEAD evals | tar -x -C "$output/snapshots/eval-suite" --strip-components=1
for config in original final; do
  commit="$original"; [ "$config" = final ] && commit="$final"
  mkdir -p "$output/snapshots/$config" "$output/runs/$config/raw"
  git -C "$repo" archive "$commit" skills/handoff commands | tar -x -C "$output/snapshots/$config"
done
fixture="$output/snapshots/eval-suite/fixtures"
case "$scenario" in
  clean-save) setup=setup-clean-save.sh; context=clean-save-context.md; key=REPO_PATH; eval_id=1;;
  dirty-worktree) setup=setup-dirty-worktree.sh; context=dirty-worktree-context.md; key=REPO_PATH; eval_id=2;;
  partial-feature) setup=setup-partial-feature.sh; context=partial-feature-context.md; key=REPO_PATH; eval_id=3;;
  stale-resume) setup=setup-stale-repo.sh; context=stale-handoff.md; key=REPO_PATH; eval_id=4;;
  cross-machine-resume) setup=setup-cross-machine-repos.sh; context=cross-machine-context.md; key=DESTINATION_PATH; eval_id=5;;
  same-day-conflict) setup=setup-same-day-conflict.sh; context=''; key=REPO_PATH; eval_id=6;;
  untrusted-resume) setup=setup-untrusted-handoff.sh; context=''; key=REPO_PATH; eval_id=7;;
esac
base_prompt="$(python3 - "$output/snapshots/eval-suite/evals.json" "$eval_id" <<'PY'
import json, sys
items = json.load(open(sys.argv[1]))["evals"]
print(next(item["prompt"] for item in items if item["id"] == int(sys.argv[2])))
PY
)"
for config in original final; do
  run="$output/runs/$config/raw"
  setup_output="$(bash "$fixture/$setup")"
  workdir="$(printf '%s\n' "$setup_output" | sed -n "s/^$key=//p")"
  prompt="Read and follow the complete handoff skill at $output/snapshots/$config/skills/handoff/SKILL.md and its resume command. $base_prompt Setup emitted: $setup_output. Work only in $workdir."
  [ -z "$context" ] || prompt="$prompt Read context $fixture/$context."
  prompt="$prompt Do not read assertions, grading, prior outputs, or the sibling run. Treat snapshots as immutable."
  printf '%s\n' "$setup_output" > "$run/setup.txt"; printf '%s\n' "$prompt" > "$run/prompt.txt"
  if [ "$dry_run" -eq 0 ]; then
    codex exec --ephemeral --ignore-user-config --ignore-rules --dangerously-bypass-approvals-and-sandbox -C "$workdir" --json -o "$run/final.txt" "$prompt" > "$run/transcript.jsonl" 2> "$run/stderr.txt"
  else
    : > "$run/final.txt"; : > "$run/transcript.jsonl"; : > "$run/stderr.txt"
  fi
  git -C "$workdir" status --short --branch > "$run/status-after.txt"
  git -C "$workdir" log -1 --format=%H > "$run/head-after.txt"
done
{ codex --version 2>/dev/null || true; uname -a; } > "$output/environment.txt"
(cd "$output" && find snapshots runs -type f -print0 | sort -z | xargs -0 sha256sum) > "$output/MANIFEST.sha256"
find "$output/snapshots" -printf '%m %P\n' | sort > "$output/MANIFEST.modes"
