# Dirty worktree save context

Repository: `/work/acme-billing`

- Current branch: `fix/invoice-rounding`
- `git status --short` returned:

  ```text
   M src/invoices/calculate-total.ts
   M src/invoices/calculate-total.test.ts
  ?? notes/customer-cases.txt
  ```

- The edits in both `src/invoices/` files were made during this session to round
  tax only after summing line items.
- `notes/customer-cases.txt` existed as an untracked file before this session.
  The user said it is their private scratchpad: preserve it, do not open, stage,
  modify, delete, or include its contents in the handoff.
- Decision: round after summing, rather than per line, because invoice INV-1842
  differs by one cent when each line is rounded independently.
- Verification actually run:

  ```text
  $ pnpm test src/invoices/calculate-total.test.ts
  Tests: 6 passed, 6 total
  ```

- `pnpm test` for the full suite was not run.
- Required next action: add a regression case for a negative discount line, then
  rerun `pnpm test src/invoices/calculate-total.test.ts`.
