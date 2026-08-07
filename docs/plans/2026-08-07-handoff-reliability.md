# Handoff Reliability Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add reproducible save/resume evaluations and use their failures to improve handoff accuracy without bloating notes.

**Architecture:** Store realistic prompts and objective assertions under `evals/`, snapshot the current skill as the baseline, then compare baseline and revised outputs. Keep core behavior in `SKILL.md` and move detailed mechanics or examples to `references/patterns.md`.

**Tech Stack:** Markdown Agent Skills, JSON evaluation fixtures, Python benchmark utilities supplied by `skill-creator`, Git.

---

### Task 1: Define reliability evaluations

**Files:**
- Create: `evals/evals.json`
- Create: `evals/fixtures/dirty-worktree-context.md`
- Create: `evals/fixtures/partial-feature-context.md`
- Create: `evals/fixtures/stale-handoff.md`
- Create: `evals/fixtures/cross-machine-context.md`

**Step 1: Write five evaluation prompts**

Cover clean save, dirty save, partial implementation, stale resume, and
cross-machine resume. Give each prompt an expected output and relevant fixture.

**Step 2: Add objective assertions**

Assert the required next action, verified/unverified separation, Git state,
decision rationale, exact evidence, stale-pointer checks, and preservation of
user-owned changes. Add a negative assertion that no unrun test is described as
passing.

**Step 3: Validate the JSON**

Run: `python -m json.tool evals/evals.json >/dev/null`

Expected: exit 0.

**Step 4: Commit**

```bash
git add evals
git commit -m "test: add handoff reliability evals"
```

### Task 2: Capture the baseline

**Files:**
- Create: sibling workspace `../handoff-workspace/skill-snapshot/`
- Create: run outputs under `../handoff-workspace/iteration-1/`

**Step 1: Snapshot the original skill**

Copy `skills/handoff/` to the workspace snapshot without modifying the source
repository.

**Step 2: Run every prompt against the snapshot**

Execute save and resume prompts with the original skill. Store each result in
its evaluation directory and capture token and duration metadata.

**Step 3: Grade the outputs**

Evaluate every assertion against the generated note or resume behavior. Save
`grading.json` with `text`, `passed`, and `evidence` fields.

**Step 4: Aggregate results**

Run the skill-creator benchmark aggregator and record baseline pass rate, token
usage, and recurring qualitative failures.

### Task 3: Refine save behavior from failures

**Files:**
- Modify: `skills/handoff/SKILL.md`
- Modify if detail is needed: `skills/handoff/references/patterns.md`
- Modify if behavior changes: `commands/save.md`

**Step 1: Add a failing assertion-specific regression case**

If a baseline failure is not already isolated, narrow its prompt and assertion
in `evals/evals.json`.

**Step 2: Run the affected baseline case**

Expected: the relevant assertion fails against `skill-snapshot`.

**Step 3: Make the smallest save-rule change**

Add only rules justified by observed failures: gather fresh Git/test evidence,
record exact commands and results, identify user-owned dirty changes, and place
unconfirmed claims under `Believed but unverified`.

**Step 4: Run the affected case against the revised skill**

Expected: the targeted assertion passes and the note remains approximately one
screenful.

**Step 5: Commit**

```bash
git add skills/handoff/SKILL.md skills/handoff/references/patterns.md commands/save.md evals/evals.json
git commit -m "fix: improve handoff save accuracy"
```

Stage only files actually changed.

### Task 4: Refine resume behavior from failures

**Files:**
- Modify: `skills/handoff/SKILL.md`
- Modify if detail is needed: `skills/handoff/references/patterns.md`
- Modify if behavior changes: `commands/resume.md`

**Step 1: Run stale and conflicting-note cases**

Expected: capture any failures to validate named files, commits, dirty state, or
believed-but-unverified claims before acting.

**Step 2: Make the smallest resume-rule change**

Require targeted verification of stale pointers and uncertainty while avoiding
a broad repository rediscovery pass. Define how to choose among conflicting
same-day notes without silently trusting filename order.

**Step 3: Rerun the affected cases**

Expected: all resume assertions pass, and output moves directly to the recorded
next action after targeted checks.

**Step 4: Commit**

```bash
git add skills/handoff/SKILL.md skills/handoff/references/patterns.md commands/resume.md
git commit -m "fix: harden handoff resume checks"
```

Stage only files actually changed.

### Task 5: Run the comparative evaluation

**Files:**
- Create: revised outputs under `../handoff-workspace/iteration-1/`
- Modify if promises changed: `README.md`

**Step 1: Run all prompts against the revised skill**

Capture outputs, timing, and tokens beside the baseline results.

**Step 2: Grade and aggregate**

Run the same assertions for both configurations and generate the benchmark.

Expected: revised pass rate exceeds baseline, no critical assertion regresses,
and routine notes remain within the screenful target.

**Step 3: Inspect qualitative results**

Check that notes are actionable rather than transcript-like and that resume does
not perform unrelated rediscovery.

**Step 4: Update documentation if needed**

Document only user-visible behavior that changed.

**Step 5: Commit**

```bash
git add README.md
git commit -m "docs: describe reliable handoff checks"
```

Skip this commit when README does not need a change.

### Task 6: Final verification

**Files:**
- Verify all modified repository files.

**Step 1: Validate fixtures**

Run: `python -m json.tool evals/evals.json >/dev/null`

Expected: exit 0.

**Step 2: Confirm repository state**

Run: `git status --short && git log --oneline -5`

Expected: only intended files are present; commits match the plan.

**Step 3: Review the final diff**

Run: `git diff origin/main...HEAD --check`

Expected: exit 0 with no whitespace errors.

**Step 4: Report evidence**

Report baseline versus revised assertion pass rate, token usage, scenarios run,
and any remaining limitations.
