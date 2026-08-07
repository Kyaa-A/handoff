# Cross-machine resume context

The handoff was written in a source checkout and is now being resumed in a fresh
destination clone produced by the attached setup script.

## Handoff note

- Goal: add cursor pagination to `GET /documents`.
- Branch: `feat/document-cursors`; the source worktree was dirty when the note
  was written.
- The portable work was committed and pushed to
  `origin/feat/document-cursors` before switching machines. The setup script
  prints its exact `FEATURE_SHA`.
- Do not rely on `tmp/page-debug.json` in the source checkout; it was an
  untracked, machine-local debug artifact and was intentionally not committed.
- Decision: encode `(created_at, id)` in the cursor because timestamps are not
  unique and `id` provides deterministic ordering.
- Verification on the source machine:

  ```text
  $ pnpm test src/documents/cursor.test.ts
  Tests: 9 passed, 9 total
  ```

- `pnpm test` was not run.
- The destination has not yet run the focused test. Before continuing, recover
  the pushed feature work safely and establish that the intended commit is the
  one available locally.
