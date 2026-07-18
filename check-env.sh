#!/usr/bin/env bash
# le-harnais — environment doctor.
#
# Reports what is present / missing for running the distribution on THIS machine,
# with a per-OS install hint for anything absent. Read-only: it never installs
# or changes anything. Exit code is the count of MISSING *required* components
# (0 = ready to run the core), so it is scriptable / agent-friendly.
#
#   ./dist/check-env.sh            # human table
#   ./dist/check-env.sh --json     # machine-readable (one JSON object)
#
# Tiers:
#   REQUIRED  — the core `lh` agent loop + generation (rust to build, ollama to generate)
#   LOGIC     — logic backends that SHELL OUT (z3/clingo/lean); sql+prolog are bundled
#   TOOLS     — optional bundled tools (aria quantum, lift lean-lift, appsec security)
set -uo pipefail

JSON=0; [ "${1:-}" = "--json" ] && JSON=1

OS="$(uname -s)"; ARCH="$(uname -m)"
case "$OS" in Darwin) OSN=macos; PKG="brew install" ;; Linux) OSN=linux; PKG="apt/dnf install" ;; *) OSN="$OS"; PKG="(your package manager)" ;; esac

MISS_REQ=0
ROWS=()   # tier|name|status|detail|hint

have() { command -v "$1" >/dev/null 2>&1; }
add()  { ROWS+=("$1|$2|$3|$4|$5"); }

# ---- REQUIRED ----------------------------------------------------------------
if have cargo; then add REQUIRED cargo present "$(cargo --version 2>/dev/null | awk '{print $2}')" ""
else add REQUIRED cargo MISSING "-" "https://rustup.rs  (curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh)"; MISS_REQ=$((MISS_REQ+1)); fi

if have ollama; then
  OV="$(ollama --version 2>/dev/null | awk '{print $NF}')"
  NM="$(ollama list 2>/dev/null | tail -n +2 | grep -c . || echo 0)"
  add REQUIRED ollama present "v${OV:-?}, ${NM} model(s)" ""
else
  case "$OSN" in
    linux) H="curl -fsSL https://ollama.com/install.sh | sh   (or ./dist/install-ollama.sh)";;
    macos) H="brew install ollama  (or download https://ollama.com/download/mac ; or ./dist/install-ollama.sh)";;
    *)     H="https://ollama.com/download";;
  esac
  add REQUIRED ollama MISSING "-" "$H"; MISS_REQ=$((MISS_REQ+1))
fi

# ---- LOGIC backends (shell-out; sql+prolog are bundled in the binary) --------
for pair in "z3:z3" "clingo:clingo" "lean:lean (lake)"; do
  bin="${pair%%:*}"; label="${pair##*:}"
  if have "$bin"; then add LOGIC "$label" present "$($bin --version 2>/dev/null | head -1)" ""
  else
    case "$bin" in
      z3)    h="$PKG z3";;
      clingo) h="$PKG clingo   (or: pipx install clingo / conda install -c conda-forge clingo)";;
      lean)  h="https://leanprover-community.github.io/get_started.html  (elan/lake)";;
    esac
    add LOGIC "$label" absent "-" "$h"
  fi
done
add LOGIC "sql, prolog" present "bundled in lh (pure Rust)" ""

# ---- TOOLS (optional, bundled in dist/tools) ---------------------------------
# fields: bin : dist/tools/<dir> : human label
DIST="$(cd "$(dirname "$0")" && pwd)"
for spec in "aria:aria:aria quantum backend" "lift:leanlift:leanlift" "appsec:appsec:security-toolkit"; do
  IFS=':' read -r bin dir label <<<"$spec"
  local_bin="$DIST/tools/$dir/${bin}-$(echo "$OSN")-${ARCH}"
  if have "$bin"; then add TOOLS "$label" present "on PATH" ""
  elif [ -x "$local_bin" ]; then add TOOLS "$label" bundled "dist/tools/$dir ($ARCH)" "add to PATH to use"
  else add TOOLS "$label" absent "-" "build from source repo (see dist/tools/README.md)"; fi
done
have docker && add TOOLS "docker (appsec scanners)" present "$(docker --version 2>/dev/null | awk '{print $3}' | tr -d ,)" "" \
             || add TOOLS "docker (appsec scanners)" absent "-" "https://docs.docker.com/engine/install/  (only needed for appsec)"

# ---- emit --------------------------------------------------------------------
if [ "$JSON" = 1 ]; then
  printf '{\n  "os": "%s", "arch": "%s", "missing_required": %d,\n  "components": [\n' "$OSN" "$ARCH" "$MISS_REQ"
  n=${#ROWS[@]}; i=0
  for r in "${ROWS[@]}"; do IFS='|' read -r t nm st d h <<<"$r"; i=$((i+1)); c=","; [ $i -eq $n ] && c=""
    printf '    {"tier":"%s","name":"%s","status":"%s","detail":"%s"}%s\n' "$t" "$nm" "$st" "$d" "$c"; done
  printf '  ]\n}\n'
else
  echo "le-harnais env doctor — ${OSN}/${ARCH}"
  echo "──────────────────────────────────────────────────────────────────────"
  cur=""
  for r in "${ROWS[@]}"; do IFS='|' read -r t nm st d h <<<"$r"
    [ "$t" != "$cur" ] && { echo; echo "[$t]"; cur="$t"; }
    case "$st" in present|bundled) mark="✓";; MISSING) mark="✗";; *) mark="·";; esac
    printf "  %s %-26s %-8s %s\n" "$mark" "$nm" "$st" "$d"
    [ -n "$h" ] && [ "$st" != present ] && [ "$st" != bundled ] && printf "      ↳ install: %s\n" "$h"
  done
  echo
  echo "──────────────────────────────────────────────────────────────────────"
  # arch-label sanity (warn only; publish.sh hard-fails on the same check)
  if [ -x "$DIST/verify-arch.sh" ] && ! "$DIST/verify-arch.sh" >/dev/null 2>&1; then
    echo "⚠ WARNING: a bundled binary is mislabeled — run ./dist/verify-arch.sh"
  fi
  if [ "$MISS_REQ" -eq 0 ]; then echo "READY: core requirements present. (·/absent items are optional per feature.)"
  else echo "NOT READY: $MISS_REQ required component(s) missing — see ↳ hints above."; fi
fi
exit "$MISS_REQ"
