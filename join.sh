#!/usr/bin/env bash
# Reassemble every split binary in this tree: cat parts → original, verify sha256, chmod +x.
set -euo pipefail
cd "$(dirname "$0")"
shopt -s nullglob globstar
for sha in **/*.sha256; do
  d="$(dirname "$sha")"; base="$(basename "$sha" .sha256)"
  parts=("$d/$base".part-*)
  [ ${#parts[@]} -gt 0 ] || { echo "no parts for $base"; continue; }
  cat "${parts[@]}" > "$d/$base"
  ( cd "$d" && { sha256sum -c "$(basename "$sha")" || shasum -a 256 -c "$(basename "$sha")"; } )
  chmod +x "$d/$base"
  echo "reassembled $d/$base"
done
