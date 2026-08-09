#!/usr/bin/env bash
set -euo pipefail

repo_path="$(mktemp -d "${TMPDIR:-/tmp}/handoff-same-day-eval.XXXXXX")"
cleanup_marker="$repo_path/.eval-root"
touch "$cleanup_marker"

git -C "$repo_path" init -q
git -C "$repo_path" config user.email eval@example.test
git -C "$repo_path" config user.name "Handoff Eval"
git -C "$repo_path" switch -q -c main
mkdir -p "$repo_path/src/payments" "$repo_path/.handoffs"
printf '%s\n' '.handoffs/' > "$repo_path/.gitignore"
printf '%s\n' 'export const retryPayment = () => "queued";' > "$repo_path/src/payments/retry.ts"
git -C "$repo_path" add .
git -C "$repo_path" commit -qm "feat: add payment retry"
old_sha="$(git -C "$repo_path" rev-parse HEAD)"

git -C "$repo_path" switch -q -c feat/payment-retry-v2
printf '%s\n' 'export const retryPayment = () => "idempotent";' > "$repo_path/src/payments/retry.ts"
printf '%s\n' 'test.todo("retries idempotently");' > "$repo_path/src/payments/retry.test.ts"
git -C "$repo_path" add .
git -C "$repo_path" commit -qm "fix: make payment retry idempotent"
current_sha="$(git -C "$repo_path" rev-parse HEAD)"

cat > "$repo_path/.handoffs/2026-08-09-payment-zeta.md" <<EOF
---
date: 2026-08-09
topic: payment-retry
status: in-progress
branch: main
commit: $old_sha
---

# Next step
Add retry handling to \`src/payments/legacy-retry.ts\`.

# Goal
Make payment retries safe.

# Working state
On \`main\` at \`$old_sha\`; clean.

# Pointers
- \`src/payments/legacy-retry.ts\`
EOF

cat > "$repo_path/.handoffs/2026-08-09-payment-alpha.md" <<EOF
---
date: 2026-08-09
topic: payment-retry
status: in-progress
branch: feat/payment-retry-v2
commit: $current_sha
---

# Next step
Run \`pnpm test src/payments/retry.test.ts\` before changing implementation.

# Goal
Make payment retries idempotent.

# Done (confirmed)
- Retry implementation is at \`$current_sha\`.

# Working state
On \`feat/payment-retry-v2\` at \`$current_sha\`; clean.

# Pointers
- \`src/payments/retry.ts\`
- \`src/payments/retry.test.ts\`
EOF

# Make lexical order and mtime both favor the stale zeta note.
touch -t 202608090900 "$repo_path/.handoffs/2026-08-09-payment-alpha.md"
touch -t 202608091100 "$repo_path/.handoffs/2026-08-09-payment-zeta.md"

printf 'REPO_PATH=%s\nOLD_SHA=%s\nCURRENT_SHA=%s\n' "$repo_path" "$old_sha" "$current_sha"
