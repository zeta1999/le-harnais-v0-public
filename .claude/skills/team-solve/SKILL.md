---
name: team-solve
description: >-
  Run a coding task that has a check through the le-harnais five-role team.
  Use when the user asks for the 5x recipe, five roles, team-solve, or a
  checked coding task that this session should not implement itself. The
  command is lh team-solve. Leave off --solo.
---

# Five-role team (`lh team-solve`)

You do not write the solution. One `lh team-solve` process is the five roles:
plan, two ideators, solve, check, review, repair, judge, verify. Each role is
a fresh context of the same local model (ollama by default).

## Before the command

1. `DIR` is a git checkout that already has one commit. If it has none, `git init`, add the project files, and commit them. Leave `.lh/` untracked.
2. The task text names the check inside backticks. The usual check is `` `bash check.sh` ``. Leave `check.sh` unchanged.
3. `export LH_NUM_CTX=32768`. A local Qwen GGUF that advertises a 262k window will try to allocate that window unless this is set.
4. `--id` is new each run. The same id in the same worktree fails, because the run directory already exists.

## Command

Pick the binary, then run the team. Stdin (`-`) is the task.

```sh
export LH_NUM_CTX=32768
if [ -x ./bin/lh-linux-x86_64 ]; then LH=./bin/lh-linux-x86_64
elif [ -x ./bin/lh-linux-arm64 ]; then LH=./bin/lh-linux-arm64
elif [ -x ./bin/lh-macos-arm64 ]; then LH=./bin/lh-macos-arm64
else LH=lh
fi

"$LH" ${LH_MODEL:+--model "$LH_MODEL"} team-solve --worktree "$DIR" --id run1 - <<'EOF'
<task here>. Do not edit check.sh. The check command is `bash check.sh`.
EOF
```

`--solo` on that same line is one context, then `bash check.sh`. Use it only when the user asked for the one-context recipe.

## How to read the result

The process exits 0 only when verify passes. Stdout then contains `verify passed`. `repair skipped` means the first check already passed. `repair ran` means a later context edited the tree after the review said FAIL. The ledger is `$DIR/.lh/runs/team-solve-<id>/`.
