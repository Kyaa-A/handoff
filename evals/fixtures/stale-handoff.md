---
date: 2026-08-05
topic: export-timeout
status: in-progress
branch: fix/export-timeout
---

# Next step
Edit `src/export/run-export.ts:88` to pass the abort signal into `fetchBatch`,
then run `pnpm test src/export/run-export.test.ts`.

# Goal
Stop CSV exports promptly when the client disconnects.

# Done (confirmed)
- Abort controller plumbing added in commit `abc1234`.
- Focused tests passed: `pnpm test src/export/run-export.test.ts` (8/8).

# Working state
On `fix/export-timeout`; clean tree.

# Decisions
- Propagate one abort signal through every batch. This prevents a disconnected
  request from starting later database reads.

# Believed but unverified
- `fetchBatch` still ignores its signal argument.

# Pointers
- `src/export/run-export.ts:88`
- commit `abc1234`
