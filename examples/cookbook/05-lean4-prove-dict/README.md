# 05 · lean4 proof of program semantics — OrderedDict lookup laws

**Method:** Lean 4 deductive proof (core, no Mathlib) of the dictionary semantics:
`lookup_insert` and `lookup_insert_ne` over a key-sorted association-list model.
**Why non-trivial:** a real proof by induction + nested by_cases, no `sorry`.

- **Model:** none (the proof is hand-written reference); the *generation* variant is
  `run_orddict_lean.sh` (a local model fills the `sorry`s under guidance).
- **Dataset / finetuning:** none.
- **Run:** `./run.sh` typechecks `docs/examples/orddict.lean` with `lean` (fails on any
  error or `sorry`).

See `docs/examples/orddict.lean`, `docs/lean-escalation.md`.
