#!/usr/bin/env python3
import hashlib, json, pathlib, sys

root = pathlib.Path(sys.argv[1])
manifest = root / "MANIFEST.sha256"
assert manifest.is_file() and (root / "MANIFEST.modes").is_file()
for line in manifest.read_text().splitlines():
    digest, name = line.split("  ", 1)
    assert hashlib.sha256((root / name).read_bytes()).hexdigest() == digest
for config in ("original", "final"):
    raw = root / "runs" / config / "raw"
    for name in ("setup.txt", "prompt.txt", "final.txt", "transcript.jsonl", "stderr.txt", "status-after.txt", "head-after.txt"):
        assert (raw / name).is_file()
    for line in (raw / "transcript.jsonl").read_text().splitlines():
        json.loads(line)
print("run artifacts valid")
