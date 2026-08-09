# Handoff eval harness

Prerequisites: Bash, Git, Python 3, pnpm, and an authenticated `codex` CLI.

Validate all deterministic fixtures offline:

```bash
bash evals/validate-all.sh
```

Capture a blind raw run from immutable Git snapshots:

```bash
bash evals/harness/run.sh \
  --original 15b6f7620faab94a3452666340637a08a6f9337f \
  --final HEAD --scenario cross-machine-resume \
  --output /tmp/handoff-eval
python3 evals/harness/validate-run.py /tmp/handoff-eval
```

Use `--dry-run` to validate arguments and fixture setup without invoking Codex.
The runner records prompts, setup output, JSONL, stderr, final output, post-state,
environment, file modes, and SHA-256 manifests. It does not grade semantics:
grade atomic assertions against raw evidence and record decisions in a benchmark
JSON. Codex has no supported random seed, so repeat samples when variance matters.
