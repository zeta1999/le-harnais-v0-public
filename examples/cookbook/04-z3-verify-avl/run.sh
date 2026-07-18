#!/usr/bin/env bash
set -euo pipefail; REPO="$(cd "$(dirname "$0")/../../.." && pwd)"
"$REPO/refs/llm-jepa/.venv/bin/python" - "$REPO/examples/avl_rebalance.smt2" <<'PY'
import z3, sys
print(z3.Z3_eval_smtlib2_string(z3.main_ctx().ref(), open(sys.argv[1]).read()))
PY
