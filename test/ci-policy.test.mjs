import assert from 'node:assert/strict';
import { mkdtemp, mkdir, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { resolve } from 'node:path';
import test from 'node:test';
import { assertSafeWorkflows } from '../scripts/ci-policy.mjs';

const sha = '1'.repeat(40);
test('repository workflows satisfy CI policy', async () => assertSafeWorkflows(resolve(import.meta.dirname, '..')));
test('scans all workflow YAML forms', async () => {
  const root = await mkdtemp(resolve(tmpdir(), 'handoff-ci-'));
  await mkdir(resolve(root, '.github/workflows'), { recursive: true });
  await writeFile(resolve(root, '.github/workflows/ci.yml'), `steps:\n  - uses: actions/checkout@${sha}\n`);
  await writeFile(resolve(root, '.github/workflows/extra.yaml'), `steps:\n  - { "uses": actions/setup-node@${sha} }\n`);
  await assertSafeWorkflows(root);
});
test('rejects job-level, disallowed, unpinned, and uppercase uses', async () => {
  for (const uses of [`evil/action@${sha}`, 'actions/checkout@v4', `actions/checkout@${'A'.repeat(40)}`]) {
    const root = await mkdtemp(resolve(tmpdir(), 'handoff-ci-'));
    await mkdir(resolve(root, '.github/workflows'), { recursive: true });
    await writeFile(resolve(root, '.github/workflows/ci.yml'), `jobs:\n  attack:\n    "uses": ${uses}\n`);
    await assert.rejects(assertSafeWorkflows(root));
  }
});
