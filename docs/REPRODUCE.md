# Reproducing every shipped model & result

This is the exact recipe for each artifact in the distribution: base model, dataset
(and how it was built), the training command, the eval command, and the headline
metric. Everything was measured on **one RTX PRO 6000 (96 GB)**. The Rust harness
needs no GPU; the Python training side reuses `refs/llm-jepa/.venv` — **do not make a
new venv** (the relocated venv pins `transformers==4.55.2`, which the recipes assume).

> Conventions: `PY=refs/llm-jepa/.venv/bin/python`. Training writes to
> `refs/llm-jepa/ft-<name>/`. The VRAM-choreography rule (CLAUDE.md): the 35B
> ollama judge/teacher and a full-FT must **not** be co-resident on the 96 GB card —
> the drivers `ollama stop` first.

---

## 0. Datasets (fetch, or build)

The exact corpora used live in a **private** HF dataset repo (~4.8 MB) — pull them to
skip regeneration (needs your HF token; the repo is private):

```sh
hf download renaudb1999/le-harnais-datasets --repo-type dataset --local-dir datasets
```

To rebuild from scratch instead: all corpora are generated locally with
`qwen3.6:35b-a3b-bf16` over public-domain sources; outputs are gitignored
`datasets/*.jsonl` (OpenAI `messages` format).

```sh
PY=refs/llm-jepa/.venv/bin/python
# wisdom (situation↔principle) + commentary (verse↔gloss) → combined `counsel`
$PY tools/build_wisdom_dataset.py     --books proverbs ecclesiastes sirach --max-verses 60 \
    --out datasets/wisdom     --model qwen3.6:35b-a3b-bf16
$PY tools/build_commentary_dataset.py --books proverbs ecclesiastes        --max-verses 60 \
    --out datasets/commentary --model qwen3.6:35b-a3b-bf16
# or the whole chain (waits for the GPU to free, builds both):
tools/run_corpus_gen.sh
# AgentWorld distillation corpus: teacher predicts OBSERVATION + NEXT_STATE for 200
# programmatic (state, action) pairs → 160 train / 40 held-out eval
$PY tools/gen_agentworld_corpus.py     # writes datasets/agentworld_distill_{train,eval}.jsonl
```

| corpus | train / test | source | view pair |
|---|---|---|---|
| `wisdom_*` | 162 / 18 | Proverbs + Ecclesiastes (WEB/KJVA) + 60 Sirach (eBible eng-web, PD) | situation ↔ principle |
| `commentary_*` | 108 / 12 | John Gill's Exposition (PD) | verse ↔ gloss |
| `counsel_*` | 270 / 30 | wisdom + commentary concatenated | SFT set for §2 |
| `agentworld_distill_*` | 160 / 40 | teacher `Qwen-AgentWorld-35B-A3B` over programmatic (state,action) | (state,action) ↔ (OBSERVATION, NEXT_STATE) |

---

## 1. AgentWorld distillation — the HERO result (1B / 3B / 8B students)

Distil the teacher's next-state prediction into a Llama student via plain full-FT SFT
(`--regular`, `FORCE_OPTIM=adafactor` so the output is a complete servable checkpoint).
One driver, parameterized by `BASE`/`OUT`:

```sh
# 1B (Mac-runnable stand-in), 3B (balanced), 8B (near-teacher local replacement)
BASE=meta-llama/Llama-3.2-1B-Instruct  OUT=refs/llm-jepa/ft-agentworld-1b  tools/distill_agentworld.sh
BASE=meta-llama/Llama-3.2-3B-Instruct  OUT=refs/llm-jepa/ft-agentworld-3b  tools/distill_agentworld.sh
BASE=meta-llama/Meta-Llama-3.1-8B-Instruct OUT=refs/llm-jepa/ft-agentworld-8b tools/distill_agentworld.sh
# eval each against the 40 held-out pairs (token-F1 + OBSERVATION-block match):
PY=refs/llm-jepa/.venv/bin/python
$PY tools/bench_distill.py --model refs/llm-jepa/ft-agentworld-8b --eval datasets/agentworld_distill_eval.jsonl
```
Training: 3 epochs, batch 4 × grad-accum 4, lr 1e-5, max-len 1024, seed 82.

**Result (40 held-out pairs, teacher = Qwen-AgentWorld-35B-A3B):**

| model | token-F1 vs teacher | OBSERVATION hit-rate | VRAM (bf16) |
|---|---|---|---|
| base Llama-3.2-1B | 0.531 | 5% | ~2.5 GB |
| **distilled 1B** | **0.826** | **60%** | ~2.5 GB |
| base Llama-3.2-3B | 0.467 | 0% | ~6 GB |
| **distilled 3B** | **0.868** | **75%** | ~6 GB |
| base Llama-3.1-8B | 0.764 | 35% | ~16 GB |
| **distilled 8B** | **0.958** | **95%** | ~16 GB |
| teacher 35B-A3B (ref) | 1.000 | 100% | ~22 GB (q4) |

