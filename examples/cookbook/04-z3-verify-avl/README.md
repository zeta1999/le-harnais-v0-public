# 04 · z3 as a *verifier* (prove, not just check) — AVL rotation preserves balance

**Method:** SMT (z3) proves a universal arithmetic property; on a missing precondition it
returns a concrete counterexample. **Why non-trivial:** this is the half the Lean proof
(05) abstracts away — the height/balance-factor arithmetic of all four AVL rotations.

- **Model:** none (pure solver).
- **Dataset:** none.
- **Finetuning:** none.
- **Run:** `./run.sh` → all four rotations `unsat` (proven), plus a missing-precondition
  variant that yields a counterexample tree `(a=2,b=0,c=3)`.

Artifact: `examples/avl_rebalance.smt2`. See `docs/solver-helpers.md`.
