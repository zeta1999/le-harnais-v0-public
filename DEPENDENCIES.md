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

### Which model to pull

The verifier-grounded cascade (`lh solve … --cascade`, and the built-in `default_route`) escalates
`qwen3.6:35b-a3b-bf16` → the **Qwen3.5-9B DeepSeek-V4-Flash distill** → `gemma4:26b` → `gemma4:12b`.
On a big CUDA/VRAM box, pull `qwen3.6:35b-a3b-bf16` (71 GB, the settled best all-round solver).

**On a Mac (incl. 16/24 GB):** pull the distill — it's the only cascade tier that fits, ~10 GB,
dense, clean fenced output, strong on prolog and competitive on lean-with-repair:

```sh
ollama pull hf.co/Jackrong/Qwen3.5-9B-DeepSeek-V4-Flash-GGUF:Q8_0   # ~10 GB — the Mac-lane solver
# then, e.g.:
lh solve prolog "<task>" --model hf.co/Jackrong/Qwen3.5-9B-DeepSeek-V4-Flash-GGUF:Q8_0
```

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
| leanlift (`lift`) | a Lean 4 toolchain (elan/lake); the `rust-*`/`c2r-*` examples and `lift prove` also need Charon+Aeneas, and `c2r-*` needs cpp2rust — both **optional & self-skipping** (see below) | binary in `tools/leanlift/` |
| security (`appsec`) | **Docker** + the scanner images pinned in `tools/appsec/tools.lock` | binary in `tools/appsec/` |
| lean4-skills | a Lean 4 toolchain + the upstream python engine | skills in `tools/lean4-skills/` |

Install hints (per OS) are printed by `check-env.sh` for anything missing.

### `lh logic lean4` against a real project: `LH_LEAN_PROJECT`

By default the lean backend elaborates snippets standalone. Point
`LH_LEAN_PROJECT` at a lake project root and `lh` runs `lake env lean` there
instead, so snippets can `import` the project's modules and mathlib
(`<project>/.lake/packages/mathlib`; override with `MATHLIB_PATH`). This is how
leanlift's independent re-certification calls us: `LEANLIFT_LH=1 lift prove …`
sets `LH_LEAN_PROJECT` to Aeneas's `backends/lean` so both certifiers elaborate
in the same environment.

### leanlift's optional provers (for the bundled `lift`)

`lift`'s sound lanes shell out to tools it locates by env var and **self-skips
without** (clean `SKIPPED`, exit 0 — never a failure):

| tool | enables | build (in a leanlift checkout) | locate via |
|---|---|---|---|
| Charon + Aeneas | `rust-*`, `c2r-*`, `lift prove` (L3) | `scripts/build_aeneas.sh` (OCaml/opam) | `LEANLIFT_AENEAS` |
| cpp2rust | the deterministic C++→Rust→Lean `c2r-*` lane | `scripts/build_cpp2rust.sh` (auto-fetches LLVM 22 if system clang < 21) | `LEANLIFT_CPP2RUST` |

## Linked shared libraries (.so/.dylib)

**Nothing to bundle.** Every bundled binary links only base-system libraries
(glibc/gcc runtime). The one exception class: the `*-cuda` server additionally
links `libcuda` (ships with the **NVIDIA driver**) and `libcublas`/`libcurand`
(ship with the **CUDA toolkit runtime** — NVIDIA-redistributable, but a
driver-only box must install the toolkit runtime or the binary won't load; the
Tier-A `lh` binaries have no such deps). This is *enforced*, not asserted:
`./verify-arch.sh` audits each present binary's `NEEDED`/`otool -L` entries
against an anchored allowlist and fails the publish gate on anything
undeclared or unauditable. Caveat: split binaries (`*.part-*`, e.g. appsec in
the public mirror) are audited only after `join.sh` reassembles them.
Per-binary lists live in `MANIFEST.json` (`linked_libs`).

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
