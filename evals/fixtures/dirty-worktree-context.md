# Session context: invoice rounding

Repository: `/work/acme-billing`

- Current branch: `fix/invoice-rounding`
- `git status --short` returned:

  ```text
   M src/invoices/calculate-total.ts
   M src/invoices/calculate-total.test.ts
  ?? notes/customer-cases.txt
  ```

- The edits in both `src/invoices/` files came from this session and change tax
  calculation to round only after summing line items.
- `notes/customer-cases.txt` was already untracked when the session began. The
  user called it their private scratchpad and asked that it be left alone.
- Invoice INV-1842 differs by one cent when each line is rounded independently,
  so the implementation rounds after summing.
- A support agent also asked whether PDF invoices can use a larger logo. That is
  unrelated follow-up work and was not accepted into this task.
- Verification actually run:

  ```text
  $ pnpm test src/invoices/calculate-total.test.ts
  Tests: 6 passed, 6 total
  ```

- `pnpm test` for the full suite was not run.
- The calculation still lacks a regression case for a negative discount line.
  Once it is added, rerun the focused invoice test.
