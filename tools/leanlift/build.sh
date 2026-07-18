#!/usr/bin/env bash
# Build the leanlift `lift` binary for THIS platform (macOS arm64, linux arm64, …).
# The bundled lift-linux-x86_64 was built on a Linux x86_64 host; Rust binaries do
# not cross-build cleanly to Darwin, so rebuild natively on a Mac.
#
#   SRC=/path/to/leanlift ./build.sh
# Produces: lift-<os>-<arch> next to this script (+ leaves it executable).
set -euo pipefail
SRC="${SRC:-/home/pc/work/leanlift}"
[ -f "$SRC/Cargo.toml" ] || { echo "set SRC=/path/to/leanlift checkout (has Cargo.toml)"; exit 1; }
command -v cargo >/dev/null || { echo "install Rust: https://rustup.rs"; exit 1; }

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"; [ "$OS" = darwin ] && OS=macos
ARCH="$(uname -m)"
OUT="$(cd "$(dirname "$0")" && pwd)/lift-${OS}-${ARCH}"

( cd "$SRC" && cargo build --release --bin lift )
cp "$SRC/target/release/lift" "$OUT"; strip "$OUT" 2>/dev/null || true
chmod +x "$OUT"
echo "built $OUT"
echo "runtime dep: a Lean 4 toolchain (elan/lake) on PATH — see the leanlift README."
