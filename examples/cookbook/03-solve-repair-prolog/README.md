# 03 · generate→verify→repair + primitive cheat-sheet — Prolog 4-queens

**Method:** `lh solve prolog` samples, runs scryer-prolog, feeds the verdict back to
repair; a problem-agnostic **primitive cheat-sheet** supplies the solver-specific knowledge
the model lacks. **Why non-trivial:** 4-queens needs generate-and-test + the diagonal
constraint; without the card weak models reach for non-existent CLP(FD) `all_distinct`.

- **Model:** ollama `gemma4:12b` (the card takes it 0/5 → 5/5) or `qwen3.6`.
- **Dataset / finetuning:** none.
- **Needs:** native logic (in-process, default); scryer-prolog on PATH.
- **Run:** `./run.sh`  (solve with the cheat-sheet; compare by removing `--guidance-file`).

Cheat-sheet: `tools/primitives/scryer.md`. See `docs/solver-helpers.md`.
