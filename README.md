<p align="center">
  <img src="assets/logo.svg" alt="le-harnais" width="160"/>
</p>

<h1 align="center">le-harnais — distribution</h1>

<p align="center">
  <strong>Compiled binaries, models, datasets &amp; companion tools for the <em>le-harnais</em> local-model agent harness.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/status-experimental-yellow.svg" alt="experimental">
  <img src="https://img.shields.io/badge/core-Rust-orange.svg" alt="Rust">
  <img src="https://img.shields.io/badge/targets-linux%20x86__64%20%C2%B7%20arm64%20%C2%B7%20macOS-blue.svg" alt="Targets">
  <img src="https://img.shields.io/badge/python-none-2ea44f.svg" alt="No Python">
  <img src="https://img.shields.io/badge/files-%E2%89%A450MB%20(split)-lightgrey.svg" alt="GitHub-safe">
</p>

> **⚠ Binary distribution.** This repo carries **compiled binaries** and pointers to
> Hugging-Face-hosted models — the source lives in the working repo. Large binaries are
> **split into ≤45 MB parts**; run [`join.sh`](join.sh) once after cloning to reassemble them.

---

## First: reassemble split binaries, then check your machine

```sh
./join.sh            # cat *.part-* → binaries, verify sha256, chmod +x  (only if parts exist)
./check-env.sh       # what's present/missing on this box (REQUIRED / LOGIC / TOOLS)
./install-ollama.sh  # install the generation backend if it's absent
```

## What's Inside

| Dir | Contents |
|---|---|
| [`bin/`](bin/) | the portable `lh` agent CLI (`linux-x86_64`, `linux-arm64`) + `lh-serve` (Linux+CUDA); macOS built on a Mac |
| [`tools/`](tools/) | companion **binaries** + skills: `aria` (quantum), `lift` (leanlift), `appsec` (security), `lean4-skills` |
| [`models/`](models/) | `MANIFEST.json` + `fetch_models.sh` — weights live in per-model Hugging Face repos |
| [`datasets/`](datasets/) | versioned, checksummed backup of the training/eval datasets |
| [`docs/`](docs/) | `CLI-TUTORIAL.md` (hands-on `lh` command tour) · `models.md` (recommended local models + eval log) · `REPRODUCE.md` (exact train+eval per model) · `PROVENANCE.md` (lineage/license) |
| **`check-env.sh` · `install-ollama.sh`** | environment doctor + generation-backend installer |
| **`BINARIES.md` · `DEPENDENCIES.md`** | per-target binary checklist + the full dependency map |

## Platforms

| target | `lh` | `lh-serve` | how |
|---|:-:|:-:|---|
| linux x86_64 | ✅ | ✅ CUDA | prebuilt here |
| linux arm64 (incl. DGX Spark) | ✅ | — (ollama) | prebuilt here |
| macOS arm64 | build on a Mac | Metal (on a Mac) | `./build-mac-all.sh` |

Generation is delegated to **ollama** (recommended) or any OpenAI-compatible endpoint;
`lh-serve` (candle) is the optional native server. `lh` itself is torch/CUDA-free.

## Verify integrity

Every binary is checksummed in `bin/SHA256SUMS`, `MANIFEST.json`, and each tool dir; split
binaries carry a `.sha256` that `join.sh` checks on reassembly. Binary arch labels are
guaranteed by `verify-arch.sh` (a filename like `*-linux-x86_64` always matches its real arch).
