#!/usr/bin/env bash
set -euo pipefail

root_path="$(mktemp -d "${TMPDIR:-/tmp}/handoff-cross-machine-eval.XXXXXX")"
remote_path="$root_path/search-api.git"
source_path="$root_path/source-search-api"
destination_path="$root_path/destination-search-api"

git init -q --bare "$remote_path"
git clone -q "$remote_path" "$source_path"
git -C "$source_path" config user.email eval@example.test
git -C "$source_path" config user.name "Handoff Eval"
git -C "$source_path" switch -q -c main
mkdir -p "$source_path/src/documents"
printf '%s\n' 'export const listDocuments = () => [];' > "$source_path/src/documents/list.ts"
git -C "$source_path" add .
git -C "$source_path" commit -qm "feat: add document listing"
git -C "$source_path" push -q -u origin main
git --git-dir="$remote_path" symbolic-ref HEAD refs/heads/main

git -C "$source_path" switch -q -c feat/document-cursors
cat > "$source_path/src/documents/list.ts" <<'EOF'
export const cursorFields = ["created_at", "id"];
export const listDocuments = () => cursorFields;
EOF
cat > "$source_path/src/documents/cursor.test.ts" <<'EOF'
import assert from "node:assert/strict";
import test from "node:test";
import { cursorFields, listDocuments } from "./list.ts";

for (const name of [
  "uses created_at first",
  "uses id as the tie-breaker",
  "keeps two cursor fields",
  "returns the cursor fields",
  "keeps deterministic ordering",
  "does not use offset",
  "does not duplicate created_at",
  "does not duplicate id",
  "keeps the tuple stable",
]) {
  test(name, () => {
    assert.deepEqual(cursorFields, ["created_at", "id"]);
    assert.deepEqual(listDocuments(), cursorFields);
  });
}
EOF
cat > "$source_path/package.json" <<'EOF'
{
  "name": "handoff-cross-machine-eval",
  "private": true,
  "type": "module",
  "scripts": {
    "test": "node --test"
  }
}
EOF
git -C "$source_path" add package.json src/documents
git -C "$source_path" commit -qm "feat: add document cursors"
feature_sha="$(git -C "$source_path" rev-parse HEAD)"
git -C "$source_path" push -q -u origin feat/document-cursors
mkdir -p "$source_path/tmp"
printf '%s\n' '{"cursor":"machine-local"}' > "$source_path/tmp/page-debug.json"

git clone -q --no-local --single-branch --branch main "$remote_path" "$destination_path"
git -C "$destination_path" config user.email eval@example.test
git -C "$destination_path" config user.name "Handoff Eval"

printf 'SOURCE_PATH=%s\nDESTINATION_PATH=%s\nREMOTE_PATH=%s\nFEATURE_SHA=%s\n' \
  "$source_path" "$destination_path" "$remote_path" "$feature_sha"
