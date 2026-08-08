# le-harnais — model registry ("good models" list)

*Living list of vetted local models. A model earns a ✅ by clearing `scripts/mini_eval.sh`
(agentic, verifier-graded — see `docs/NEXT-STEPS.md` Track B). This is the "which model do I run
on which machine, and is it worth the trouble" reference.*

**Status legend:** ✅ vetted · 🧪 pending mini-eval · 💤 shelved · ❌ dropped

## Machine tiers (the "can I actually run it here" columns)

| Tier | Hardware | Memory | Practical ceiling |
|---|---|---|---|
| **RTX6000** | RTX PRO 6000 Blackwell (Max-Q) | 96 GB VRAM + 128 GB RAM | Everything, incl. MoE via `--n-cpu-moe` offload |
| **Spark** | DGX Spark (GB10) | 128 GB unified (~273 GB/s) | Whole model must fit in 128 GB; bandwidth-bound |
| **M5-36** | Mac M5 | 36 GB unified | Small dense models only |
| **M4-24** | Mac M4 | 24 GB unified | Smallest dense models only |

## Registry

| Model | Size / quant | Runtime | RTX6000 | Spark | M5-36 | M4-24 | Role | Status |
|---|---|---|:-:|:-:|:-:|:-:|---|---|
| `qwen3.6:35b-a3b-bf16` | ~75 GB (MoE bf16) | ollama | ✅ | — | — | — | **judge + solver (incumbent)** | ✅ **best solver (9/14, 3× faster)** |
| `gemma4:12b` | ~8 GB Q4 | ollama | ✅ | ✅ | ✅ | ✅ | doc-tree navigation (P2.2), light gen | ✅ |
| `ornith:9b` | 5.6 GB (MIT) | ollama | ✅ | ✅ | ✅ | ✅ | coding generator | ✅ |
| `ornith:35b` | 21 GB (MIT) | ollama | ✅ | ✅ | — | — | coding generator | ✅ |
| `north-mini-code-1.0:q4_K_M` | 18 GB (Apache-2.0) | ollama | ✅ | ✅ | — | — | coding gen (tool-call conforming) | ✅ |
| **Antares-1B** (Cisco Foundation AI) | 1.96 GB Q8_0 GGUF / 3.67 GB bf16 (Apache-2.0) | ollama (GGUF) | ✅ | ✅ | ✅ | ✅ | **vuln localization** (CWE/CVE → candidate files) | 🧪 pending mini-eval |
| **Antares-350M** (Cisco Foundation AI) | 0.70 GB bf16 (Apache-2.0) — no published GGUF | ollama (convert first) | ✅ | ✅ | ✅ | ✅ | vuln localization, smallest lane | 🧪 pending mini-eval |
| `ft-ornith-scaffold-3b` (ours) | ~6 GB | ollama/candle | ✅ | ✅ | ✅ | ✅ | scaffold-structured coding | ✅ |
| nomic-embed / jepa | small | lh-serve/ollama | ✅ | ✅ | ✅ | ✅ | embeddings (memory recall) | ✅ |
| **Qwen3.5-9B-DeepSeek-V4-Flash** (distill) | 9.5 GB Q8_0 (**dense**) | ollama | ✅ | ✅ | ✅ | ✅ | **Mac-lane** solver | ✅ solid (8/14; qwen better overall) |
| **Laguna XS 2.1** (poolside) | 20 GB Q4_K_M (MoE 33B / 3B-act) | ollama `laguna-xs-2.1` | ✅ | ✅ | ✅ | ✅ | **fast coding / prolog+z3 gen** | ✅ 9/14 (prolog+z3 8/8, lean 1/6), **~17× faster than qwen** |
| Leanstral-1.5 `Q6_K` (non-4bit) | 97.7 GB (MoE 119B / 6B-act) | llama.cpp `--n-cpu-moe` | ran (66 GB VRAM) | — | — | — | Lean specialist | ⚪ **one-shot 3/6 (quant ruled out); AGENTIC lean_run_code loop 4/6 = qwen tie.** Still shelved for adoption (ties qwen, needs 97 GB + 16-step loop); agentic lever confirmed. See leanstral-eval.md §5-§6 |
| **DeepSeek-V4-Flash** `UD-Q4_K_XL` | 145 GB (MoE 284B / 13B-act, arch `deepseek4`) | llama.cpp | ran (77 GB VRAM) | — | — | — | candidate judge+solver | 💤 **SHELVED (NO-GO)** |
| **DeepSeek-R1-Distill-Qwen-32B** | ~20 GB Q4 (dense) | ollama `deepseek-r1:32b` | ✅ | ✅ | tight | — | reasoning distill | ❌ **3/11 (CoT-format mismatch)** |
| **QwQ-32B** | ~20 GB Q4 (dense) | ollama `qwq:32b` | ✅ | ✅ | tight | — | reasoning | ⚪ deferred (same CoT risk) |
| **DeepSeek-R1-Distill-Qwen-14B** | ~9 GB Q4 (dense) | ollama `deepseek-r1:14b` | ✅ | ✅ | ✅ | ✅ | reasoning distill | ⚪ deferred (same CoT risk) |
| GLM-5.2 (via **colibri**) | ~370 GB experts on disk (744B / 40B-act) | `coli serve` (openai-compat) | disk-stream | disk-stream | — | — | batch oracle only (0.05–1 tok/s) | 💤 shelved |

