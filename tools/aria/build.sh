#!/usr/bin/env bash
# Build the `aria` quantum-DSL binary for THIS platform (the backend behind lh's
# `aria` tool and the docs/quantum recipes). Pure Rust, no CUDA/torch — builds on
# macOS arm64, linux arm64, and linux x86_64 alike.
#
#   SRC=/path/to/aria-quantum-language-oss-public ./build.sh
# Produces: aria-<os>-<arch> next to this script.
set -euo pipefail
SRC="${SRC:-/home/pc/work/aria-quantum-language-oss-public}"
[ -f "$SRC/Cargo.toml" ] || { echo "set SRC=/path/to/aria checkout (has Cargo.toml)"; exit 1; }
command -v cargo >/dev/null || { echo "install Rust: https://rustup.rs"; exit 1; }

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"; [ "$OS" = darwin ] && OS=macos
ARCH="$(uname -m)"
OUT="$(cd "$(dirname "$0")" && pwd)/aria-${OS}-${ARCH}"

( cd "$SRC" && cargo build --release -p aria-cli )
cp "$SRC/target/release/aria" "$OUT"; strip "$OUT" 2>/dev/null || true
chmod +x "$OUT"
echo "built $OUT"
echo "lh finds it via: aria on PATH, or export LH_ARIA_BIN=$OUT"
