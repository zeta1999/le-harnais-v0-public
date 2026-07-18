# le-harnais cookbook — runnable examples

One folder per **(method × a non-trivial use case where it helps)**. Each has a `README.md`
(model · dataset · finetuning · exact commands), a `run.sh`, and `expected.txt`.

| # | method | use case | needs |
|---|---|---|---|
| 01 | verifier-gated best-of-N (boosting #1) | spider SQL: greedy fails, N=5 passes | logic (native), ollama |
| 02 | routing / escalation (boosting #2) | cheap 1B → qwen SQL, mostly-cheap | logic (native), ollama, model-svc |
| 03 | generate→verify→repair + primitive cheat-sheet | Prolog 4-queens | logic (native), ollama |
| 04 | z3 as verifier (prove, not just check) | AVL rotation preserves balance | `lh logic z3` (native) |
| 05 | lean4 proof of program semantics | OrderedDict lookup laws | lean (elan) |
| 06 | agent loop (ReAct tools) | write the AVL `OrderedDict` in Rust | ollama |
| 07 | counsel game (served model + judge) | couple/proverbs advice | model-svc, ollama judge |
| 08 | verifier-grounded cascade routing | mixed: cheap→strong by task | logic (native), ollama |

**Logic is native — no Python sidecar (Phase R1 cutover).** Logic backends run in-process and are
the default; there is no `logic-svc` to start. Just build and run:

```sh
cargo build                       # default features include native logic (z3 via the `z3` binary)
cargo build --features native-z3  # optional: in-process z3 via libz3 (no `z3` binary needed)
lh doctor                         # shows which backends are compiled in + available
./run.sh                          # 01/02/03/08 run fully native — no :8100 service
```

(`LH_LOGIC_REMOTE=<url>` forces the legacy HTTP path against a remote logic-svc, if you run one.)

## Prerequisites (once)
- **ollama** with `qwen3.6:35b-a3b-bf16`, `gemma4:12b/26b/e4b`, `nomic-embed-text`.
- **solvers**: `z3`, `scryer-prolog` (`~/.cargo/bin`), `clingo`, `lean` (elan). Check with `lh doctor`.
- **build**: `cargo build` (native logic by default) — or `--features native-z3` for in-process z3.
- **model-svc** (for 02/07): serve an HF/JEPA checkpoint — `MODEL_DIR=... py/model-svc/run_model_svc.sh`.

Run any example: `cd NN-name && ./run.sh`. Headless by default; agent-loop examples (06, 07) also
run interactively with `lh tui "<task>"`.
