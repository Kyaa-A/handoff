---
name: handoff
description: Write a lean, resumable handoff note so a fresh Claude Code session can continue the work without re-reading the whole conversation. Use this skill whenever the user is wrapping up, pausing, running low on usage or context, switching machines, or says "save my progress," "hand off," "continue later," "context is getting long," "pause here," or (to resume) "pick up where I left off." It captures the goal, what is done, what is in progress, the decisions and why, the next step, and pointers to the key files and commits, then writes it to a dated handoff file so the next session starts warm instead of cold.
---

# handoff

Long sessions get slow and expensive: every turn drags the entire history along, and eventually the context is summarized or lost. The fix is not a bigger session. It is a smaller one. Capture the few things that matter in a durable note, then start fresh. The next session reads a screenful and resumes, instead of replaying hours of conversation.

This skill writes that note, and reads it back to resume. Apply it by default when a session is winding down or when the user asks to pause, save, or continue later.

## When to write a handoff

Write one when any of these is true:

- The user says to pause, save progress, wrap up, or continue later.
- The session is long and the context is getting heavy.
- The user is close to a usage cap and wants to keep going in a fresh session.
- A natural milestone is reached (a feature shipped, a decision settled) and the rest is a separate chunk of work.

When in doubt near the end of a working session, offer to write one.

## The non-negotiables

1. **Capture state, not transcript.** Record the goal, what is done, what is in progress, the next step, and the blockers. Do not narrate the play-by-play. A handoff is an index, not a log.
2. **Why over what.** Write down decisions and their reasons. The code already shows what was done; it cannot show why a path was chosen or rejected. The why is the expensive part to rediscover.
3. **Point, do not paste.** Reference files as `path:line`, name the commit SHA, link the URL or ticket. Do not copy code or large output into the note. Pointers stay correct and cost almost nothing.
4. **Absolute dates, never relative.** Write `2026-06-24`, not "today" or "yesterday." A note read next week must not lie about when it was written.
5. **Lead with the next action.** The first line of the body is the single thing the next session should do first. Everything else is support.
6. **Mark confirmed versus assumed.** Tag what was verified (tests passed, feature checked) separately from what is believed but unproven, so the next session does not trust a stale claim.
7. **Self-contained.** A fresh session with zero prior context must be able to act on the note alone. No "as discussed above." There is no above.
8. **Lean.** Target a screenful. If it grows past that, you are transcribing, not handing off. Cut.

## What to capture

A handoff note has these parts, in this order:

- **Next step** (one line): the first thing to do on resume.
- **Goal**: what this work is trying to achieve, in a sentence or two.
- **Done**: what is finished and confirmed, with `path:line` or commit pointers.
- **In progress**: what is half-built, where it stands, and what is left.
- **Decisions**: each key choice and the reason for it. Link related notes.
- **Blockers / open questions**: what is stuck, and what input is needed.
- **Pointers**: the handful of files, commits, commands, or URLs the next session will need.

Leave out anything the repository already records: file structure, what the code does, git history. Capture only what is not derivable from the project itself.

## Where it goes

Write the note to `.handoffs/YYYY-MM-DD-<slug>.md` in the working repository, where `<slug>` is a short kebab-case topic. The newest note is the resume target: sort by the date prefix, and when two notes share a date, the more recently modified one wins.

By default `.handoffs/` is local and private: add it to the project's `.gitignore` unless the user wants to commit notes for a team handoff. Say which you did.

## Resuming

On a resume request, find the newest file in `.handoffs/`, read it, and state the plan in two or three lines: the goal, where things stand, and the next step you are about to take. Then continue the work. Do not re-derive everything from scratch; the note is the context.

If a note names a file, function, commit, or flag, verify it still exists before relying on it. A handoff reflects what was true when it was written, and the repository may have moved since.

## Output

After writing a note, tell the user the path, the one-line next step, and whether you gitignored or committed it. Keep the confirmation to a few lines. For mechanics, examples of good versus bad entries, and multi-session chaining, read `references/patterns.md`.