*Coding-model details + benchmarks:* `docs/local-coding-agents-bench.md`, `docs/model-routing.md`.
Requires **ollama ≥ 0.30.11** (older clients 412 on HF pulls).

### Mini-eval log (2026-07-12, verifier-graded lean+prolog; z3 skipped — not installed; single-seed → DIRECTIONAL)

| Model | lean | prolog | total | speed | note |
|---|:-:|:-:|:-:|---|---|
| **Qwen3.5-9B distill** | 3/3 | 3/3 | **6/6** | fast | proved `a+b=b+a` (others missed it) |
| qwen3.6 (incumbent) | 2/3 | 3/3 | 5/6 | fast | resident judge+solver |
| DeepSeek-V4-Flash Q4 | 2/3 | 3/3 | 5/6 | **~8 tok/s** | ties qwen, lost to its own distill |

### HARD-set (11 tasks: 6 lean + 5 prolog) + bigger-distill test (2026-07-12)

| Model | lean | prolog | total | time | note |
|---|:-:|:-:|:-:|---|---|
| **Qwen3.5-9B distill** | 3/6 | 5/5 | **8/11** | 1478s | best; harness-fit |
| qwen3.6 (incumbent) | 2/6 | 5/5 | 7/11 | 1057s | |
| **R1-Distill-Qwen-32B** | 0/6 | 3/5 | **3/11** | 468s | **CoT-format mismatch** |

**"Does bigger help?" → NO (in this harness), and now root-caused (2026-07-12).**
R1-Distill-32B scored **3/11**. Diagnosis in three layers:
1. **Plumbing (FIXED):** ollama surfaces R1's chain-of-thought in a separate `thinking` field and
   leaves `content` empty unless `think:true` is sent; `solve` sent no think flag → empty content.
   Fixed in the `lh-llm` ollama provider: capture `thinking` as a content fallback + `LH_NUM_CTX`/
   `LH_NUM_PREDICT` budget knobs; `LH_THINK=1` sends `think:true`.
2. **The real blocker (NOT fixed):** even with the plumbing, R1 answers *"write a Lean 4 program"*
   with a **natural-language math proof** ("Here is a step-by-step explanation… Step 1…"), **not
   fenced Lean code** — so there is nothing for the extractor to compile. It needs a
   reasoning-model-specific *terse, fence-forcing* prompt (a bigger change to the shared `solve`
   prompt), not just extraction.
3. **Economics:** when R1 does ramble it burns 5+ min / 8k+ tokens per goal — too slow/verbose for a
   fast verify-repair loop regardless.

**Consequence:** the 9 B V4-Flash distill is the recommended **Mac-lane** solver — it emits clean
fenced code and fits every Mac (where qwen's 75 GB can't). It is NOT faster than qwen (see the
firm-up below — it's ~3× slower and slightly behind overall). **R1/QwQ are a confirmed poor fit** (QwQ-32B / R1-14B share the
NL-prose-proof behavior; not separately benched).

