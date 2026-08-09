#!/usr/bin/env bash
set -euo pipefail

repo_path="$(mktemp -d "${TMPDIR:-/tmp}/handoff-partial-eval.XXXXXX")"
git -C "$repo_path" init -q
touch "$repo_path/.git/handoff-eval-root"
git -C "$repo_path" config user.email eval@example.test
git -C "$repo_path" config user.name "Handoff Eval"
git -C "$repo_path" switch -q -c feat/idempotent-dispatch
mkdir -p "$repo_path/src/dispatch"
printf '%s\n' 'export const createDispatch = () => "created";' > "$repo_path/src/dispatch/dispatch.service.ts"
git -C "$repo_path" add .
git -C "$repo_path" commit -qm "feat: add request id schema"
setup_sha="$(git -C "$repo_path" rev-parse HEAD)"

printf '%s\n' 'export const createDispatch = () => "checks request id";' > "$repo_path/src/dispatch/dispatch.service.ts"
cat > "$repo_path/src/dispatch/idempotency.repository.ts" <<'EOF'
export const recordRequest = () => {
  throw new Error("duplicate request");
};
EOF

printf 'REPO_PATH=%s\nSETUP_SHA=%s\n' "$repo_path" "$setup_sha"
