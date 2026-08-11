import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { mkdtemp, mkdir, readFile, readdir, stat, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { spawn, spawnSync } from 'node:child_process';
import test from 'node:test';

const repoRoot = resolve(import.meta.dirname, '..');
const checker = join(repoRoot, 'scripts/check-update.mjs');

async function fixture(platform = 'claude', version = '0.2.0') {
  const root = await mkdtemp(join(tmpdir(), 'handoff-plugin-'));
  const data = await mkdtemp(join(tmpdir(), 'handoff-data-'));
  const manifestDir = platform === 'claude' ? '.claude-plugin' : '.codex-plugin';
  await mkdir(join(root, manifestDir));
  await writeFile(join(root, manifestDir, 'plugin.json'), JSON.stringify({ name: 'handoff', version }));
  return { root, data };
}

async function serve(handler) {
  const server = createServer(handler);
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const { port } = server.address();
  return {
    url: `http://127.0.0.1:${port}/manifest.json`,
    close: () => new Promise((resolve) => server.close(resolve)),
  };
}

async function run({ platform = 'claude', root, data, url, extraEnv = {} }) {
  const child = spawn(process.execPath, [checker, '--platform', platform, '--root', root, '--data', data], {
    env: {
      ...process.env,
      NODE_ENV: 'test',
      HANDOFF_UPDATE_TEST_URL: url,
      HANDOFF_UPDATE_TTL_MS: '86400000',
      ...extraEnv,
    },
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  let stdout = '';
  let stderr = '';
  child.stdout.setEncoding('utf8').on('data', (chunk) => { stdout += chunk; });
  child.stderr.setEncoding('utf8').on('data', (chunk) => { stderr += chunk; });
  const code = await new Promise((resolve) => child.on('close', resolve));
  return { code, stdout, stderr };
}

for (const platform of ['claude', 'codex']) {
  test(`${platform}: newer version produces one safe terminal warning`, async () => {
    const { root, data } = await fixture(platform);
    const remote = await serve((_req, res) => {
      res.setHeader('content-type', 'application/json');
      res.end(JSON.stringify({ name: 'handoff', version: '0.3.0' }));
    });
    try {
      const result = await run({ platform, root, data, url: remote.url });
      assert.equal(result.code, 0);
      assert.equal(result.stderr, '');
      const lines = result.stdout.trim().split('\n');
      assert.equal(lines.length, 1);
      const output = JSON.parse(lines[0]);
      assert.equal(output.continue, true);
      assert.match(output.systemMessage, /handoff 0\.2\.0.*0\.3\.0/s);
      assert.equal('additionalContext' in output, false);
      const messageLines = output.systemMessage.split('\n').map((line) => line.trim());
      if (platform === 'claude') {
        assert.ok(messageLines.includes('claude plugin marketplace update handoff'));
        assert.ok(messageLines.includes('claude plugin update handoff@handoff'));
        assert.match(output.systemMessage, /\/reload-plugins/);
      } else {
        assert.ok(messageLines.includes('codex plugin marketplace upgrade handoff'));
        assert.ok(messageLines.includes('codex plugin remove handoff@handoff'));
        assert.ok(messageLines.includes('codex plugin add handoff@handoff'));
        assert.match(output.systemMessage, /new Codex session/i);
      }
      assert.doesNotMatch(result.stdout, /127\.0\.0\.1|manifest\.json|token/i);
    } finally {
      await remote.close();
    }
  });
}

test('equal and older versions are silent', async () => {
  for (const version of ['0.2.0', '0.1.9']) {
    const { root, data } = await fixture();
    const remote = await serve((_req, res) => res.end(JSON.stringify({ name: 'handoff', version })));
    try {
      assert.deepEqual(await run({ root, data, url: remote.url }), { code: 0, stdout: '', stderr: '' });
    } finally {
      await remote.close();
    }
  }
});

test('semver comparison preserves arbitrary-length numeric components', async () => {
  const cases = [
    ['9007199254740992.0.0', '9007199254740993.0.0', true],
    ['9007199254740993.0.0', '9007199254740992.999999999999999999999.999999999999999999999', false],
    ['9007199254740993.12345678901234567890.7', '9007199254740993.12345678901234567890.7', false],
  ];
  for (const [installed, latest, warns] of cases) {
    const { root, data } = await fixture('claude', installed);
    const remote = await serve((_req, res) => res.end(JSON.stringify({ name: 'handoff', version: latest })));
    try {
      const result = await run({ root, data, url: remote.url });
      assert.equal(result.code, 0);
      assert.equal(result.stderr, '');
      assert.equal(result.stdout.length > 0, warns);
    } finally {
      await remote.close();
    }
  }
});

test('successful no-update result is cached and avoids a second request', async () => {
  const { root, data } = await fixture();
  let requests = 0;
  const remote = await serve((_req, res) => {
    requests += 1;
    res.end(JSON.stringify({ name: 'handoff', version: '0.2.0' }));
  });
  try {
    await run({ root, data, url: remote.url });
    await run({ root, data, url: remote.url });
    assert.equal(requests, 1);
    const entries = await readdir(data);
    assert.deepEqual(entries, ['update-check.json']);
    assert.equal((await stat(join(data, 'update-check.json'))).mode & 0o077, 0);
  } finally {
    await remote.close();
  }
});

test('disabled checker is silent and makes no request', async () => {
  const { root, data } = await fixture();
  let requests = 0;
  const remote = await serve((_req, res) => { requests += 1; res.end('{}'); });
  try {
    const result = await run({ root, data, url: remote.url, extraEnv: { HANDOFF_UPDATE_CHECK: '0' } });
    assert.deepEqual(result, { code: 0, stdout: '', stderr: '' });
    assert.equal(requests, 0);
  } finally {
    await remote.close();
  }
});

test('network, HTTP, timeout, JSON, schema, and semver failures are silent', async () => {
  const cases = [
    async () => serve((_req, res) => { res.statusCode = 404; res.end('secret body'); }),
    async () => serve((_req, res) => res.end('{bad json')),
    async () => serve((_req, res) => res.end(JSON.stringify({ name: 'handoff', version: 'v0.3.0' }))),
    async () => serve((_req, res) => res.end(JSON.stringify({ name: 'handoff', version: '0.3.0-beta.1' }))),
    async () => serve((_req, res) => res.end(JSON.stringify({ name: 'handoff', version: '00.3.0' }))),
    async () => serve((_req, res) => res.end(JSON.stringify({ name: 'other', version: '0.3.0' }))),
    async () => serve(() => {}),
  ];
  for (let index = 0; index < cases.length; index += 1) {
    const { root, data } = await fixture();
    const remote = await cases[index]();
    try {
      const extraEnv = index === cases.length - 1 ? { HANDOFF_UPDATE_TIMEOUT_MS: '30' } : {};
      assert.deepEqual(await run({ root, data, url: remote.url, extraEnv }), { code: 0, stdout: '', stderr: '' });
    } finally {
      await remote.close();
    }
  }
  const { root, data } = await fixture();
  assert.deepEqual(await run({ root, data, url: 'http://127.0.0.1:1/secret?token=value' }), { code: 0, stdout: '', stderr: '' });
});

test('malformed installed version is silent', async () => {
  const { root, data } = await fixture('claude', '0.2.0-beta.1');
  let requests = 0;
  const remote = await serve((_req, res) => { requests += 1; res.end(JSON.stringify({ name: 'handoff', version: '0.3.0' })); });
  try {
    assert.deepEqual(await run({ root, data, url: remote.url }), { code: 0, stdout: '', stderr: '' });
    assert.equal(requests, 0);
  } finally {
    await remote.close();
  }
});

test('unavailable plugin data directory does not block an update warning', async () => {
  const { root, data } = await fixture();
  await writeFile(join(data, 'not-a-directory'), 'occupied');
  const unavailable = join(data, 'not-a-directory', 'child');
  const remote = await serve((_req, res) => res.end(JSON.stringify({ name: 'handoff', version: '0.3.0' })));
  try {
    const result = await run({ root, data: unavailable, url: remote.url });
    assert.equal(result.code, 0);
    assert.equal(result.stderr, '');
    assert.equal(JSON.parse(result.stdout).continue, true);
  } finally {
    await remote.close();
  }
});

test('checker never writes inside the plugin root and cache replacement is atomic', async () => {
  const { root, data } = await fixture();
  const before = await readdir(root, { recursive: true });
  const remote = await serve((_req, res) => res.end(JSON.stringify({ name: 'handoff', version: '0.2.0' })));
  try {
    await run({ root, data, url: remote.url });
    assert.deepEqual(await readdir(root, { recursive: true }), before);
    assert.deepEqual(await readdir(data), ['update-check.json']);
    assert.equal(JSON.parse(await readFile(join(data, 'update-check.json'), 'utf8')).version, '0.2.0');
  } finally {
    await remote.close();
  }
});

test('expired cache is safely replaced on a second write', async () => {
  const { root, data } = await fixture();
  let requests = 0;
  const remote = await serve((_req, res) => {
    requests += 1;
    res.end(JSON.stringify({ name: 'handoff', version: '0.2.0' }));
  });
  try {
    const extraEnv = { HANDOFF_UPDATE_TTL_MS: '0', HANDOFF_UPDATE_TEST_WINDOWS_REPLACE: '1' };
    await run({ root, data, url: remote.url, extraEnv });
    const first = JSON.parse(await readFile(join(data, 'update-check.json'), 'utf8'));
    await new Promise((resolve) => setTimeout(resolve, 2));
    await run({ root, data, url: remote.url, extraEnv });
    const second = JSON.parse(await readFile(join(data, 'update-check.json'), 'utf8'));
    assert.equal(requests, 2);
    assert.ok(second.checkedAt > first.checkedAt);
    assert.deepEqual(await readdir(data), ['update-check.json']);
  } finally {
    await remote.close();
  }
});

test('hook and marketplace manifests parse and versions match', async () => {
  const paths = [
    'package.json',
    '.claude-plugin/plugin.json',
    '.claude-plugin/marketplace.json',
    '.codex-plugin/plugin.json',
    '.agents/plugins/marketplace.json',
    'hooks/hooks.json',
    'hooks/codex-hooks.json',
  ];
  const documents = Object.fromEntries(await Promise.all(paths.map(async (path) => [path, JSON.parse(await readFile(join(repoRoot, path), 'utf8'))])));
  assert.equal(documents['.claude-plugin/plugin.json'].version, '0.4.1');
  assert.equal(documents['.codex-plugin/plugin.json'].version, '0.4.1');
  assert.equal(documents['.agents/plugins/marketplace.json'].plugins[0].version, '0.4.1');
  assert.equal(documents['package.json'].version, '0.4.1');
  assert.equal(documents['hooks/hooks.json'].hooks.SessionStart[0].matcher, 'startup');
  assert.equal(documents['hooks/hooks.json'].hooks.SessionStart[0].hooks.length, 1);
  assert.equal(documents['hooks/hooks.json'].hooks.SessionStart[0].hooks[0].timeout, 5);
  assert.match(documents['hooks/hooks.json'].hooks.SessionStart[0].hooks[0].command, /\$\{CLAUDE_PLUGIN_ROOT\}/);
  assert.match(documents['hooks/hooks.json'].hooks.SessionStart[0].hooks[0].command, /\$\{CLAUDE_PLUGIN_DATA\}/);
  assert.equal(documents['hooks/codex-hooks.json'].hooks.SessionStart[0].matcher, 'startup');
  assert.equal(documents['hooks/codex-hooks.json'].hooks.SessionStart[0].hooks[0].type, 'command');
  const codexHook = documents['hooks/codex-hooks.json'].hooks.SessionStart[0].hooks[0];
  assert.equal(codexHook.timeout, 5);
  assert.match(codexHook.command, /\$PLUGIN_ROOT/);
  assert.match(codexHook.command, /\$PLUGIN_DATA/);
  assert.equal(typeof codexHook.commandWindows, 'string');

  const linuxRoot = '/tmp/Plugin Root/handoff';
  const linuxData = '/tmp/Plugin Data/handoff';
  const shell = await new Promise((resolve, reject) => {
    const child = spawn('sh', ['-c', `set -- ${codexHook.command}; printf '%s\\n' \"$@\"`], {
      env: { ...process.env, PLUGIN_ROOT: linuxRoot, PLUGIN_DATA: linuxData },
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    let stdout = '';
    let stderr = '';
    child.stdout.setEncoding('utf8').on('data', (chunk) => { stdout += chunk; });
    child.stderr.setEncoding('utf8').on('data', (chunk) => { stderr += chunk; });
    child.on('error', reject);
    child.on('close', (code) => resolve({ code, stdout, stderr }));
  });
  assert.deepEqual(shell, {
    code: 0,
    stdout: [
      'node',
      `${linuxRoot}/scripts/check-update.mjs`,
      '--platform',
      'codex',
      '--root',
      linuxRoot,
      '--data',
      linuxData,
      '',
    ].join('\n'),
    stderr: '',
  });
  assert.doesNotMatch(shell.stdout, /\$(?:\{|)PLUGIN_(?:ROOT|DATA)/);

  assert.equal(
    codexHook.commandWindows,
    'node "$env:PLUGIN_ROOT\\scripts\\check-update.mjs" --platform codex --root "$env:PLUGIN_ROOT" --data "$env:PLUGIN_DATA"',
  );
  assert.doesNotMatch(codexHook.commandWindows, /%PLUGIN_(?:ROOT|DATA)%/);

  if (spawnSync('pwsh', ['-NoProfile', '-Command', '$PSVersionTable.PSVersion.Major']).status === 0) {
    const windowsRoot = String.raw`C:\Users\Example User\.codex\plugins\handoff`;
    const windowsData = String.raw`C:\Users\Example User\.codex\plugin data\handoff`;
    const result = spawnSync('pwsh', ['-NoProfile', '-Command', `& { param([Parameter(ValueFromRemainingArguments=\$true)] \$rest) \$rest -join [Environment]::NewLine } ${codexHook.commandWindows}`], {
      env: { ...process.env, PLUGIN_ROOT: windowsRoot, PLUGIN_DATA: windowsData },
      encoding: 'utf8',
    });
    assert.equal(result.status, 0, result.stderr);
    assert.doesNotMatch(result.stdout, /\$env:PLUGIN_(?:ROOT|DATA)/);
  }
});
