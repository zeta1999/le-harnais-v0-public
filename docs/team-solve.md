# `lh team-solve` — one command for the team

A coding task with a check the driver runs. The default is the five-role
recipe: plan, two ideators, solve, check, review, repair, judge, verify.
`--solo` is the one-context recipe. Both are the same subcommand.

```sh
LH_NUM_CTX=32768 lh --model "$LH_MODEL" team-solve --worktree "$DIR" --id run1 - <<'EOF'
Implement merge(intervals) in ranges.py. The check command is `bash check.sh`.
Do not edit check.sh.
EOF
```

Leave off `--solo`. Stderr prints `team-solve: plan` through `team-solve: verify`.
A run whose final check passes prints:

```
check passed
repair skipped
judge ran
verify passed
dir <worktree>/.lh/runs/team-solve-<id>
```

`repair ran` means the reviewer wrote `verdict: FAIL` and a second context
edited the tree. `check failed` on that first line is the captured check, not
the exit code. The process exits 0 only when verify passes. A failing verify
is an error before those lines.

## What the project has to be

- A git checkout with at least one commit. `open_run` records `HEAD` and
  refuses a directory that is not a checkout.
- A check the planner can name. The usual one is `check.sh`, invoked as
  `` `bash check.sh` ``. The driver runs whatever command the planner writes
  in the Check section of `task.md` (the first backtick span). The word
  `samples` runs `tests/N.in` against `tests/N.out` via `solution.py`. The
  word `judge` runs nothing and leaves the verdict to the judge.
- `--worktree` defaults to the current directory. `--id` defaults to
  `r<unix seconds>` and must match `[A-Za-z0-9._-]+`. The task argument `-`
  reads the prompt from stdin.
- The model is the global `--model` (ollama by default). For a GGUF whose
  advertised context is 262k, set `LH_NUM_CTX=32768` or ollama tries to allocate
  that window.

A second invocation with the same `--id` fails: the run directory already
exists. Pick a new id.

## Roles

Each role is a new agent context. The model id is shared. Step budgets are
the per-role defaults (24, or 48 for the solver and the repair), with one
retry. Planner, ideators, reviewer, and judge may write only inside the run
directory. The solver and the repair may write the worktree. `bash` is not
confined by the lexical sandbox.

| Step | Writes | Stops when |
|---|---|---|
| plan | `task.md` sections, `plan.md`, `notes.md` | Deliverable, Check, Scope, and Done when are filled, and Check names a command, `samples`, or `judge` |
| ideate | `proposal-a.md`, `proposal-b.md` | each proposal has at least five non-blank lines |
| solve | the worktree, then `changes.diff` | the diff outside `.lh/` is non-empty |
| check | `test-output.log`, `test-status.txt` | the driver ran the Check (`0`, `1`, or `none`) |
| review | `review.md` | first line is `verdict: PASS` or `verdict: FAIL` |
| repair | the worktree, `repair.md` | skipped when the review is PASS; otherwise `repair.md` is non-blank |
| judge | `verdict.md` | skipped when `check-kind.txt` says `samples`; otherwise the same verdict line |
| verify | `final-check.log` | the Check passes and the verdict is PASS |

The ledger is `<worktree>/.lh/runs/team-solve-<id>/`. It is not part of the
git diff the solver is judged on.

## One context

```sh
lh team-solve --solo --worktree "$DIR" --id solo1 '… Run bash check.sh until it exits 0.'
```

One agent, 32 steps, then the driver runs `bash check.sh` and records
`solo-check.log`. A failing check prints `check failed` and exits non-zero.
Solo does not plan, ideate, review, or repair in a fresh context.

## What one pair of runs showed

Directional, one run each, `Qwen3.8-27B` Q4 through ollama with
`LH_NUM_CTX=32768`. Not a benchmark.

On the ordered-dict AVL (the spec tests in the worktree, no skeleton), solo
passed in 6 min 34 s (20 calls, 23,265 generated tokens). The five-role run
passed in 26 min 44 s after a repair (146 calls, 92,087 generated tokens).
Decode was almost the entire wall clock, at the same tokens per second. The
extra roles cost about four times the generated tokens on a task the single
context already solved.

On a degree-2 B-tree whose check walks occupancy, order, and leaf depth,
solo spent 13 min 33 s and 49,330 generated tokens and left the stub raising
`NotImplementedError`. The same prompt as `lh team-solve` (no `--solo`)
passed on the solver’s first check in 41 min 14 s, and repair was skipped.
The runnable shape of that command is cookbook example 09.
