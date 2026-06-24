# handoff

A Claude Agent Skill that ends a work session by writing a lean, resumable note, so a fresh session picks up the work without re-reading the whole conversation. Start cold, resume warm, keep your sessions short and cheap.

## The problem

Long sessions get slow and expensive. Every turn carries the entire history along, the context eventually gets summarized or dropped, and continuing tomorrow means replaying hours of conversation. Keeping one giant session alive just to preserve context is the costly way to stay continuous, and it still loses the thread in the end.

The lean way is the opposite: capture the few things that actually matter in a durable note, then start a fresh, cheap session that reads a screenful and resumes. This matters most when you are watching a usage cap, but shorter sessions are faster and clearer for everyone.

## What it does

The skill writes a handoff note when a session winds down, and reads it back to resume.

- **Captures state, not transcript.** Goal, what is done, what is in progress, decisions and why, the next step, and pointers to the key files and commits.
- **Why over what.** The repository already records what changed. The note records why a path was chosen, which is the expensive thing to rediscover.
- **Points, does not paste.** References `path:line`, commit SHAs, and URLs instead of copying code, so the note stays correct and tiny.
- **Confirmed versus assumed.** Separates verified work from believed-but-unproven, so a resume never trusts a stale claim.
- **Lean by design.** Targets a screenful. A handoff is an index, not a log.

## File structure

```
handoff/
├── .claude-plugin/
│   ├── plugin.json       # plugin manifest (name, version, metadata)
│   └── marketplace.json  # one-plugin marketplace, so it installs from this repo
├── skills/
│   └── handoff/
│       ├── SKILL.md      # the rules Claude loads
│       └── references/
│           └── patterns.md  # template, good/bad examples, storage, chaining
├── commands/
│   ├── save.md           # /handoff:save, write the note now
│   └── resume.md         # /handoff:resume, load the newest note and continue
├── README.md             # this file
├── LICENSE               # MIT
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── SECURITY.md
└── CITATION.cff
```

`skills/handoff/SKILL.md` carries the rules and triggers. `skills/handoff/references/patterns.md` holds the template, good-versus-bad example entries, the `.handoffs/` storage layout, and how to chain notes across several sessions, which Claude reads when it needs the detail.

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

Either way, Claude discovers the skill automatically via the `description` field in `SKILL.md`. No configuration needed.

## Usage

You do not have to invoke it manually. Ask Claude to pause or save and it writes the note on its own:

- "Let's wrap up, save my progress."
- "I'm running low, hand this off so I can continue in a fresh session."
- "Pick up where I left off." (resumes from the newest note)

To run it deliberately with the plugin install, use `/handoff:save` to write a note and `/handoff:resume` to continue from the latest one. Notes land in `.handoffs/` in your project and are gitignored by default; commit them only when you want a shared, team-visible handoff.

## License

MIT. Copyright (c) 2026 Asnari (Kyaa-A). See [LICENSE](LICENSE).