**Terse-prompt rescue attempt — TRIED, didn't work (2026-07-12).** Added an opt-in `LH_REASONING`
fence-forcing prompt + the `thinking`-capture / budget plumbing (`LH_THINK`/`LH_NUM_CTX`/
`LH_NUM_PREDICT`). R1-32B retest: **3/9 (lean 0/3, prolog 1/3, z3 2/3)**. z3 now scores (SMT is
terse enough for R1), but it **still can't emit compilable Lean (0/3)** — the fence-forcing prompt
doesn't overcome R1's NL-prose habit for syntax-heavy targets, and it stays far below qwen (9/14) /
distill (8/14). **Verdict unchanged: R1/QwQ are a dead end here.** The plumbing + `LH_REASONING`
prompt are KEPT (they make any better-behaved reasoning model usable, and z3 works), but bigger
reasoning distills are not worth adopting.

### Multi-vote firm-up — SETTLED, and it OVERTURNS the single-config read (2026-07-12)

3 seeds × the HARD set **now including z3** (z3/clingo installed), ROUNDS=1. Both models were
**deterministic** (identical all 3 seeds → near-zero noise, good):

| Model | lean | prolog | z3 | total | time |
|---|:-:|:-:|:-:|:-:|---|
| **qwen3.6** | 2/6 | 4/5 | **3/3** | **9/14** | ~296s |
| distill (9B) | 1/6 | 5/5 | 2/3 | 8/14 | ~880s |

**qwen3.6 (9/14) > distill (8/14), and is ~3× faster.** The distill's earlier "win" (8/11 vs 7/11)
was **config-specific** — it needed the ROUNDS=2 repair round on lean and excluded z3. Add z3 (qwen
3/3 > distill 2/3) and drop the repair round and the incumbent wins. **Honest correction: "the 9 B
distill is best" was NOT robust** (the exact single-seed trap the honesty rule warns about). Settled
read: **qwen3.6 is the better all-round solver (and faster)**; the **distill is the Mac-lane pick**
(fits every machine, strong on prolog, competitive on lean-with-repair) — not an overall winner.

**Verdict — DeepSeek-V4-Flash SHELVED (NO-GO), mirroring the P4 Leanstral call.** It did **not** beat
qwen3.6 (tied 5/6), is **beaten by its own 9 GB distill** (6/6), and is 145 GB at **~8 tok/s** (the
`deepseek4` "Lightning Indexer"/DSA has no GPU kernel in this llama.cpp build → CPU-bound) while
displacing the judge from VRAM. Incumbent wins the tie. GGUF kept on disk
(`/home/pc/models/deepseek-v4-flash`) for a possible **NVFP4/vLLM re-test** or once llama.cpp adds a
GPU Lightning-Indexer kernel. **The real win: the 9 GB distill** — best on the eval, fits every Mac,
and now the recommended small solver. (Caveat: tiny single-seed set; promote to multi-vote before
"settled".)

## DeepSeek-V4-Flash quant matrix (only if the distill gate passes)

| Quant | Size | Run mode on RTX6000 (96 GB VRAM + 128 GB RAM) |
|---|---|---|
| Dynamic 1-bit / IQ2_XXS | 85 / 87 GB | 100% in VRAM, no offload (max speed, low-bit quality) |
| UD-IQ3_XXS | 103 GB | near-full VRAM + ~7 GB experts in RAM |
| **UD-Q4_K_XL** | **155 GB** | **hybrid VRAM+RAM (chosen)** — ~90 GB VRAM + ~65 GB RAM, no SSD |
| UD-Q8_K_XL (lossless) | 162 GB | hybrid VRAM+RAM, quality ceiling |

**V4-Pro** (1.6T / 49B-act) is **not runnable** on any target here (4-bit ≈ 800 GB+). Ignore.

## Antares — the vuln-localization lane (new model class, 2026-07-21)

