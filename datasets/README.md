# dist/datasets — versioned dataset backup

The training/eval datasets under `datasets/*.jsonl` are **gitignored** (see the
repo `.gitignore`: `/datasets/*.jsonl`) — they are local artifacts, so a plain
`git clone` does **not** carry them and they are otherwise unbacked. This
directory is the durable, versioned snapshot.

## Contents

- `datasets-v1-2026-07-18.tar.gz` — all 17 `datasets/*.{jsonl,json}` files
  (5712 rows total), `tar czf` with sorted, zeroed-owner entries for a stable hash.
- `MANIFEST.json` — per-file `sha256`, row count, byte size, plus the `git_commit`
  the snapshot was taken at. This is the integrity record.

Excluded on purpose: `datasets/tutorial-generation/Versteeg_Malalasekera_2ed.pdf`
is already git-tracked, so it is not duplicated here.

## Restore

```sh
tar xzf dist/datasets/datasets-v1-2026-07-18.tar.gz -C datasets/
# verify against the manifest
python3 - <<'PY'
import json, hashlib, pathlib
m = json.load(open("dist/datasets/MANIFEST.json"))
for f in m["files"]:
    h = hashlib.sha256(pathlib.Path("datasets", f["file"]).read_bytes()).hexdigest()
    print("OK " if h == f["sha256"] else "BAD", f["file"])
PY
```

## Cutting a new version

Re-run the snapshot after datasets change; bump the date/version and keep old
tarballs (never overwrite — each is a point-in-time record tied to a `git_commit`):

```sh
STAMP="v2-$(date +%F)"
# rebuild MANIFEST.json + datasets-$STAMP.tar.gz  (see the commit that added v1
# for the exact sha256/row-count generation loop)
```
