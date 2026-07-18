#!/usr/bin/env bash
# build-mac-all.sh — RUN ON AN APPLE-SILICON MAC. Builds every macOS arm64 binary the
# linux-amd64 box could not cross-build, labels + arch-verifies them, refreshes checksums,
# and flips the ☐ macOS rows in BINARIES.md to ✅. One-shot hand-off completion.
#
# Prereqs (see DEPENDENCIES.md): Rust (rustup), a Lean 4 toolchain (for lift at runtime),
# Go + Xcode Command Line Tools (CGO for appsec, Metal for lh-serve).
#
#   ./dist/build-mac-all.sh
# Overrides: SRC_ARIA=, SRC_LIFT=, SRC_APPSEC= (default to sibling repos).
set -uo pipefail
cd "$(dirname "$0")/.."                 # repo root
DIST="$PWD/dist"; TOOLS="$DIST/tools"; BIN="$DIST/bin"
mkdir -p "$BIN"

[ "$(uname -s)" = Darwin ] || { echo "This script must run on macOS (Darwin). Aborting."; exit 1; }
ARCH="$(uname -m)"; [ "$ARCH" = arm64 ] || echo "warning: expected arm64, got $ARCH"
command -v cargo >/dev/null || { echo "install Rust: https://rustup.rs"; exit 1; }

ok=(); skip=()
label() { printf '\n>> %s\n' "$1"; }

# 1) lh core (portable; only Rust)
label "lh core → bin/lh-macos-arm64"
if rustup target add aarch64-apple-darwin >/dev/null 2>&1; cargo build --release --target aarch64-apple-darwin -p lh-cli; then
  cp target/aarch64-apple-darwin/release/lh "$BIN/lh-macos-arm64"; strip "$BIN/lh-macos-arm64" 2>/dev/null || true; ok+=("lh-macos-arm64")
else skip+=("lh-macos-arm64 (cargo build failed)"); fi

# 2) lh-serve (Metal)
label "lh-serve (Metal) → bin/lh-serve-macos-arm64-metal"
if cargo build --release --target aarch64-apple-darwin -p lh-serve --features metal 2>/dev/null; then
  cp target/aarch64-apple-darwin/release/lh-serve "$BIN/lh-serve-macos-arm64-metal"; strip "$BIN/lh-serve-macos-arm64-metal" 2>/dev/null || true; ok+=("lh-serve-macos-arm64-metal")
else skip+=("lh-serve-macos-arm64-metal (needs Metal deps; optional — ollama is the default path)"); fi

# 3) aria (already provided for macOS, but rebuild if source is present to be current)
label "aria → tools/aria/aria-macos-arm64"
SRC_ARIA="${SRC_ARIA:-../aria-quantum-language-oss-public}"
if [ -f "$SRC_ARIA/Cargo.toml" ] && ( cd "$SRC_ARIA" && cargo build --release -p aria-cli ); then
  cp "$SRC_ARIA/target/release/aria" "$TOOLS/aria/aria-macos-arm64"; strip "$TOOLS/aria/aria-macos-arm64" 2>/dev/null || true; ok+=("aria-macos-arm64")
else [ -f "$TOOLS/aria/aria-macos-arm64" ] && { skip+=("aria-macos-arm64 (kept prebuilt)"); } || skip+=("aria-macos-arm64 (no source at $SRC_ARIA)"); fi

# 4) lift (leanlift; only Rust)
label "lift → tools/leanlift/lift-macos-arm64"
SRC_LIFT="${SRC_LIFT:-../leanlift}"
if [ -f "$SRC_LIFT/Cargo.toml" ] && ( cd "$SRC_LIFT" && cargo build --release --bin lift ); then
  cp "$SRC_LIFT/target/release/lift" "$TOOLS/leanlift/lift-macos-arm64"; strip "$TOOLS/leanlift/lift-macos-arm64" 2>/dev/null || true; ok+=("lift-macos-arm64")
else skip+=("lift-macos-arm64 (no source at $SRC_LIFT)"); fi

# 5) appsec (Go + CGO/DuckDB)
label "appsec → tools/appsec/appsec-macos-arm64"
SRC_APPSEC="${SRC_APPSEC:-../security-toolkit}"
GO="${GO:-$HOME/go/bin/go}"; command -v "$GO" >/dev/null || GO=go
if [ -f "$SRC_APPSEC/appsec/go.mod" ] && command -v "$GO" >/dev/null && \
   ( cd "$SRC_APPSEC/appsec" && CGO_ENABLED=1 "$GO" build -o "$TOOLS/appsec/appsec-macos-arm64" ./cmd/appsec ); then
  strip "$TOOLS/appsec/appsec-macos-arm64" 2>/dev/null || true; ok+=("appsec-macos-arm64")
else skip+=("appsec-macos-arm64 (needs Go+CGO and source at $SRC_APPSEC)"); fi

# arch-verify everything we produced
label "arch-verify"
"$DIST/verify-arch.sh" || { echo "ABORT: a produced binary is mislabeled."; exit 1; }

# refresh bin checksums
( cd "$BIN" && { shasum -a 256 lh-* 2>/dev/null || sha256sum lh-*; } > SHA256SUMS 2>/dev/null || true )

# flip ☐ → ✅ for the macOS rows we built, in BINARIES.md (best-effort, per binary present)
for b in lh lh-serve aria lift appsec; do
  f=""; case "$b" in
    lh) f="$BIN/lh-macos-arm64";; lh-serve) f="$BIN/lh-serve-macos-arm64-metal";;
    aria) f="$TOOLS/aria/aria-macos-arm64";; lift) f="$TOOLS/leanlift/lift-macos-arm64";;
    appsec) f="$TOOLS/appsec/appsec-macos-arm64";; esac
  [ -f "$f" ] || continue
  # mark the macOS-arm64 column (3rd status cell) ✅ on the row whose first cell names this binary
  perl -0pi -e "s/(\\| \`$b[^|]*\`[^\\n]*?\\|[^|]*\\|[^|]*\\|)\\s*☐\\s*\\|/\$1 ✅ |/g" "$DIST/BINARIES.md" 2>/dev/null || true
done

echo; echo "=== built ==="; printf '  ✅ %s\n' "${ok[@]:-none}"
echo "=== skipped ==="; printf '  · %s\n' "${skip[@]:-none}"
echo; echo "Done. Review BINARIES.md, then commit the new dist/bin/*-macos-* and dist/tools/*/*-macos-* binaries."
