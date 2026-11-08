#!/usr/bin/env bash
# One CLI invocation of the five-role team. See docs/team-solve.md.
# --solo on the same lh team-solve line is the one-context recipe.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/../../.." && pwd)"
if [[ -n "${LH:-}" ]]; then
  :
elif [[ -x "$REPO/bin/lh-linux-x86_64" ]]; then LH="$REPO/bin/lh-linux-x86_64"
elif [[ -x "$REPO/bin/lh-linux-arm64" ]]; then LH="$REPO/bin/lh-linux-arm64"
elif [[ -x "$REPO/bin/lh-macos-arm64" ]]; then LH="$REPO/bin/lh-macos-arm64"
elif [[ -x "$REPO/target/debug/lh" ]]; then LH="$REPO/target/debug/lh"
else LH="$(command -v lh)"
fi

HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="${LH_WORKDIR:-$(mktemp -d "${TMPDIR:-/tmp}/lh-team-solve.XXXXXX")}"
ID="${LH_RUN_ID:-cookbook09}"

mkdir -p "$WORK"
cp "$HERE/project/ranges.py" "$HERE/project/check.sh" "$WORK/"
chmod +x "$WORK/check.sh"

if [[ ! -d "$WORK/.git" ]]; then
  git -C "$WORK" init -q
  git -C "$WORK" config user.name zeta1999
  git -C "$WORK" config user.email renoir42@renoir42.com
  git -C "$WORK" add ranges.py check.sh
  git -C "$WORK" commit -q -m "interval-merge stub"
fi

# A model that advertises a 262k window will try to allocate it unless this is set.
export LH_NUM_CTX="${LH_NUM_CTX:-32768}"

args=(team-solve --worktree "$WORK" --id "$ID" -)
if [[ -n "${LH_MODEL:-}" ]]; then
  args=(--model "$LH_MODEL" "${args[@]}")
fi

echo "worktree $WORK"
"$LH" "${args[@]}" < "$HERE/prompt.txt"
echo "worktree $WORK"
