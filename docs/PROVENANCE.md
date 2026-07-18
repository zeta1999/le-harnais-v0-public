# Model provenance & license

Every model in this distribution is a **derivative fine-tune of a Meta Llama base
model**. None is a redistribution of a base model unchanged. The base weights are
*not* shipped — only our fine-tuned deltas (as full merged checkpoints).

## License (read this)

All shipped checkpoints derive from **Llama 3.1 / Llama 3.2** and are therefore
governed by the **Llama Community License** (the 3.1 and 3.2 community license
agreements, respectively). By the license terms:

- Built with Llama. "Llama" is a trademark of Meta Platforms, Inc.
- Each derivative's name carries a `Llama-` lineage marker (see table).
- You must comply with the Llama Acceptable Use Policy.
- The training **datasets** (`datasets/*.jsonl`) were generated locally with
  `qwen3.6:35b-a3b-bf16` over **public-domain** sources (WEB/KJVA/eBible scripture,
  John Gill's Exposition) and programmatic state/action pairs — see `REPRODUCE.md`.

The non-Llama teacher used for the AgentWorld distillation
(`Qwen-AgentWorld-35B-A3B`, run via ollama) is **not** redistributed here; only the
student weights (which are Llama derivatives) ship.

## Base-model lineage

| this model (HF repo `renaudb1999/le-harnais-<name>`) | base model | params | class |
|---|---|---|---|
| `ft-agentworld-1b` | `meta-llama/Llama-3.2-1B-Instruct` | 1B | HERO |
| `ft-agentworld-3b` | `meta-llama/Llama-3.2-3B-Instruct` | 3B | HERO |
| `ft-agentworld-8b` | `meta-llama/Meta-Llama-3.1-8B-Instruct` | 8B | HERO |
| `ft-counsel` | `meta-llama/Llama-3.2-1B-Instruct` | 1B | HERO |
| `ft-counsel-Llama-3.2-3B-Instruct-regular-full` | `meta-llama/Llama-3.2-3B-Instruct` | 3B | ablation |
| `ft-counsel-Llama-3.2-3B-Instruct-jepa-full` | `meta-llama/Llama-3.2-3B-Instruct` | 3B | ablation |
| `ft-counsel-Llama-3.2-3B-Instruct-regular-full-dom` | `meta-llama/Llama-3.2-3B-Instruct` | 3B | ablation |
| `ft-counsel-Llama-3.2-3B-Instruct-regular-full-plus` | `meta-llama/Llama-3.2-3B-Instruct` | 3B | ablation |
| `ft-counsel-Meta-Llama-3.1-8B-Instruct-regular-full` | `meta-llama/Meta-Llama-3.1-8B-Instruct` | 8B | ablation |
| `ft-counsel-Meta-Llama-3.1-8B-Instruct-jepa` | `meta-llama/Meta-Llama-3.1-8B-Instruct` | 8B | ablation |
| `ft-counsel-Meta-Llama-3.1-8B-Instruct-jepa-full` | `meta-llama/Meta-Llama-3.1-8B-Instruct` | 8B | ablation |
| `ft-counsel-Meta-Llama-3.1-8B-Instruct-jepa-loraembed` | `meta-llama/Meta-Llama-3.1-8B-Instruct` | 8B | ablation (LoRA merged) |
| `ft-counsel-Meta-Llama-3.1-8B-Instruct-regular-dom2` | `meta-llama/Meta-Llama-3.1-8B-Instruct` | 8B | ablation |
| `ft-medium-regular` | `meta-llama/Llama-3.2-1B-Instruct` | 1B | ablation (spider) |
| `ft-medium-jepa` | `meta-llama/Llama-3.2-1B-Instruct` | 1B | ablation (spider) |
| `ft-medium-jepa-drop75` | `meta-llama/Llama-3.2-1B-Instruct` | 1B | ablation (spider) |
| `ft-smoke-regular` | `meta-llama/Llama-3.2-1B-Instruct` | 1B | **smoke** (128-sample pipeline test, not a result) |
| `ft-smoke-jepa` | `meta-llama/Llama-3.2-1B-Instruct` | 1B | **smoke** (128-sample pipeline test, not a result) |

Lineage was confirmed against each checkpoint's `config.json`
(`hidden_size`/`num_hidden_layers`: 2048/16 → 1B, 3072/28 → 3B, 4096/32 → 8B), not
the directory name alone.

## What was stripped before shipping

The on-disk training dirs carried HF `Trainer` `checkpoint-*/` snapshots
(`optimizer.pt` + fp32 master copies for *resume*) — e.g. `ft-agentworld-8b` was
149 GB on disk but only ~15 GB of that is the bf16 model. We ship the **inference
weights only** (the top-level `model-*.safetensors` + tokenizer + configs) and the
GGUF quantizations. No quality is lost — the optimizer state is only needed to
*continue* training, which `REPRODUCE.md` does from the base model instead.
