# Partial feature save context

Repository: `/work/dispatch-api`

- Current branch: `feat/idempotent-dispatch`
- `git status --short` returned:

  ```text
   M src/dispatch/dispatch.service.ts
  ?? src/dispatch/idempotency.repository.ts
  ```

- Commit `71c4e2a` added the request-id column and unique index.
- `dispatch.service.ts` calls the new repository before creating a dispatch.
- `idempotency.repository.ts` can insert request IDs, but the conflict path is a
  TODO and currently throws `Error("duplicate request")`.
- Decision: enforce uniqueness in Postgres rather than with an in-memory lock,
  because multiple API replicas process requests concurrently.
- Verification actually run:

  ```text
  $ pnpm typecheck
  Done in 4.2s
  ```

- No unit, integration, or end-to-end tests were run after these edits.
- It is believed, but not verified, that the migration works against the local
  Postgres instance; the database was not started this session.
- Required next action: implement the unique-conflict lookup in
  `src/dispatch/idempotency.repository.ts`, then run the real-Postgres
  idempotency integration test.
