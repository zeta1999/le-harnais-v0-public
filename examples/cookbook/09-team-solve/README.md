# 09 · five-role team — merge touching intervals

**Method:** one `lh team-solve` process. The default runs the team in order:
plan, two ideators, solve, the driver's check, review, repair, judge, verify.
Repair is a fresh context only when the review says FAIL.
**Why this shape:** the whole recipe is that one command. `--solo` on the
same line is the one-context comparison. There is no second binary and no
shell loop over roles.

- **Model:** whatever `lh` is configured to call. `LH_MODEL` overrides it.
  A GGUF with a 262k advertised context needs `LH_NUM_CTX` (the script
  defaults it to 32768).
- **Dataset / finetuning:** none.
- **Run:** `./run.sh` copies `project/` to a temporary git checkout, commits
  the stub, and runs `lh team-solve`. The prompt is `prompt.txt` on stdin
  (`-`), which is the same as passing the task as an argument.
- **Pass shape:** `expected.txt`. `repair` is `skipped` when the first check
  already passed, and `ran` when a later context had to fix it. Either can
  be a successful run. The command exits non-zero when verify fails.

The worktree must already have one commit before `lh team-solve` starts.
`run.sh` does that. Reusing `LH_RUN_ID` in a worktree that already has that
run directory fails; the script's default id is `cookbook09` and the
worktree is a new temp directory each time unless `LH_WORKDIR` is set.

See `docs/team-solve.md`.
