#!/usr/bin/env bash
# Verify every bundled binary's FILENAME arch suffix matches its ACTUAL arch,
# AND audit its linked shared libraries against the base-system allowlist.
# Guards two rules: "no binary mislabeled" and "no undeclared .so/.dylib dep —
# every bundled binary must run on a stock system" (anything outside the
# allowlist must either be bundled next to the binary or documented).
# Scans dist/bin and dist/tools by default.
#
#   ./dist/verify-arch.sh [dir ...]
# Exit 0 = all labels + libs OK; exit 1 = at least one problem (prints which).
#
# Suffix → expected `file` signature:
#   *-linux-x86_64  ⇒ ELF … x86-64
#   *-linux-arm64   ⇒ ELF … aarch64 / ARM aarch64
#   *-macos-arm64   ⇒ Mach-O … arm64
#   *-macos-x86_64  ⇒ Mach-O … x86_64
#
# Linked-libs audit: ELF via `objdump -p` NEEDED entries (works cross-arch, so
# the arm64 binary is audited on an x86_64 host too); Mach-O via `otool -L`
# (macOS only — skipped elsewhere, the macOS agent re-runs this). A dynamically
# linked ELF that objdump cannot read (or a missing objdump) is a FAILURE, not
# a silent pass — the audit must never vacuously succeed.
# Allowlist: base glibc/gcc runtime; *-cuda binaries additionally the NVIDIA
# libs — libcuda from the driver, libcublas/libcurand from the CUDA toolkit
# runtime (NVIDIA-redistributable; a driver-only box needs the toolkit libs).
# Note: split binaries (*.part-*) are not audited until reassembled by join.sh.
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

# Anchored soname allowlists (substring matches would let lookalikes through:
# a hypothetical `mylibz.so` must NOT pass just because it contains `libz.so`).
# *-cuda binaries additionally allow the NVIDIA libs — libcuda from the DRIVER,
# libcublas/libcurand from the CUDA TOOLKIT runtime (NVIDIA-redistributable;
# a driver-only box still needs the toolkit runtime libs).
BASE_OK='^(ld-linux|linux-vdso|libc\.so|libm\.so|libdl\.so|librt\.so|libpthread\.so|libgcc_s\.so|libstdc\+\+\.so|libz\.so)'
CUDA_OK='^(libcuda\.so|libcudart\.so|libcublas|libcurand\.so|libnvrtc|libnccl)'
MACOS_OK='^(/usr/lib/|/System/Library/|@rpath/libc\+\+|libSystem|libc\+\+|libobjc)'

audit_libs() {  # $1 = path, $2 = basename → prints offending libs (one/line),
                # or "AUDIT_UNAVAILABLE <why>" when the audit could not run
  local ok="$BASE_OK"
  case "$2" in *-cuda) ok="$BASE_OK|$CUDA_OK" ;; esac
  local desc needed
  desc="$(file -b "$1")"
  case "$desc" in
    ELF*)
      command -v objdump >/dev/null || { echo "AUDIT_UNAVAILABLE objdump not installed"; return 0; }
      needed="$(objdump -p "$1" 2>/dev/null | awk '/NEEDED/{print $2}')"
      if [ -z "$needed" ]; then
        # A static ELF genuinely has no NEEDED; a dynamically linked one
        # yielding nothing means objdump could not read it (e.g. non-multiarch
        # binutils vs a foreign-arch ELF) — that must not pass as clean.
        case "$desc" in
          *"dynamically linked"*) echo "AUDIT_UNAVAILABLE objdump read no NEEDED from a dynamically linked ELF" ;;
        esac
        return 0
      fi
      echo "$needed" | grep -Ev "$ok" || true ;;
    Mach-O*)
      command -v otool >/dev/null || return 0  # linux host: macOS agent re-runs
      otool -L "$1" 2>/dev/null | tail -n +2 | awk '{print $1}' | grep -Ev "$MACOS_OK" || true ;;
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
    bad="$(audit_libs "$f" "$(basename "$f")")"
    if [ -n "$bad" ]; then
      printf '  ✗ %-42s UNDECLARED LIBS: %s (bundle the lib next to the binary or add it to the allowlist with a note)\n' \
        "${f#$HERE/}" "$(echo "$bad" | tr '\n' ' ')"
      fail=1
    fi
  done < <(find "$d" -type f ! -name '*.part-*' ! -name '*.sha256' -print0 2>/dev/null)
done

if [ "$fail" -eq 0 ]; then echo "arch-verify: OK ($checked labeled binaries, libs audited)"; else echo "arch-verify: PROBLEMS found"; fi
exit "$fail"
