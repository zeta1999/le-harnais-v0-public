# 06 · agent loop (ReAct tools) — write the AVL OrderedDict in Rust

**Method:** the `lh` agent loop drives generate→edit→`cargo test`→repair until green.
**Why non-trivial:** an order-by-key, self-balancing (AVL) `OrderedDict<K,V>` with
order-statistics `get_index`, balance-property tests — the dict-coding interview task.

- **Model:** ollama `qwen3.6:35b-a3b-bf16` (or `gemma4:26b`). Post the `think:None` fix,
  reasoning models follow the JSON tool protocol cleanly.
- **Dataset / finetuning:** none (zero-shot agent).
- **Run (headless, agent-facing):** `./run.sh`  — scaffolds a crate, runs the agent.
- **Run (interactive TUI):** `lh tui "$(cat task.txt)" --sandbox` from repo root.

Wraps `run_orddict_rust.sh` (guidance skeleton + `cargo check` verify). See
`docs/orddict-tree-experiment.md`, `tools/orddict_avl_skeleton.md`.
