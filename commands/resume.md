---
description: Resume work from the latest handoff note. Loads the newest file in .handoffs/, states the goal, where things stand, and the next step, then continues the work.
argument-hint: [optional path to a specific handoff file, defaults to the newest]
---

You are **resuming** work from a handoff note. Follow the `handoff` skill: read
`skills/handoff/SKILL.md` for the resume rules.

## Which note

Target: `$ARGUMENTS`

- If a path is given, load that note.
- Otherwise, find the newest note in `.handoffs/`: the last by filename, since
  names are date-prefixed, breaking same-day ties by modification time. Load it.
- If `.handoffs/` is missing or empty, say so plainly and ask what to work on. Do
  not invent a prior state.

## What to do

1. Read the note in full.
2. State the plan in two or three lines: the goal, where things stand, and the
   single next step you are about to take. Do not recite the whole note.
3. Before relying on any file, function, commit, or flag the note names, verify it
   still exists. The note reflects what was true when written; the repository may
   have moved. Re-check anything the note marked believed-but-unverified.
4. Continue the work from the next step. The note is your context; do not rebuild
   it from scratch.

## Output

Open with the two-or-three-line resume summary, then proceed with the work.
