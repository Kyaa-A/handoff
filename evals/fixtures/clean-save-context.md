# Session context: audit CSV export

The user asked to pause work on large audit-log exports. The repository is on
`feat/audit-export`; `git status --short` produced no output. Commit `9b7c1d2`
contains CSV escaping.

The implementation streams rows rather than buffering an entire export. Earlier
profiling showed production exports can exceed 500 MB, which is why the team
rejected buffering. A teammate also mentioned that the admin table's empty-state
copy may need revision, but that belongs to a different ticket.

This session ran:

```text
$ pnpm test src/audit/export.test.ts
Tests: 12 passed, 12 total
```

No full suite, typecheck, or lint command was run. The unfinished work is the
UTF-8 BOM option at `src/audit/export.ts:64`; after adding it, the focused export
test needs to be rerun.
