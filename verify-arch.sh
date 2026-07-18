#!/usr/bin/env bash
# Verify every bundled binary's FILENAME arch suffix matches its ACTUAL arch.
# Guards the "no binary mislabeled" rule. Scans dist/bin and dist/tools by default.
#
#   ./dist/verify-arch.sh [dir ...]
# Exit 0 = all labels correct; exit 1 = at least one mismatch (prints which).
#
# Suffix → expected `file` signature:
#   *-linux-x86_64  ⇒ ELF … x86-64
#   *-linux-arm64   ⇒ ELF … aarch64 / ARM aarch64
#   *-macos-arm64   ⇒ Mach-O … arm64
#   *-macos-x86_64  ⇒ Mach-O … x86_64
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
DIRS=("$@"); [ ${#DIRS[@]} -eq 0 ] && DIRS=("$HERE/bin" "$HERE/tools")

expect_for() {  # $1 = filename → echo a grep -E pattern for the expected `file` output
  case "$1" in
    *-linux-x86_64|*-linux-x86_64-cuda) echo 'ELF.*x86-64' ;;
    *-linux-arm64|*-linux-arm64-cuda)   echo 'ELF.*(aarch64|ARM aarch64)' ;;
    *-macos-arm64|*-macos-arm64-metal)  echo 'Mach-O.*arm64' ;;
    *-macos-x86_64)                     echo 'Mach-O.*x86_64' ;;
    *) echo "" ;;  # not a labeled binary → skip
  esac
}

fail=0; checked=0
for d in "${DIRS[@]}"; do
  [ -d "$d" ] || continue
  # any regular, non-part file whose name carries an arch suffix
  while IFS= read -r -d '' f; do
    pat="$(expect_for "$(basename "$f")")"; [ -z "$pat" ] && continue
    checked=$((checked+1))
    got="$(file -b "$f")"
    if echo "$got" | grep -Eq "$pat"; then
      printf '  ✓ %-42s %s\n' "${f#$HERE/}" "$(echo "$got" | cut -d, -f1-2)"
    else
      printf '  ✗ %-42s MISLABELED: %s (expected /%s/)\n' "${f#$HERE/}" "$(echo "$got" | cut -d, -f1)" "$pat"
      fail=1
    fi
  done < <(find "$d" -type f ! -name '*.part-*' ! -name '*.sha256' -print0 2>/dev/null)
done

if [ "$fail" -eq 0 ]; then echo "arch-verify: OK ($checked labeled binaries)"; else echo "arch-verify: MISLABELED binaries found"; fi
exit "$fail"
