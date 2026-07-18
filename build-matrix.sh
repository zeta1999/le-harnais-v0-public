#!/usr/bin/env bash
# Build the le-harnais distribution matrix (Track C).
#
# Two tiers:
#   Tier A — the portable core `lh` (the `default-members` crates; NO candle/CUDA). It cross-compiles
#            to every target and covers the whole mission (agent + logic + memory + RAG + MCP + kb),
#            because inference is delegated to ollama/openai-compat which each platform runs natively.
#   Tier B — the OPTIONAL native model server `lh-serve` (candle). Built NATIVELY per target, never
#            cross-compiled. Optional because ollama is the recommended (faster) generation path.
#
# Targets:
#   linux-amd64      Tier A: cargo (native here)                     Tier B: lh-serve --features cuda (sm_120)
#   linux-arm64-cpu  Tier A: cross → aarch64-unknown-linux-gnu       Tier B: none (use ollama)
#   dgx-spark        Tier A: the SAME arm64-linux core binary        Tier B: lh-serve --features cuda, BUILD ON THE SPARK (sm_121)
#   macos-arm64      Tier A: build on a Mac (dist/build-macos.sh)    Tier B: lh-serve --features metal, on the Mac
#
# Logic-backend capability is UNIFORM by construction: `sql` = bundled sqlite (pure Rust, travels
# with the binary); `prolog`/`clingo`/`lean` SHELL OUT, so they need scryer-prolog(bundled)/`clingo`/
# `z3`/`lean` on PATH at runtime. No C-linking to those, which is exactly why the core cross-compiles.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p dist/bin

strip_q() { strip "$1" 2>/dev/null || true; }

build_amd64() {
  echo ">> [Tier A] linux-amd64 (native)"
  cargo build --release -p lh-cli
  cp target/release/lh dist/bin/lh-linux-x86_64 && strip_q dist/bin/lh-linux-x86_64
}

build_arm64() {
  echo ">> [Tier A] linux-arm64 (cross — also the DGX Spark core binary)"
  command -v cross >/dev/null || { echo "   install: cargo install cross (needs docker)"; return 1; }
  # CROSS_ROOTLESS_CONTAINER_ENGINE=1 is REQUIRED under rootless docker (else the container's uid
  # mapping can't write the mounted /target → 'Permission denied creating /target/release'). Harmless
  # with rootful docker/podman. Verified: produces a valid ELF aarch64 binary on this host.
  CROSS_ROOTLESS_CONTAINER_ENGINE=1 cross build --release -p lh-cli --target aarch64-unknown-linux-gnu
  cp target/aarch64-unknown-linux-gnu/release/lh dist/bin/lh-linux-arm64
}

case "${1:-all}" in
  amd64) build_amd64 ;;
  arm64) build_arm64 ;;
  all)
    build_amd64
    build_arm64 || echo "   (arm64 skipped)"
    echo ">> [Tier A] macos-arm64: run dist/build-macos.sh ON a Mac (no Linux→Darwin cross)"
    echo ">> [Tier B] lh-serve (optional native serving), per target:"
    echo "     linux-amd64 : cargo build -p lh-serve --features cuda   (CUDA_COMPUTE_CAP=120)"
    echo "     dgx-spark   : cargo build -p lh-serve --features cuda   (ON the Spark, sm_121)"
    echo "     macos-arm64 : cargo build -p lh-serve --features metal  (on the Mac)"
    echo "     linux-arm64 : (none — use ollama)"
    ;;
  *) echo "usage: $0 [amd64|arm64|all]"; exit 1 ;;
esac

( cd dist/bin && { sha256sum lh-* 2>/dev/null || shasum -a 256 lh-*; } > SHA256SUMS 2>/dev/null || true )
echo "done. dist/bin:"; ls -la dist/bin/ 2>/dev/null
