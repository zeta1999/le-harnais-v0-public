# `lh` — CLI usage tutorial

A hands-on tour of the `lh` command line. Every command below is copy-pasteable. `lh` delegates
generation to a local backend (ollama or any OpenAI-compatible endpoint) and does the reasoning,
verification, and orchestration itself — so most commands take a `--provider` / `--model` pair.

> **Setup once:** `./check-env.sh` (or `lh doctor`) reports which logic backends and models are
> available. Install a generation backend with `./install-ollama.sh`, then
> `ollama pull qwen3.6:35b-a3b-bf16` (see `docs/models.md` for the recommended set). Logic backends
> (`z3`, `scryer-prolog`, `clingo`, `lean`/`lake`) are runtime-PATH deps — `lh doctor` tells you
> what's missing and how to install it.

Global flags worth knowing (they go **before** the subcommand):

```sh
lh --provider ollama --model qwen3.6:35b-a3b-bf16 <cmd> ...   # pick the backend + model
lh --provider openai-compat --endpoint http://127.0.0.1:8080 --model my-model <cmd> ...
lh --json <cmd> ...          # machine-readable envelope (stable contract; see docs/contract.md)
lh --sandbox <cmd> ...       # confine file tools to the working dir
```

---

## 1. Talk to a model — `lh model`

```sh
lh model list                                   # what's available on the backend
lh --model qwen3.6:35b-a3b-bf16 model chat "Explain a red-black tree in two sentences."
lh --model qwen3.6:35b-a3b-bf16 model probe     # capabilities + recommended routing flags
```

## 2. Verifier-gated solving — `lh solve`

The core building block: sample N candidates, keep the **first that a verifier accepts**. Never
trusts raw model text. Backends: `sql`, `prolog`, `datalog` (clingo), `z3`, `lean`.

```sh
# Prolog: generate → run in scryer → repair on failure, best-of-4, with a primitive cheat-sheet
lh --provider ollama --model gemma4:12b solve prolog \
  "Define factorial/2 and query factorial(5, X); X should be 120." -n 4

# Lean 4: the model writes a proof; the native lean4 verifier is ground truth
lh --model qwen3.6:35b-a3b-bf16 solve lean "For every natural number n, n + 0 = n."

# SQL against a spider DB, graded by order-insensitive exec-match vs a gold query
lh --model qwen3.6:35b-a3b-bf16 solve sql concert_singer "List each singer and their concert count." \
  --gold "SELECT ..."
```

Useful `solve` flags: `-n <N>` (candidates), `--cascade "modelA,modelB"` (try cheap→strong,
escalate on verify-fail), `--guidance-file <card.md>` (attach a primitive cheat-sheet),
`--profile <p.toml>` (overlay temperature / rounds / sampler — see §9).

## 3. Call a logic backend directly — `lh logic`

No model in the loop — just run the solver on code you already have (handy for scripting/CI).

```sh
lh logic z3 '(assert (> x 0)) (check-sat)'              # SMT-LIB2 (PROGRAM positional)
lh logic prolog "fact(1). fact(2)." "fact(X)."          # scryer: <PROGRAM> <QUERY> positionals
lh --json logic z3 '(assert (= (+ 2 2) 5)) (check-sat)' # JSON verdict for a script
```

## 4. The agent loop — `lh run` (and `lh tui`)

A headless ReAct loop with tools (read/write/edit/ls/bash, plus optional logic, memory, codegraph,
lean). It proposes an action, runs it, observes, repeats — with step/token/repeat caps and an
escalation handoff when it's stuck.

```sh
# Fix a bug, gated by the project's own test as the verify command, confined to the cwd
lh --model qwen3.6:35b-a3b-bf16 run "Fix the failing test in app.py." \
  --verify-cmd "python -m pytest -q" --max-steps 12 --sandbox

# Give the agent the logic tools too (adds lean_run_code, z3_check, prolog, …)
lh --model qwen3.6:35b-a3b-bf16 run --logic "Prove n+0=n in Lean 4 using lean_run_code."

lh tui "Refactor the parser"          # same loop, interactive TUI
```

## 5. Memory — `lh memory`

A flat file-based store of frontmatter facts with semantic recall (nomic-embed / jepa).

```sh
# save takes: <NAME> <DESCRIPTION> <BODY>  (+ --type user|feedback|project|reference)
lh memory save db-topology "prod DB write path" \
  "Writes go to the primary only; replicas are read-only." --type project
lh memory recall "database topology"        # relevance-ranked
lh memory list
```

## 6. Document retrieval — `lh kb`

PageIndex-style retrieval over a docs/specs tree (reasoning tree beats vector RAG on structured
docs). Includes a token-firewall PDF digest.

```sh
lh kb search ./docs "how does escalation routing work?" --llm   # tree-navigated retrieval
lh kb digest paper.pdf                                          # pdf → local-model digest (frontier reads the digest, not the PDF)
```

## 7. Orchestration, boosting, cascade

```sh
lh orchestrate "Build and test a CLI arg parser"          # decompose → route easy→cheap/hard→strong → synthesize
lh boost --model gemma4:12b "Summarize this changelog"    # self-consistency vote / judge rerank
lh --provider ollama solve prolog "$Q" --cascade "gemma4:e4b,qwen3.6:35b-a3b-bf16"   # escalate on verify-fail
```

## 8. Serve `lh` to a stronger model — `lh mcp` / `lh skills`

```sh
lh mcp                    # expose lh's tools (run, logic, memory, codegraph, …) over MCP stdio
lh skills                 # the driver-model contract (how Opus drives lh as a subagent)
lh skills --json          # machine-readable capability + model-routing manifest
```

## 9. Tune the harness — `--profile`

A profile overlays the *mutable* knobs (think, sampler, temperature, repair rounds, best-of-N,
cascade, guidance) without touching safety knobs. Empty file = today's defaults.

```toml
# my-solver.toml
[inference]
temperature = 1.0
[repair]
max_rounds = 4
```

```sh
lh --profile my-solver.toml --model my-model solve lean "For all a b : Nat, a + b = b + a."
```

## 10. Environment doctor

```sh
lh doctor          # which logic backends are compiled in + available, and what's missing
./check-env.sh     # fuller environment report (rust, ollama, solvers, tool binaries)
```

---

**Where to go next:** the runnable [`examples/cookbook/`](../examples/cookbook/) has one folder per
(method × use case) with a `run.sh` and `expected.txt`. `docs/models.md` lists the recommended local
models per machine. `lh <cmd> --help` gives the exact flags for any subcommand.
