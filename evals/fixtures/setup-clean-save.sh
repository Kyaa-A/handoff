#!/usr/bin/env bash
set -euo pipefail

repo_path="$(mktemp -d "${TMPDIR:-/tmp}/handoff-clean-eval.XXXXXX")"
git -C "$repo_path" init -q
touch "$repo_path/.git/handoff-eval-root"
git -C "$repo_path" config user.email eval@example.test
git -C "$repo_path" config user.name "Handoff Eval"
git -C "$repo_path" switch -q -c feat/audit-export

mkdir -p "$repo_path/src/audit"
cat > "$repo_path/src/audit/export.ts" <<'EOF'
import { Readable } from "node:stream";

export type AuditRow = {
  id: string;
  action: string;
  actor: string;
};

const escapeCsv = (value: string): string => {
  if (!/[",\n]/.test(value)) return value;
  return `"${value.replaceAll('"', '""')}"`;
};

const encodeRow = (row: AuditRow): string =>
  [row.id, row.action, row.actor].map(escapeCsv).join(",");

export async function* streamAuditCsv(
  rows: AsyncIterable<AuditRow>,
): AsyncGenerator<string> {
  yield "id,action,actor\n";
  for await (const row of rows) {
    yield `${encodeRow(row)}\n`;
  }
}

export const createAuditCsvStream = (
  rows: AsyncIterable<AuditRow>,
): Readable => Readable.from(streamAuditCsv(rows));
EOF

line_count="$(wc -l < "$repo_path/src/audit/export.ts" | tr -d ' ')"
while [ "$line_count" -lt 63 ]; do
  printf '\n' >> "$repo_path/src/audit/export.ts"
  line_count=$((line_count + 1))
done
printf '%s\n' '// TODO: add the optional UTF-8 BOM before the CSV header.' >> "$repo_path/src/audit/export.ts"

cat > "$repo_path/src/audit/export.test.ts" <<'EOF'
import { strict as assert } from "node:assert";
import test from "node:test";
import { streamAuditCsv } from "./export.ts";

async function collect(chunks: AsyncIterable<string>): Promise<string> {
  let csv = "";
  for await (const chunk of chunks) csv += chunk;
  return csv;
}

test("streams escaped audit rows with real newlines", async () => {
  const rows = (async function* () {
    yield { id: "1", action: "view,export", actor: "Ada" };
  })();

  assert.equal(
    await collect(streamAuditCsv(rows)),
    'id,action,actor\n1,"view,export",Ada\n',
  );
});
EOF

cat > "$repo_path/package.json" <<'EOF'
{
  "name": "handoff-clean-eval",
  "private": true,
  "type": "module",
  "scripts": {
    "test": "node --test"
  }
}
EOF

git -C "$repo_path" add package.json src
GIT_AUTHOR_DATE='2026-08-07T00:00:00Z' \
GIT_COMMITTER_DATE='2026-08-07T00:00:00Z' \
  git -C "$repo_path" commit -qm "feat: stream audit CSV export"

printf 'REPO_PATH=%s\nHEAD_SHA=%s\n' "$repo_path" "$(git -C "$repo_path" rev-parse HEAD)"
