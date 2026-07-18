#!/usr/bin/env bash
# Build the macOS arm64 `lh` binary — RUN THIS ON A MAC (Apple Silicon, M1+).
#
# Why this is a separate script: the release was assembled on an x86_64 Linux host,
# which cannot produce an aarch64-apple-darwin binary (no Apple SDK / code-signing
# toolchain, no osxcross installed). `lh` itself is torch/CUDA-free and fully portable,
# so a native build on your M-series Mac is the clean path.
#
# Usage (from the repo root, on your Mac):
#   ./dist/build-macos.sh
# Produces: dist/bin/lh-macos-arm64  (+ updates dist/bin/SHA256SUMS)
set -euo pipefail

cd "$(dirname "$0")/.."   # repo root

command -v cargo >/dev/null || { echo "error: install Rust (https://rustup.rs)"; exit 1; }
rustup target add aarch64-apple-darwin 2>/dev/null || true

# lh-serve (candle/CUDA) is NOT built here — it is Linux+CUDA only and is excluded
# from default-members. We build only the portable `lh` binary.
cargo build --release --target aarch64-apple-darwin

mkdir -p dist/bin
cp target/aarch64-apple-darwin/release/lh dist/bin/lh-macos-arm64
strip dist/bin/lh-macos-arm64 || true

# refresh checksums
( cd dist/bin && shasum -a 256 lh-* lh-serve-* 2>/dev/null > SHA256SUMS || sha256sum lh-* lh-serve-* > SHA256SUMS )
echo "built dist/bin/lh-macos-arm64"
./dist/bin/lh-macos-arm64 --version
