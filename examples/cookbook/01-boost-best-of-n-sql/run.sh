#!/usr/bin/env bash
set -euo pipefail; REPO="$(cd "$(dirname "$0")/../../.." && pwd)"
# Logic is native (in-process) by default — just `cargo build` and run; no service needed.
export LH_SPIDER_PATH="${LH_SPIDER_PATH:-$REPO/refs/llm-jepa/spider_data/database}"
exec "$REPO/target/debug/lh" --provider ollama --model "${LH_MODEL:-qwen3.6:35b-a3b-bf16}" \
  solve sql concert_singer \
  "List singer names and the number of concerts for each singer." \
  --gold "SELECT T2.name, count(*) FROM singer_in_concert AS T1 JOIN singer AS T2 ON T1.singer_id = T2.singer_id GROUP BY T2.singer_id" \
  -n 5
