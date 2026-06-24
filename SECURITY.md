# Security Policy

handoff is a documentation-only Claude Agent Skill: it ships Markdown files (`SKILL.md`, `references/patterns.md`, and the command prompts) with no executable code, no build step, and no runtime. The practical security surface is small. But skill content becomes instructions an AI agent will follow, and the notes it writes can capture project detail, so a few things are worth taking seriously.

## Reporting a vulnerability

Please report security concerns privately to **asnaripacalna@gmail.com** rather than opening a public issue. Include:

- a description of the issue and its impact,
- the file and lines involved, and
- steps to reproduce, if applicable.

Expect an initial response within a few days. Please allow a reasonable window to address the issue before any public disclosure.

## In scope

- Content in the skill or command files that could induce an agent to act unsafely, leak data, or write secrets into a handoff note.
- Guidance that would cause handoff notes to be committed or shared when they should stay local.
- Misleading or hidden instructions that could cause unsafe behavior in a tool-using agent.

## A note on handoff contents

Handoff notes can contain local paths, in-progress reasoning, and project detail. The skill gitignores `.handoffs/` by default for this reason. If you choose to commit notes for a team handoff, review them first the way you would any committed file: do not record secrets, tokens, or credentials in a note.

## Out of scope

- Vulnerabilities in Claude, Claude Code, or any host application that loads this skill: report those to their respective vendors.
- General workflow disagreements; those are regular issues or PRs.

## Supported versions

This project tracks a single line of development on `main`. Fixes land on `main`; there are no separately maintained release branches.
