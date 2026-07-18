#!/usr/bin/env bash
set -euo pipefail; REPO="$(cd "$(dirname "$0")/../../.." && pwd)"
# Logic is native (in-process) by default — just `cargo build` and run; no service needed.
export LH_SPIDER_PATH="${LH_SPIDER_PATH:-$REPO/refs/llm-jepa/spider_data/database}"
exec "$REPO/target/debug/lh" --provider ollama --model "${LH_STRONG:-qwen3.6:35b-a3b-bf16}" \
  solve sql concert_singer \
  "What is the average, minimum, and maximum age of all singers from France?" \
  --gold "SELECT avg(age), min(age), max(age) FROM singer WHERE country = 'France'" \
  -n 3 --cheap-model "${LH_CHEAP:-ft-medium-jepa}" --cheap-provider openai-compat \
       --cheap-endpoint http://127.0.0.1:8000
