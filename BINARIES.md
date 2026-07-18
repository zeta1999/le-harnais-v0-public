# Binary completion checklist

The per-`(binary × target)` build status. This bundle was assembled on a
**linux-amd64 + CUDA** box, which cannot cross-build Apple-Silicon binaries — so the
**macOS arm64** rows are left open for a **macOS agent** to complete.

Legend: ✅ built & bundled here · ☐ to build on that platform · — not applicable.

| binary | linux-x86_64 | linux-arm64 | macOS arm64 | build command | runtime deps |
|---|:-:|:-:|:-:|---|---|
| `lh` (core agent) | ✅ | ✅ | ☐ | see below | ollama (generation) |
| `lh-serve` (candle) | ✅ cuda | — (use ollama) | ☐ metal | `cargo build -p lh-serve --features {cuda,metal}` | CUDA sm_120 / Metal |
| `aria` (quantum) | ✅ | ☐ | ✅ | `tools/aria/build.sh` | none (pure Rust) |
| `lift` (leanlift) | ✅ | ☐ | ☐ | `tools/leanlift/build.sh` | Lean 4 toolchain |
| `appsec` (security) | ✅ | ☐ | ☐ | `tools/appsec/build.sh` (Go+CGO) | Docker + scanners |

Sub-note: `lh-linux-arm64` doubles as the **DGX Spark** core binary; `lh-serve` for the
Spark is built **on the Spark** (`--features cuda`, sm_121).

## SHA-256 (first 16 hex) of what's bundled here

```
lh-linux-x86_64              373625560d6aa6e4   (13M)
lh-linux-arm64               7b43af3641386fda   (15M)
lh-serve-linux-x86_64-cuda   4e8b336b2cb34543   (19M)
aria-linux-x86_64            f755e42d3f6addb1   (1.2M)
aria-macos-arm64             2cc0e5309ca282f8   (1.4M)
lift-linux-x86_64            7e9cd6830ee0b601   (1.2M)
appsec-linux-x86_64          6d88936b3b0fdaf8   (57M → split in the public mirror)
```

Full digests live in `bin/SHA256SUMS`, `MANIFEST.json`, and each tool's dir.

## macOS agent: how to close the ☐ rows

On an Apple-Silicon Mac with Rust, a Lean 4 toolchain, Go (+ Xcode CLT for CGO/Metal),
clone this repo and run **one script**:

```sh
./dist/build-mac-all.sh
```

It builds every missing macOS binary (`lh`, `lh-serve --features metal`, `lift`, `appsec`),
strips them, labels them `‹tool›-macos-arm64`, **verifies each arch label**
(`dist/verify-arch.sh`), refreshes `bin/SHA256SUMS`, and rewrites the ☐ macOS cells above
to ✅. Then commit. (`aria-macos-arm64` is already provided, so that row is done.)

Per-tool source checkouts default to the sibling paths (`SRC=…` overrides): aria →
`../aria-quantum-language-oss-public`, lift → `../leanlift`, appsec → `../security-toolkit`.
The `lh`/`lh-serve` sources are this repo. See `DEPENDENCIES.md` for the toolchains.