Δ student−base: 1B +0.295/+55pts, 3B +0.401/+75pts, 8B +0.194/+60pts (n=40 each —
large, clear effects). The 8B student is essentially teacher-quality at ~16 GB vs the
35B teacher's ~22 GB. Full analysis: `docs/agentworld.md`.

---

## 2. Counsel model — SFT + serve + verify→repair game (HERO)

```sh
just train-counsel              # regular SFT, Llama-3.2-1B on counsel_train, 4 epochs (~1 min, peak ~24 GB)
                                #   → refs/llm-jepa/ft-counsel/
LH_MODEL_PATH=refs/llm-jepa/ft-counsel just model-svc      # serve OpenAI-compat on :8000 (lh-serve/candle)
# run the couple-advice game (generate → retrieve → LLM-judge → repair-once):
lh --provider ollama --model qwen3.6:35b-a3b-bf16 \
   game docs/examples/couple_scenario.json --corpus datasets/wisdom_train.jsonl
```
Eval the served checkpoint: `tools/run_counsel_eval.sh` (uses `tools/eval_counsel.py`).
The game demonstrates the project's "don't trust raw model text" rule: a harsh /
sycophantic / ungrounded answer is rejected by the judge and repaired once. Full
transcript: `docs/RESULTS.md` §3 and `docs/code-review.md`.

---

## 3. JEPA study — does text↔code joint-embedding fine-tuning help? (ablations)

**Verdict: dataset-dependent, not model-dependent.** JEPA helps where the two views
align tightly (NL→regex); nothing on loose alignment (NL→SQL). It costs ~2×
wall-clock; `--jepa_ratio 0.5` recovers most of that. Models behind these rows ship as
the `ft-medium-*` (spider) and `ft-counsel-*-{jepa,regular}-full` (counsel-scaling)
checkpoints.

```sh
cd refs/llm-jepa
PY=.venv/bin/python
# one config, 3 seeds (fast):
$PY ../../tools/run_jepa_seeds.py --dataset synth --seeds 82 23 37 --eval-cap 300
# full suite (full eval + gemma + jepa_ratio + turk), chained, single GPU:
nohup ../../tools/run_jepa_suite.sh > exp-logs/suite.log 2>&1 &
# spider hyperparameter grid (the negative result):
$PY ../../tools/run_jepa_sweep.py --seeds 82 --eval-cap 300
```

| experiment | model | eval | regular (μ±σ) | jepa (μ±σ) | Δ |
|---|---|---|---|---|---|
| synth (NL→regex), full | Llama-3.2-1B | 2000 | 0.578 ± 0.037 | **0.666 ± 0.019** | **+8.8** |
| synth, other model | gemma-2-2b-it | 300 | 0.723 ± 0.090 | **0.857 ± 0.026** | **+13.3** |
| synth, `--jepa_ratio 0.5` | Llama-3.2-1B | 300 | 0.600 ± 0.024 | **0.677 ± 0.014** | **+7.7** |
| turk (other NL→regex) | Llama-3.2-1B | 300 | 0.234 ± 0.009 | **0.264 ± 0.022** | **+3.0** |
| spider (NL→SQL), full grid | Llama-3.2-1B | 300 | **0.287** | ≤ 0.283 | **≤ 0** |

The `ft-counsel-*-3B/8B` `regular`/`jepa`/`dom`/`dom2`/`plus` variants are the
counsel-corpus scaling × augmentation × JEPA ablations (JEPA ≈ +7 @3B, ≈0 @8B —
size & data dominate method). Full tables: `docs/jepa.md`, `docs/jepa-where-it-shines.md`.

> `ft-smoke-*` are 128-sample / 1-epoch **pipeline smoke tests** — they validate the
> training path, they are **not** a result. Shipped for completeness only.

---

## 4. Harness results that need no trained model

These run off the binaries + ollama/solvers (no shipped checkpoint). One command each;
see `dist/examples/cookbook/` for runnable versions and `docs/RESULTS.md` §4–§9.

```sh
lh solve z3     "integers a,b,c in 1..9 all different, a+b+c=17, a*b*c=168; show a model" --expect sat
lh solve prolog "Tom parent of Bob; Bob of Ann and Pat. Find Tom's grandchildren." -n 3
lh solve lean   "For every natural number n, 0 + n = n." -n 4
lh boost "<reasoning question>" -n 9 --temperature 0.8        # self-consistency vote
./tools/run_test_usage_a.sh                                   # ordered-dict: Rust (3/3) + Lean (axiom-clean)
./ci.sh                                                       # fmt + clippy -D warnings + tests
```
