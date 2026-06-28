# handoff

An agent skill, for both Claude Code and Codex CLI, that ends a work session by writing a lean, resumable note, so a fresh session picks up the work without re-reading the whole conversation. Start cold, resume warm, keep your sessions short and cheap.

## The problem

Long sessions get slow and expensive. Every turn carries the entire history along, the context eventually gets summarized or dropped, and continuing tomorrow means replaying hours of conversation. Keeping one giant session alive just to preserve context is the costly way to stay continuous, and it still loses the thread in the end.

The lean way is the opposite: capture the few things that actually matter in a durable note, then start a fresh, cheap session that reads a screenful and resumes. This matters most when you are watching a usage cap, but shorter sessions are faster and clearer for everyone.

## What it does

The skill writes a handoff note when a session winds down, and reads it back to resume.

- **Captures state, not transcript.** Goal, what is done, what is in progress, decisions and why, the next step, and pointers to the key files and commits.
- **Why over what.** The repository already records what changed. The note records why a path was chosen, which is the expensive thing to rediscover.
- **Points, does not paste.** References `path:line`, commit SHAs, and URLs instead of copying code, so the note stays correct and tiny.
- **Confirmed versus assumed.** Separates verified work from believed-but-unverified, so a resume never trusts a stale claim.
- **Lean by design.** Targets a screenful. A handoff is an index, not a log.

## File structure

```
handoff/
├── .claude-plugin/
│   ├── plugin.json       # plugin manifest (name, version, metadata)
│   └── marketplace.json  # one-plugin marketplace, so it installs from this repo
├── skills/
│   └── handoff/
│       ├── SKILL.md      # the rules the agent loads (Claude Code or Codex)
│       └── references/
│           └── patterns.md  # template, good/bad examples, storage, chaining
├── commands/
│   ├── save.md           # /handoff:save, write the note now
│   └── resume.md         # /handoff:resume, load the newest note and continue
├── examples/
│   ├── good-handoff.md   # an exemplary note that obeys every rule
│   └── bad-handoff.md    # the same work written as a transcript, and why it fails
├── README.md             # this file
├── LICENSE               # MIT
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── SECURITY.md
└── CITATION.cff
```

`skills/handoff/SKILL.md` carries the rules and triggers. `skills/handoff/references/patterns.md` holds the template, good-versus-bad example entries, the `.handoffs/` storage layout, and how to chain notes across several sessions, which Claude reads when it needs the detail.

## Examples

`examples/` holds a complete handoff note and its badly-written twin, so the difference between a note you can resume from and one you cannot is concrete:

- [`examples/good-handoff.md`](examples/good-handoff.md) leads with the next step, splits confirmed work from believed-but-unverified, records why each decision was made, and points at `path:line` and commit SHAs instead of pasting code.
- [`examples/bad-handoff.md`](examples/bad-handoff.md) is the same work as a transcript: relative dates, pasted code, no clear next step, and confirmed mixed with assumed. Its header comment lists exactly what makes it fail a resume.

## Install

Two ways to install, depending on whether you want a managed plugin or a plain skill.

### As a plugin (from this repo's marketplace)

In Claude Code, add the marketplace and install the plugin:

```
/plugin marketplace add Kyaa-A/handoff
/plugin install handoff@handoff
```

You get version tracking, one-command updates, and the namespaced commands `/handoff:save` and `/handoff:resume`.

### As a plain skill (for a bare `/handoff`)

Copy the skill folder into your personal skills directory:

```bash
git clone https://github.com/Kyaa-A/handoff.git
cp -r handoff/skills/handoff ~/.claude/skills/handoff
```

Installed this way the skill triggers automatically, but the `/handoff:save` and `/handoff:resume` commands come only with the plugin install above.

### On Codex CLI

Codex uses the same skill format, so the `skills/handoff` folder drops straight into your Codex skills directory:

```bash
git clone https://github.com/Kyaa-A/handoff.git
cp -r handoff/skills/handoff ~/.agents/skills/handoff
```

Codex auto-invokes it when your prompt matches the `description` (same as Claude Code), or you can call it explicitly by typing `$handoff`. Run `/skills` to confirm it loaded. For a project-scoped install, copy it into `.agents/skills/handoff` in the repo instead. (Codex reads skills from `.agents/skills`; older builds used `~/.codex/skills`, see the [skills docs](https://developers.openai.com/codex/skills).)

Either way, the agent, Claude Code or Codex, discovers the skill automatically via the `description` field in `SKILL.md`. No configuration needed.

## Usage

You do not have to invoke it manually. Ask Claude to pause or save and it writes the note on its own:

- "Let's wrap up, save my progress."
- "I'm running low, hand this off so I can continue in a fresh session."
- "Pick up where I left off." (resumes from the newest note)

To run it deliberately with the plugin install, use `/handoff:save` to write a note and `/handoff:resume` to continue from the latest one. On Codex, the same phrases trigger it automatically, or invoke it explicitly with `$handoff` ("`$handoff` save my progress" / "`$handoff` pick up where I left off"). Notes land in `.handoffs/` in your project and are gitignored by default; commit them only when you want a shared, team-visible handoff.

## Commands

The plugin install adds two namespaced slash commands:

| Command | What it does | Argument |
| --- | --- | --- |
| `/handoff:save [slug]` | Writes a handoff note for the current session to `.handoffs/YYYY-MM-DD-<slug>.md`: the single next step, the goal, what is done and confirmed, what is in progress, the working state, the decisions and why, the blockers and open questions, and pointers to the key files and commits. Grounds the confirmed list in real evidence (git status, a test run), gitignores `.handoffs/` by default, and commits nothing else. | Optional topic slug for the filename. Defaults to one derived from the current work. |
| `/handoff:resume [path]` | Loads the newest note in `.handoffs/`, states the goal, current state, and next step in two or three lines, verifies the files and commits it names still exist, then continues the work from there. | Optional path to a specific note. Defaults to the newest by date, breaking same-day ties by modification time. |

The `handoff` skill itself triggers automatically on phrases like the ones above, so neither command is required, they are the manual buttons for the same save and resume loop.

## License

MIT. Copyright (c) 2026 Asnari (Kyaa-A). See [LICENSE](LICENSE).
