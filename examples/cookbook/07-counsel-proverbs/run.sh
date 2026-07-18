#!/usr/bin/env bash
set -euo pipefail; REPO="$(cd "$(dirname "$0")/../../.." && pwd)"
exec "$REPO/run_jepa_game.sh" "$@"