Cisco Foundation AI released **Antares** as open-weight (Apache-2.0) task specialists:
**350M** and **1B** now, **3B** announced. This is a class we did not previously have in the
registry: not a generator, not a judge — a *localizer*.

**What the task actually is.** Input = a CWE id + generic weakness description, or a CVE/GHSA
advisory. The model then **explores the repo agentically through a terminal** (`grep`, `find`,
`cat`), iterating like a human investigator — search, read candidates, fold in evidence,
backtrack when a path dies. Output = a **ranked list of source files** likely to contain the
weakness, plus the exploration trace.

**What it is not.** It does **not** discover unknown bugs, and it emits no proof of
exploitability. Cisco is explicit that it supplements rather than replaces dependency analysis,
secret scanning, DAST, and expert review. So it slots *before* our verification lenses, never
in place of them.

**Why it belongs here.** It is the first model in the registry whose native interface is the
same shell-tool loop `lh` already drives, at a size that runs on every tier including M4-24.
The obvious wiring is the SCA→SAST gap in `tools/appsec`: `trivy` reports "dependency X has
CVE-NNNN" and the trail stops; Antares turns that advisory into candidate files, which the
existing `reach` oracle can then test for entry→sink reachability under clingo. That gives an
advisory-driven, *solver-checked* answer to "do we actually reach the vulnerable path" — which
neither a scanner nor a model produces alone.

**Run it:**
```sh
cd dist/models
./fetch_models.sh antares-1b --gguf          # → ./antares-1b/antares-1b-q8_0.gguf (1.96 GB)
ollama create antares-1b -f modelfiles/antares-1b.Modelfile
lh model chat --model antares-1b ...
```
Upstream weights are `fdtn-ai/antares-1b` (3.67 GB bf16) and `fdtn-ai/antares-350m` (0.70 GB
bf16), both Apache-2.0. The Q8_0 GGUF is a **community** conversion (`mitkox/antares-1b-Q8_0-GGUF`)
— convert from the upstream safetensors yourself if that provenance matters. **There is no
published GGUF for the 350M**; it needs its own conversion before ollama can load it.

### Provenance and packaging gotchas (all verified on this box, 2026-08-08)

- **"Open-weight" is Apache-2.0 but access-GATED.** `fdtn-ai/antares-*` returns *"Access to model
  … is restricted and you are not in the authorized list"* even with a valid HF token; the model
  card requires a form that Cisco *"reviews manually"*. The metadata API (file list, license) is
  public, the weights are not. Access for this account was granted 2026-08-08. Plan for a
  human-in-the-loop step before any CI can pull upstream weights — the community GGUF mirror is
  the only ungated path.
- **It is a `granitemoehybrid`, not a dense Granite.** `config.json` reports
  `GraniteMoeHybridForCausalLM`, 40 layers, hidden 2048, vocab 100352, ctx 131072. ollama reports
  `arch=granite, parameters 1.8B`.
- **The community GGUF ships NO chat template.** `ollama show` reports `{{ .Prompt }}` and
  capability `completion` only. Loaded as-is the model ignores instructions and emits generic CWE
  prose. `modelfiles/antares-1b.Modelfile` now carries the template ported from the upstream
  `chat_template.jinja`.
- **It is a reasoning model.** The upstream generation prompt ends with
  `<|start_of_role|>assistant<|end_of_role|><think>`, so every reply is `…reasoning…</think>answer`.
  Any driver must split on `</think>` and budget tokens for the reasoning phase — a 24-token cap
  returns nothing usable.
- **ollama resolves `FROM` relative to the Modelfile's own directory**, not the cwd. Since
  `fetch_models.sh` downloads to `dist/models/<name>/`, a Modelfile in `modelfiles/` needs `../`.
  A wrong relative path fails with the very misleading `400 Bad Request: invalid model name`.
- **Do not one-shot it.** Asked to name a file without tools, it *invents* file contents to
  justify its answer ("the code contains several direct SQL query constructions …" about a file
  it never read). Its native interface is the `<tool_call>` / `<tool_response>` loop; give it real
  `grep`/`cat` results or treat its output as fiction.

