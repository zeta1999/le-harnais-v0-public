#!/usr/bin/env bash
set -euo pipefail; REPO="$(cd "$(dirname "$0")/../../.." && pwd)"
Q="Place 4 queens on a 4x4 board so no two share a row, column, or diagonal; represent a solution as a permutation of column positions and query all solutions."
exec "$REPO/target/debug/lh" --provider ollama solve prolog "$Q" -n 3 \
  --cascade "gemma4:e4b,qwen3.6:35b-a3b-bf16"
