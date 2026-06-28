<!-- Example: a good handoff note. See examples/bad-handoff.md for the same work written badly. -->
---
date: 2026-06-24
topic: stripe-webhook-idempotency
status: in-progress
branch: fix/webhook-idempotency
---

# Next step
Add the unique constraint on `webhook_events.event_id` and run the migration, then
delete the in-memory `Set` guard in `src/payments/webhook.ts:48`. The DB constraint
replaces it.

# Goal
Make the Stripe webhook handler idempotent so retried events never double-credit a
wallet. Stripe redelivers on any non-2xx, and our handler currently processes each
delivery.

# Done (confirmed)
- Reproduced the double-credit: replaying one `payment_intent.succeeded` credited the
  wallet twice. Captured in the failing test `webhook.spec.ts:120` (red).
- Handler now records every event id before crediting. Commit `7f3a1c2`.

# In progress
- Dedup is enforced by an in-memory `Set` (`src/payments/webhook.ts:48`) as a stopgap.
  It does not survive a restart and breaks across multiple instances. Replacing it
  with a unique constraint on `webhook_events.event_id` + an upsert that no-ops on
  conflict. Migration drafted, not yet run.

# Working state
On `fix/webhook-idempotency`. webhook.ts has uncommitted edits (the Set guard);
the migration is drafted but unstaged. Commit `7f3a1c2` holds the event-recording.

# Environment
Dev server on :3000 (`pnpm dev`). Needs STRIPE_SECRET_KEY and DATABASE_URL set
(see `.env.example`); the local DB is migrated to head, the unique-constraint
migration is drafted but not yet run.

# Decisions
- Dedup at the database, not the app. (Why: we run 3 instances behind the LB, so an
  in-process guard cannot see another instance's events. The DB is the only shared
  truth.)
- Store-then-credit, not credit-then-store. (Why: if the process dies mid-handler,
  an unstored credit would replay and double; an uncredited store just retries
  cleanly.)

# Blockers / open questions
- None blocking. Open question: backfill the `webhook_events` table from Stripe's
  event log, or start fresh from the deploy? Leaning fresh; we have no live leak.

# Believed but unverified
- The unique-constraint upsert should make the green path of `webhook.spec.ts:120`
  pass. Written but not run against the constraint yet. Verify before claiming done.

# Pointers
- src/payments/webhook.ts:48  (the in-memory guard to delete)
- src/payments/webhook.spec.ts:120  (the idempotency test, currently red)
- migrations/  (where the unique-constraint migration lands)
- `pnpm test src/payments`  (rerun to confirm green)
