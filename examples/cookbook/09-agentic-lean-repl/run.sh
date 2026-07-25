#!/usr/bin/env bash
# 09 · agentic Lean REPL — the model drives the lean_run_code tool until the proof compiles clean.
# The native lean4 verifier is ground truth (complete:true = compiles, no errors, no sorry).
set -euo pipefail
REPO="$(cd "$(dirname "$0")/../../.." && pwd)"
LH="$REPO/target/release/lh"; [ -x "$LH" ] || LH="$REPO/target/debug/lh"
export LH_LEAN_PROJECT="${LH_LEAN_PROJECT:-$REPO/lean}"

exec "$LH" --provider ollama --model "${LH_MODEL:-qwen3.6:35b-a3b-bf16}" \
  run --logic --sandbox --max-steps "${MAX_STEPS:-16}" \
  "Prove in Lean 4 that for all natural numbers a and b, a + b = b + a. \
State it as a theorem and prove it. Use the lean_run_code tool to compile each attempt; it returns \
{complete, ok, errors}. When it returns \"complete\": true you are done — stop and report the proof. \
Otherwise read the errors (they include the unsolved-goal state) and try a different tactic."
