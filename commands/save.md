---
description: Write a lean, resumable handoff note for the current session so a fresh session can continue without re-reading the conversation. Captures goal, state, decisions, next step, and pointers to a dated file in .handoffs/.
argument-hint: [short topic slug for the note, defaults to the current work]
---

You are writing a **handoff note** so a fresh session can continue this work.
Follow the `handoff` skill — invoke it if not already loaded; it carries the
rules plus the note template and examples.

## Topic

Topic slug: `$ARGUMENTS`

- If a slug is given, use it as `<slug>` in the filename.
- If none is given, derive a short kebab-case slug from the current goal.

## What to do

1. Reconstruct the state of the work from this session: the goal, what is done
   and confirmed, what is in progress, the working state (branch, and whether the
   tree is clean, dirty, or stashed), the decisions made and why, any blockers,
   and the handful of files, commits, or commands the next session needs.
2. Write it to `.handoffs/YYYY-MM-DD-<slug>.md` using the template the `handoff`
   skill provides. Use today's actual date, absolute, not relative.
3. Lead the body with the single next step. Point at `path:line` and commit SHAs
   instead of pasting code. Separate confirmed work from believed-but-unverified.
4. Keep it to a screenful. A handoff is an index, not a transcript.
5. Add `.handoffs/` to the project `.gitignore` unless the user has asked to
   commit handoffs for a team. State which you did.

## Output

Report the file path, the one-line next step, and whether you gitignored or
committed the note. Keep the confirmation to a few lines. Do not commit any other
work, and do not stage unrelated changes.
