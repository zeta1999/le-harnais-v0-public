#!/usr/bin/env bash
set -euo pipefail; REPO="$(cd "$(dirname "$0")/../../.." && pwd)"
"$REPO/tools/lean_verify.sh" "$REPO/docs/examples/orddict.lean" && echo "PROVED (no errors, no sorry)"
