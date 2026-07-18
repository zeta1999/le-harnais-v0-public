#!/usr/bin/env bash
# le-harnais — install ollama (the recommended generation backend).
#
# ollama is the fast, portable generation path for `lh` on every platform (the
# candle `lh-serve` server is an optional Linux+CUDA / macOS+Metal extra). This
# script installs ollama for the current OS, then optionally pulls a model.
#
#   ./dist/install-ollama.sh                 # install ollama only
#   ./dist/install-ollama.sh --pull NAME     # install, then `ollama pull NAME`
#
# Idempotent: if ollama is already on PATH it skips the install.
set -euo pipefail

PULL=""
[ "${1:-}" = "--pull" ] && PULL="${2:?--pull needs a model name}"

OS="$(uname -s)"

if command -v ollama >/dev/null 2>&1; then
  echo "ollama already installed: $(ollama --version 2>/dev/null)"
else
  case "$OS" in
    Linux)
      echo ">> installing ollama (official linux script)…"
      curl -fsSL https://ollama.com/install.sh | sh
      ;;
    Darwin)
      if command -v brew >/dev/null 2>&1; then
        echo ">> installing ollama via Homebrew…"
        brew install ollama
      else
        echo "No Homebrew found. Download the macOS app from:"
        echo "    https://ollama.com/download/mac"
        echo "…then re-run this script with --pull to fetch a model."
        exit 1
      fi
      ;;
    *) echo "Unsupported OS '$OS'. See https://ollama.com/download"; exit 1 ;;
  esac
  echo ">> installed: $(ollama --version 2>/dev/null)"
fi

if [ -n "$PULL" ]; then
  # ollama needs its server running to pull; start it in the background if idle.
  if ! curl -fsS http://localhost:11434/api/tags >/dev/null 2>&1; then
    echo ">> starting ollama server…"; (ollama serve >/dev/null 2>&1 &) ; sleep 2
  fi
  echo ">> pulling $PULL …"
  ollama pull "$PULL"
fi

echo "done. Verify with:  ./dist/check-env.sh"
