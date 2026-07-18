#!/usr/bin/env bash
# Build the security-toolkit `appsec` orchestrator for THIS platform.
# appsec uses DuckDB via CGO, so it is built NATIVELY per platform (a C toolchain
# is required) and does not cross-compile. The bundled appsec-linux-x86_64 was
# built on Linux x86_64.
#
#   SRC=/path/to/security-toolkit ./build.sh
# Produces: appsec-<os>-<arch> next to this script.
set -euo pipefail
SRC="${SRC:-/home/pc/work/security-toolkit}"
[ -f "$SRC/appsec/go.mod" ] || { echo "set SRC=/path/to/security-toolkit checkout (has appsec/go.mod)"; exit 1; }
GO="${GO:-$HOME/go/bin/go}"; command -v "$GO" >/dev/null || GO=go
command -v "$GO" >/dev/null || { echo "install Go: https://go.dev/dl/"; exit 1; }

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"; [ "$OS" = darwin ] && OS=macos
ARCH="$(uname -m)"
OUT="$(cd "$(dirname "$0")" && pwd)/appsec-${OS}-${ARCH}"

# CGO must be ON for the DuckDB store.
( cd "$SRC/appsec" && CGO_ENABLED=1 "$GO" build -o "$OUT" ./cmd/appsec )
strip "$OUT" 2>/dev/null || true
echo "built $OUT"
echo "runtime deps: Docker + the scanner images pinned in tools.lock (appsec pulls them on demand)."
