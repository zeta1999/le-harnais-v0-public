#!/usr/bin/env bash
# Smoke-test the DIST ARTIFACTS themselves (binary + a fetched model), not the
# repo-coupled cookbook. Proves: the binary runs, native logic works, and a shipped
# GGUF generates via ollama. Needs: ollama running; for step 3, a fetched model.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
LH="$HERE/../bin/lh-linux-x86_64"; [ -x "$LH" ] || LH="$HERE/../bin/lh-macos-arm64"
pass=0; fail=0
ok(){ echo "  PASS: $1"; pass=$((pass+1)); }; no(){ echo "  FAIL: $1"; fail=$((fail+1)); }

echo "[1] binary runs"; "$LH" --version && ok "lh --version" || no "lh --version"

echo "[2] native logic compiled in (dependency-free) — solver execution needs host solvers"
if "$LH" doctor 2>/dev/null | grep -q "native backends: COMPILED"; then
  ok "native logic backends compiled"
  "$LH" doctor 2>/dev/null | grep -E "available|FOUND" | sed 's/^/     /'
else no "lh doctor"; fi

echo "[3] shipped GGUF generates (needs: ./models/fetch_models.sh ft-agentworld-1b --gguf)"
G="$HERE/../models/ft-agentworld-1b/ft-agentworld-1b.Q4_K_M.gguf"
if [ -f "$G" ] && command -v ollama >/dev/null; then
  printf 'FROM %s\nPARAMETER temperature 0.6\n' "$G" > /tmp/lh-smoke.Modelfile
  ollama create lh-smoke -f /tmp/lh-smoke.Modelfile >/dev/null 2>&1
  out=$(ollama run lh-smoke "STATE: kitchen, kettle empty. ACTION: fill kettle. Predict OBSERVATION and NEW_STATE." 2>/dev/null)
  ollama rm lh-smoke >/dev/null 2>&1
  [ -n "$out" ] && { ok "agentworld-1b GGUF generated"; echo "     $out" | head -2; } || no "GGUF generate empty"
else
  echo "  SKIP: model not fetched or ollama absent"
fi
echo "== smoke: $pass passed, $fail failed =="
[ "$fail" -eq 0 ]
