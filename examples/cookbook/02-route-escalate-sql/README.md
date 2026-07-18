# 02 · routing / escalation (boosting #2) — cheap 1B → qwen SQL

**Method:** best-of-N per tier, **cheap → strong**, stopping at the first tier that
verifies. **Why it helps:** most queries resolve on the cheap tier; the expensive model is
billed only on the hard tail. The verifier makes it safe — you escalate on *proven* failure,
never shipping the cheap tier's wrong answer. **Non-trivial:** an aggregate-with-filter query.

- **Model:** cheap = a fine-tuned 1B served by `model-svc` (e.g. `ft-medium-jepa`, the
  spider-jepa from C1); strong = ollama `qwen3.6:35b-a3b-bf16`.
- **Dataset:** spider; `db_id=concert_singer`.
- **Finetuning:** the cheap tier is `refs/llm-jepa/run_single_gpu.sh medium` output
  (`ft-medium-jepa`), served via `MODEL_DIR=refs/llm-jepa/ft-medium-jepa py/model-svc/run_model_svc.sh`.
- **Needs:** native logic (in-process, default), model-svc :8000 (cheap tier), ollama (strong tier).
- **Run:** `./run.sh`  → cheap attempts fail/verify; escalates to strong only if needed.

See `docs/boosting.md` §2.
