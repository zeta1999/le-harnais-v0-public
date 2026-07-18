# le-harnais — dependencies

What each capability needs, at **build** time and **run** time, per target. Run
`./dist/check-env.sh` to see which of the runtime ones are present on a machine.

## The one dependency everyone needs: a generation backend

`lh` delegates all text generation. Pick one:

- **ollama** (recommended, every platform) — `./dist/install-ollama.sh` (or
  `curl -fsSL https://ollama.com/install.sh | sh` on Linux, `brew install ollama` on macOS).
  Faster than candle for plain generation (see `docs/candle-bench.md`).
- **`lh-serve`** (candle) — optional native server for bf16 safetensors; **Linux+CUDA** or
  **macOS+Metal** only. Use ollama unless you specifically need it.
- any **OpenAI-compatible** endpoint — `lh` speaks it via `lh_llm::LlmClient`.

## Runtime dependencies (by feature)

| feature | needs on PATH / running | bundled instead? |
|---|---|---|
| agent loop, memory, recipes, RAG, KB, MCP | — (in the `lh` binary) | ✅ pure Rust |
| logic: `sql` | — | ✅ bundled sqlite (pure Rust) |
| logic: `prolog` | — | ✅ bundled scryer (pure Rust) |
| logic: `z3` | `z3` | shells out |
| logic: `clingo` | `clingo` | shells out |
| logic: `lean` | `lean` + `lake` (elan toolchain) | shells out |
| generation | ollama **or** an OpenAI-compat endpoint **or** `lh-serve` | — |
| quantum (`aria` tool, `docs/quantum`) | `aria` on PATH (or `LH_ARIA_BIN`) | binary in `tools/aria/` |
| leanlift (`lift`) | a Lean 4 toolchain (elan/lake) | binary in `tools/leanlift/` |
| security (`appsec`) | **Docker** + the scanner images pinned in `tools/appsec/tools.lock` | binary in `tools/appsec/` |
| lean4-skills | a Lean 4 toolchain + the upstream python engine | skills in `tools/lean4-skills/` |

Install hints (per OS) are printed by `check-env.sh` for anything missing.

## Build dependencies (only if rebuilding from source)

| artifact | toolchain | notes |
|---|---|---|
| `lh` core (all targets) | **Rust** only (rustup) | torch/CUDA-free; `lh-serve` is out of `default-members`, so a core build pulls no GPU deps |
| `lh` linux-arm64 | Rust + `cross` + Docker | `dist/build-matrix.sh arm64` |
| `lh` macOS arm64 | Rust (`rustup target add aarch64-apple-darwin`) | `dist/build-macos.sh` — must run on a Mac |
| `lh-serve` linux | Rust + **CUDA toolchain** (sm_120, `CUDA_COMPUTE_CAP=120`) | `cargo build -p lh-serve --features cuda` |
| `lh-serve` macOS | Rust + **Xcode/Metal** | `cargo build -p lh-serve --features metal` |
| `aria` | Rust only | `tools/aria/build.sh` |
| `lift` | Rust only | `tools/leanlift/build.sh` |
| `appsec` | **Go** + a **C toolchain** (CGO, for DuckDB) | `tools/appsec/build.sh` |

See `BINARIES.md` for the exact per-target binary checklist and which rows are still open.
