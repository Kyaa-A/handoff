# Handoff Reliability Design

## Goal

Make saved handoffs reliably preserve the state and next action a fresh agent
needs, without increasing the normal note beyond a screenful.

## Approach

Use eval-driven refinement. Add realistic save and resume prompts, score the
observable output, and change the skill only where the baseline fails. Keep the
current Markdown note format and `.handoffs/` storage model.

## Evaluation scenarios

1. Clean pause after verified work.
2. Dirty worktree with user-owned changes.
3. Partially implemented feature with an exact next action.
4. Resume from a note containing stale pointers or unverified claims.
5. Cross-machine resume where local processes and uncommitted files do not travel.

Save evaluations check that the note records the correct next step, decisions
and reasons, verified versus unverified claims, exact verification evidence, and
working-tree state. Resume evaluations check that the agent reads the complete
note, validates pointers, rechecks uncertain claims, preserves dirty work, and
continues without reconstructing unrelated context.

## Skill changes

Refine `skills/handoff/SKILL.md` only where the baseline evaluations expose a
failure. Expected changes are a compact evidence-gathering sequence before save,
explicit treatment of user-owned dirty changes, exact verification commands and
results, and stale or conflicting note handling during resume.

Keep detailed examples and mechanics in `references/patterns.md` so the main
skill stays lean. Update commands and README only when their behavior or promises
change.

## Verification

Run each scenario against the original skill and the revised skill. Grade
objective assertions and inspect qualitative output for usefulness and brevity.
The revision succeeds when it improves reliability without causing routine notes
to exceed the existing screenful target.
