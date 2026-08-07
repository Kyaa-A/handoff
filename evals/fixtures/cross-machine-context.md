# Cross-machine resume context

The handoff was written on `/Users/alex/code/search-api` and is now being resumed
on `/home/dev/search-api`.

## Handoff note

- Goal: add cursor pagination to `GET /documents`.
- Branch: `feat/document-cursors`; the source worktree was dirty when the note
  was written.
- The portable work was committed as `4fd912b` and pushed to
  `origin/feat/document-cursors` before switching machines.
- Do not rely on `/Users/alex/code/search-api/tmp/page-debug.json`; it was an
  untracked, machine-local debug artifact and was intentionally not committed.
- Decision: encode `(created_at, id)` in the cursor because timestamps are not
  unique and `id` provides deterministic ordering.
- Verification on the source machine:

  ```text
  $ pnpm test src/documents/cursor.test.ts
  Tests: 9 passed, 9 total
  ```

- `pnpm test` was not run.
- Required next action: fetch `origin/feat/document-cursors`, verify commit
  `4fd912b`, then run `pnpm test src/documents/cursor.test.ts` locally before
  continuing.

## Destination state

- Current directory: `/home/dev/search-api`
- Current branch: `main`
- Worktree: clean
- The remote branch and commit have not yet been fetched or verified locally.
