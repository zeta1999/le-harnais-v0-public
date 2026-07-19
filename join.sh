#!/usr/bin/env bash
# Reassemble every split binary in this tree: cat parts → original, verify sha256, chmod +x.
# Portable across bash 3.2 (stock macOS) and Linux — uses `find`, not globstar (bash 4+).
set -euo pipefail
cd "$(dirname "$0")"
while IFS= read -r sha; do
  d="$(dirname "$sha")"; base="$(basename "$sha" .sha256)"
  parts=("$d/$base".part-*)
  [ -e "${parts[0]}" ] || { echo "no parts for $base"; continue; }
  cat "${parts[@]}" > "$d/$base"
  ( cd "$d" && { sha256sum -c "$(basename "$sha")" 2>/dev/null || shasum -a 256 -c "$(basename "$sha")"; } )
  chmod +x "$d/$base"
  echo "reassembled $d/$base"
done < <(find . -type f -name '*.sha256')
