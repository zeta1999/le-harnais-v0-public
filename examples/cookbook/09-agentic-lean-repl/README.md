# 09 · agentic Lean REPL — iterate to a proof with `lean_run_code`

**Method:** the ReAct agent loop (`lh run --logic`) driving the **`lean_run_code`** tool — the model
submits a Lean 4 snippet, reads back `{complete, ok, errors}` (with the unsolved-goal state), and
tries again until `complete: true`. Verify-by-execution: the native `lean4` verifier is ground truth,
so a "done" is a real compile with no errors and no `sorry`.

**Why non-trivial — and why the loop beats one-shot:** on `a + b = b + a`, a one-shot generation
often over-engineers a manual `induction … simp` and *loses*. Given the tool, the model iterates:
`induction … simp` → `complete:false` → `rw […]` → false → `induction a with | zero => omega | succ a ih => omega`
→ **`complete:true`**. The loop lets it *reach the decision procedure* (`omega`) it should have used —
the agentic lever doing real work.

- **Model:** any tool-capable local model (`qwen3.6:35b-a3b-bf16` is a strong default; override with
  `LH_MODEL`). Reasoning-capable Lean specialists benefit most.
- **Backend:** `lean`/`lake` on PATH (elan) + a Lean project on `LH_LEAN_PROJECT` (Mathlib optional;
  core-Lean goals like this one need no Mathlib). `run.sh` points at the repo's `lean/` project.
- **Dataset / finetuning:** none.
- **Run:** `./run.sh` — expects the loop to reach `"complete": true` within the step budget.

Requires the `lean_run_code` tool (shipped in `lh` @1e53401+). Strict chat templates (Mistral-family)
also require the role-alternation fix in the same build. See `docs/CLI-TUTORIAL.md` §4 and
`docs/models.md`.
