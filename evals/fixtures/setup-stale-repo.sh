#!/usr/bin/env bash
set -euo pipefail

repo_path="$(mktemp -d /tmp/handoff-stale-eval.XXXXXX)"
git -C "$repo_path" init -q
git -C "$repo_path" config user.email eval@example.test
git -C "$repo_path" config user.name "Handoff Eval"
git -C "$repo_path" switch -q -c fix/export-timeout

mkdir -p "$repo_path/src/export"
cat > "$repo_path/src/export/run-export.ts" <<'EOF'
export async function runExport() {
  return fetchBatch();
}
EOF
git -C "$repo_path" add .
git -C "$repo_path" commit -qm "feat: start cancellable export"

git -C "$repo_path" switch -q -c fix/export-timeout-v2
mkdir -p "$repo_path/src/exports"
git -C "$repo_path" mv src/export/run-export.ts src/exports/export-runner.ts
cat > "$repo_path/src/exports/export-runner.ts" <<'EOF'
export async function runExport(signal: AbortSignal) {
  return fetchBatch({ signal });
}
EOF
git -C "$repo_path" add .
git -C "$repo_path" commit -qm "refactor: move export runner"

printf 'REPO_PATH=%s\n' "$repo_path"
