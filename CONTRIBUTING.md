# Contributing to handoff

Thanks for your interest in improving handoff. This is a Claude Agent Skill: a small set of Markdown files that teach Claude to write and read resumable session notes. Contributions are mostly content: clearer rules, better example notes, and patterns that make a handoff cheaper to write and safer to resume from.

## What lives where

- `skills/handoff/SKILL.md`: the rules Claude loads, plus the `description` that triggers the skill. Keep it tight; this is always in context.
- `skills/handoff/references/patterns.md`: the template, good-versus-bad examples, storage layout, and chaining. Claude reads this on demand, so detail belongs here, not in `SKILL.md`.
- `commands/save.md` and `commands/resume.md`: the namespaced `/handoff:save` and `/handoff:resume` commands.
- `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`: package the skill as an installable plugin and a one-plugin marketplace. Touch these only when changing packaging metadata (name, version, description).
- `README.md`: the human-facing overview. Keep it in sync when you change the rules.

## Principles

- **State, not transcript.** A handoff captures where work stands, not what happened. Any new guidance should push toward a leaner, more resumable note.
- **Why over what.** The repository records what changed; the note records why. Examples should show reasons being preserved, not diffs being restated.
- **Point, do not paste.** Favor `path:line`, commit SHAs, and links over copied code in every example.
- **Lean.** A handoff is a screenful. No filler, no emojis. The structure carries the weight.

## Proposing a change

1. Open an issue describing the resume failure the change prevents (for example, a handoff that was too vague to act on, or one that aged badly).
2. Fork the repo, branch, and make the change.
3. If you add or change a rule in `skills/handoff/SKILL.md`, update `skills/handoff/references/patterns.md` and `README.md` to match.
4. Open a PR. Use [Conventional Commits](https://www.conventionalcommits.org/) for the title (e.g. `feat: add per-session frontmatter for filtering`).

## Testing a change locally

This skill has no build step. To try it:

1. Copy the skill into your Claude skills directory: `cp -r skills/handoff ~/.claude/skills/handoff` (for Claude Code). Or install it as a plugin. See the README.
2. Do a little throwaway work, then ask Claude to "save my progress" and inspect the note it writes to `.handoffs/`.
3. Start a fresh session and ask it to "pick up where I left off." Confirm the resume is accurate and acts from the note rather than guessing.

To validate the plugin and marketplace manifests, run `claude plugin validate .` from the repo root.

## Scope

handoff is deliberately focused on session continuity: writing a resumable note and reading it back. Full project memory, knowledge bases, and team wikis are adjacent but out of scope. When in doubt, open an issue first.
