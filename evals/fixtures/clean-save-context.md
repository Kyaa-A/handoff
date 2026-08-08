# Session context: audit CSV export

The user asked to pause work on large audit-log exports. The repository is the
directory emitted as `REPO_PATH` by `setup-clean-save.sh`. The setup also emits
the current commit as `HEAD_SHA`; inspect the repository to confirm its branch,
status, commit, implementation, and unfinished pointer.

The implementation streams rows rather than buffering an entire export. Earlier
profiling showed production exports can exceed 500 MB, which is why the team
rejected buffering. A teammate also mentioned that the admin table's empty-state
copy may need revision, but that belongs to a different ticket.

The following test evidence was supplied in this session context. It was not
rerun by the handoff writer:

```text
$ pnpm test src/audit/export.test.ts
Tests: 12 passed, 12 total
```

No full suite, typecheck, or lint command was run. The unfinished work is the
UTF-8 BOM option at `src/audit/export.ts:64`; after adding it, the focused export
test needs to be rerun.
