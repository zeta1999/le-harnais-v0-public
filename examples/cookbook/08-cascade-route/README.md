# 08 · verifier-grounded cascade routing — cheap→strong by task

**Method:** `lh solve --cascade` tries models in order; each gets the repair budget;
escalates to the next on *verified* failure. **Why non-trivial:** the free solver verdict
makes try-and-check beat predict-and-commit (a bandit) — a tiny model fails, a strong one
rescues, and you never ship the cheap tier's wrong answer.

- **Model:** route `gemma4:e4b → qwen3.6:35b-a3b-bf16` (or `--cascade auto`).
- **Dataset / finetuning:** none.
- **Needs:** native logic (in-process, default).
- **Run:** `./run.sh`  → tier 1 (tiny) fails its budget, escalates, tier 2 solves.

See `docs/model-routing.md`.
