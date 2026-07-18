#!/usr/bin/env bash
# Download shipped models from the Hugging Face Hub by name.
# Weights are NOT bundled in the dist tarball — they live in per-checkpoint HF repos
# (renaudb1999/le-harnais-<name>); this script pulls them on demand.
#
# Usage:
#   ./fetch_models.sh                       # list available models (from MANIFEST.json)
#   ./fetch_models.sh ft-agentworld-1b      # one model, both formats
#   ./fetch_models.sh ft-agentworld-1b --gguf      # GGUF only (portable)
#   ./fetch_models.sh ft-agentworld-1b --safetensors
#   ./fetch_models.sh --all                 # everything (large!)
# Models download into ./<name>/ next to this script.
set -euo pipefail
cd "$(dirname "$0")"
MANIFEST="MANIFEST.json"
PY="${PY:-python3}"   # any python with `huggingface_hub`; the repo venv has it:
                      #   PY=../../refs/llm-jepa/.venv/bin/python ./fetch_models.sh ...

[ -f "$MANIFEST" ] || { echo "missing $MANIFEST (run from dist/models/)"; exit 1; }

list() { "$PY" - "$MANIFEST" <<'PY'
import json,sys
m=json.load(open(sys.argv[1]))
for k,v in m["models"].items():
    print(f'  {k:55s} {v["class"]:9s} {v["repo_id"]}')
PY
}

if [ $# -eq 0 ]; then
  echo "Available models (name  class  hf-repo):"; list; exit 0
fi

PATTERN="*"; NAMES=()
for a in "$@"; do
  case "$a" in
    --gguf)        PATTERN="*.gguf";;
    --safetensors) PATTERN="*.safetensors|*.json|tokenizer*|*.model";;
    --all)         NAMES=($("$PY" -c 'import json;print(" ".join(json.load(open("MANIFEST.json"))["models"]))'));;
    *)             NAMES+=("$a");;
  esac
done

for name in "${NAMES[@]}"; do
  repo=$("$PY" -c "import json;print(json.load(open('$MANIFEST'))['models']['$name']['repo_id'])")
  echo "== fetching $name from $repo (pattern: $PATTERN) =="
  "$PY" - "$repo" "$name" "$PATTERN" <<'PY'
import sys
from huggingface_hub import snapshot_download
repo, name, pattern = sys.argv[1], sys.argv[2], sys.argv[3]
allow = None if pattern=="*" else pattern.split("|")
snapshot_download(repo_id=repo, local_dir=name, allow_patterns=allow)
print("  ->", name)
PY
done
echo "done."
