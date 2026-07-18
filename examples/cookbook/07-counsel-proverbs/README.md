# 07 · counsel game (served model + judge) — couple/proverbs advice

**Method:** a served fine-tuned model generates grounded advice; a stronger judge
(qwen) scores applies/sound/format and drives a repair loop. **Why non-trivial:** the 1B
model drifts on citation/format every turn; the judge loop catches it — the point of
pairing a weak generator with a verifier.

- **Model:** generator = a JEPA/regular fine-tuned Llama checkpoint served by `model-svc`
  (e.g. `refs/llm-jepa/ft-counsel`); judge = ollama `qwen3.6`; embedder = `nomic-embed-text`.
- **Dataset:** `datasets/counsel_*.jsonl` (verse-anchored advice pairs).
- **Finetuning:** `refs/llm-jepa` SFT — `tools/train_counsel.sh` / `run_counsel_backbone.sh`
  (regular or `--jepa`); served via `py/model-svc/run_model_svc.sh`.
- **Run:** `./run.sh [scenario.json]`  (couple scenario by default).

Wraps `run_jepa_game.sh`. See memory `model-svc-jepa-serving`, `docs/jepa.md`.
