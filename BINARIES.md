# Binary completion checklist

The per-`(binary × target)` build status. This bundle was assembled on a
**linux-amd64 + CUDA** box, which cannot cross-build Apple-Silicon binaries — so the
**macOS arm64** rows are left open for a **macOS agent** to complete.

Legend: ✅ built & bundled here · ☐ to build on that platform · — not applicable.

| binary | linux-x86_64 | linux-arm64 | macOS arm64 | build command | runtime deps |
|---|:-:|:-:|:-:|---|---|
| `lh` (core agent) | ✅ | ✅ | ✅ | see below | ollama (generation) |
| `lh-serve` (candle) | ✅ cuda | — (use ollama) | ✅ metal | `cargo build -p lh-serve --features {cuda,metal}` | CUDA sm_120 / Metal |
| `aria` (quantum) | ✅ | ☐ | ✅ | `tools/aria/build.sh` | none (pure Rust) |
| `lift` (leanlift) | ✅ | ☐ | ✅ | `tools/leanlift/build.sh` | Lean 4 toolchain; optional self-skipping: Aeneas (`prove`/`rust-*`/`c2r-*`) + cpp2rust (`c2r-*`) |
| `appsec` (security) | ✅ | ☐ | ✅ | `tools/appsec/build.sh` (Go+CGO) | Docker + scanners |

Sub-note: `lh-linux-arm64` doubles as the **DGX Spark** core binary; `lh-serve` for the
Spark is built **on the Spark** (`--features cuda`, sm_121). Both `appsec` binaries are built
from security-toolkit `585147d` (linux here, macOS by the Mac agent).

## SHA-256 (first 16 hex) of what's bundled here

```
lh-linux-x86_64              252e54bcd51857e2   (13M, @2d03a8f — R1-R8 eval fixes, rebuilt 2026-07-24)
lh-linux-arm64               a466e608d3d10a36   (15M, @2d03a8f — R1-R8 eval fixes, rebuilt 2026-07-24)
lh-serve-linux-x86_64-cuda   3270dcbb06b7a389   (19M, @d5cdcc5 — sm_120, rebuilt 2026-07-19)
lh-macos-arm64               7ddb24cb9ce167b1   (11M, @56b9e5b — Apple M4/M5, R1-R8 eval fixes)
lh-serve-macos-arm64-metal   d68c7277b438c960   (9.1M, @ce3cd80 — Metal backend)
aria-linux-x86_64            f755e42d3f6addb1   (1.2M)
aria-macos-arm64             1f607b0d8cb4c19a   (1.0M)
lift-linux-x86_64            8e8f4ccc18db4e9d   (1.4M, leanlift@e9c5b07 — includes the c2r lane)
lift-macos-arm64             66a28b1d9d953d8e   (1.2M, leanlift@e9c5b07 — includes the c2r lane)
appsec-linux-x86_64          88ee6fb23fbe32d1   (57M → split; security-toolkit@585147d)
appsec-macos-arm64           10f374fc6bbf446e   (49M → split; security-toolkit@585147d)
```

Full digests live in `bin/SHA256SUMS`, `MANIFEST.json`, and the top-level
`SHA256SUMS` (which covers the tool binaries too). `@hash` = source commit the
binary was built from. Bundled binaries' linked shared libraries are audited
by `verify-arch.sh` (base-system only — see `DEPENDENCIES.md` §"Linked shared
libraries"; split binaries only after `join.sh`) and recorded per-binary in
`MANIFEST.json` (`linked_libs`).

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
