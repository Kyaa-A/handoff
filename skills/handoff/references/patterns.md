# Handoff mechanics

The details behind the `handoff` rules: the anatomy of a good note, the compression rules, good versus bad entries, storage, and chaining sessions. Read the rule in `SKILL.md`, then the example here.

## 1. The template

A handoff note is one Markdown file. Keep the whole thing to a screenful.

```markdown
---
date: 2026-06-24
topic: rls-policy-auditor
status: in-progress
---

# Next step
Wire the `prove` step to run the tenant-isolation query as the `authenticated`
role for a second tenant and assert zero rows. See `commands/prove.md:40`.

# Goal
Build the RLS auditor skill: audit finds missing/leaky policies, fix scaffolds
them, prove runs queries under real auth contexts to confirm isolation.

# Done
- audit.md rubric written and validated. Commit a1b2c3d.
- fix.md scaffolds a CREATE POLICY per missing CRUD verb. Commit e4f5g6h.

# In progress
- prove.md: connects to the shadow DB, but the role-switch (SET ROLE) is stubbed.
  Left to do: run the cross-tenant query and assert the row count.

# Decisions
- Shadow DB over prod for prove, so a leaky policy can never expose real rows.
  (Why: the whole point is to catch leaks before they reach prod.)
- Per-verb policies, not one blanket policy. (Why: a single USING clause hides
  which operation is actually unguarded.)

# Blockers
- None. The SET ROLE approach is confirmed working against local Supabase.

# Pointers
- skills/rls/SKILL.md  (the 6 rules)
- commands/prove.md:40  (the stubbed role switch)
- supabase/migrations/  (where generated policies land)
```

The frontmatter is optional but cheap: it lets a resume step sort and filter without reading the body.

## 2. State, not transcript

The single most common failure is writing what happened instead of where things stand. A handoff is read forward, to act, not backward, to reminisce.

```markdown
<!-- Bad: a transcript. The reader has to reconstruct the state themselves. -->
First I tried adding the index on `created_at`, but EXPLAIN still showed a seq
scan, so then I looked at the query and realized it filters on `tenant_id` too,
and after some back and forth we decided a composite index made more sense...

<!-- Good: the state, plus the why, in two lines. -->
Added composite index on (tenant_id, created_at); seq scan is gone (confirmed via
EXPLAIN). Chose composite over single-column because every query filters tenant
first. Migration: supabase/migrations/20260624_idx.sql.
```

## 3. Why over what

The repository records what. It cannot record why a road was not taken. That is the knowledge a fresh session most needs and most easily loses.

```markdown
<!-- Weak: restates the diff. -->
Switched the parser to use a JSON schema.

<!-- Strong: records the reason, so nobody re-litigates it. -->
Switched the parser to tool-use with a JSON schema. Free-text parsing failed on
~10% of inputs where the model added prose around the JSON. Schema mode is now
at 100% on the 40-case fixture. Do not revert to free-text.
```

## 4. Point, do not paste

Pasted code rots and bloats. Pointers stay cheap and current.

- A file region: `path/to/file.ts:120-145`.
- A commit: the short SHA, `a1b2c3d`.
- A command to rerun: `pnpm test src/rls`.
- A source: the URL or ticket id, not its contents.

If a snippet is truly load-bearing and not yet committed, commit it first and point at the SHA, rather than pasting it into the note.

## 5. Confirmed versus assumed

A resume that trusts an unverified claim wastes the work the handoff was meant to save. Separate the two explicitly.

```markdown
# Done (confirmed)
- Login flow works end to end. Verified manually at localhost:3000/login.
- Unit tests pass: `pnpm test` green, 84/84.

# Believed but unverified
- The rate limiter should cover the /vote route, but I never hit it under load.
  Verify before claiming it is done.
```

The resume step should re-check anything in the unverified list before building on it.

## 6. Storage and naming

- One file per handoff: `.handoffs/YYYY-MM-DD-<slug>.md`.
- The date prefix sorts chronologically, so "newest" is just the last filename.
- `<slug>` is a short kebab-case topic (`rls-prove-step`, `checkout-bug`), so a directory listing reads like a table of contents.
- Default to gitignoring `.handoffs/`: these are working notes, often personal, sometimes containing local paths or half-formed ideas. Commit them only when the user wants a shared, team-visible handoff.

## 7. Chaining sessions

Across several sessions, the `.handoffs/` directory becomes a thin timeline. Two rules keep it useful:

- **Supersede, do not append.** Each new handoff is a fresh snapshot of the current state, not a diff against the last one. The newest file is always the complete picture.
- **Link, do not repeat.** If a past decision still matters, reference the older note by filename rather than copying it forward. The chain stays lean and the history stays discoverable.

When resuming, read only the newest note by default. Reach for older ones only when it points back to them or when a decision's reasoning is needed.

## 8. The resume read

A good resume is three lines, not a recital:

```
Resuming rls-policy-auditor (handoff 2026-06-24). audit and fix are done and
committed; prove.md has the role-switch stubbed at commands/prove.md:40. Next:
wire the cross-tenant query and assert zero rows. Starting there now.
```

Then act. The note is the context; do not rebuild it from the repository unless a pointer has gone stale.