Note the sizes: the "1B" is 3.67 GB in bf16, i.e. closer to ~1.8B parameters once embeddings are
counted. Still trivially resident on every tier, but it is not a 1 GB model. **Set `num_ctx`**:
at its advertised 131072 default ollama reserved **13 GB** for this 1.8B model — more than
`gemma4:12b` sitting beside it. The Modelfile pins 32768, which costs **4.6 GB**.

### First local eval (2026-08-08) — `tools/antares_localization_eval.py`

Run against `security-toolkit/test_sources/vuln-webservers` (39 labels, 5 files), one shot per
task, **no agentic tool loop**. `gemma4:12b` is the control — a 7× larger generalist.

| Task | what it asks | antares-1b | gemma4:12b |
|---|---|---|:-:|
| FILE | scanner + rule + note → pick 1 of 5 files | 54% | **82%** |
| FILE_BLIND | description only → pick 1 of 5 files (chance 20%) | **38%** | 21% |
| SYMBOL | file given → name the function (n=20) | **80%** | 60% |

**Read FILE as a trap, not a result.** Naming the scanner leaks the language — `gosec` means Go,
`bandit` means Python, `cargo-audit` means Rust — so that column measures scanner trivia, which a
generalist has and a task specialist does not. An earlier version of this eval only had that
column and appeared to show Antares losing badly (36% vs 85%). Removing the tool name reverses it:
on FILE_BLIND **gemma4 collapses to 21%, i.e. chance**, while Antares roughly doubles chance.

SYMBOL is the closest proxy to the real task, and Antares wins it 80% to 60% at ~1/7 the size.
That is the claim holding up in the dimension that matters.

Status stays 🧪 regardless: n=39/20 on a 5-file planted-bug corpus is a sanity gate, not a
benchmark, and none of this exercised the agentic grep/find/cat loop the model is actually built
around. Treat these as "not obviously broken, and specialized in the direction advertised."

**Gate before promotion.** Status stays 🧪 until it clears a mini-eval *we* run. The published
numbers — 500-task Vulnerability Localization Benchmark, "outperforms a dozen larger models" —
are Cisco's own, on Cisco's own benchmark, with no independent replication yet. `security-toolkit`
already has labeled corpora (`test_sources/*/EXPECTED.md`) and a `bench` command that scores
recall and false positives; that is the cheapest honest check and should run before any routing
change depends on this model.

## Rules of thumb
- **Never hold two big models at once.** The qwen3.6 judge (~75 GB) can't co-reside with a
  VRAM-resident V4-Flash or a 35B generator — unload one first (OOM risk on the 96 GB card).
- **Mac lane = dense small models only** (distills, `ornith:9b`, `gemma4:12b`). The real MoE never
  fits a Mac; a distill is the evolutionary offshoot that shrank to fit.
- **Big/MoE → ollama or llama.cpp, never candle.** Portability lives in `lh-llm`; candle stays bf16
  + CUDA/Metal for the small-model native path.
- **A task specialist beats a bigger generalist only on its task.** Antares localizes; it does
  not reason about exploitability. Don't route a verification lens to it because it's cheap.
- **Third-party weights stay third-party.** Antares is fetched from the upstream HF repo, not
  re-hosted under `renaudb1999/le-harnais-*` — see `class: external` in `models/MANIFEST.json`.

Sources: [unsloth/DeepSeek-V4-Flash-GGUF](https://huggingface.co/unsloth/DeepSeek-V4-Flash-GGUF) ·
[Jackrong/Qwen3.5-9B-DeepSeek-V4-Flash-GGUF](https://huggingface.co/Jackrong/Qwen3.5-9B-DeepSeek-V4-Flash-GGUF) ·
[JustVugg/colibri](https://github.com/JustVugg/colibri) ·
[fdtn-ai/antares](https://huggingface.co/collections/fdtn-ai/antares) ·
[Antares announcement](https://blogs.cisco.com/ai/introducing-antares-the-most-efficient-open-weight-ai-models-for-vulnerability-localization) ·
[Antares technical report](https://cisco-foundation-ai.github.io/antares/technical-report.pdf)
