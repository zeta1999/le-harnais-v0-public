# dist/tools — bundled companion tools

Compiled **binaries** (not source) for the companion tools that pair with `lh`,
plus the **agent-facing skills** each one ships. Rule of the bundle: *ship a
binary wherever a binary exists; ship the skill markdown where the tool is a
skill pack.* Every binary here is `linux-x86_64` (built on this host); a
`build.sh` next to each rebuilds it natively for macOS arm64 / linux arm64,
because none of these cross-compile cleanly (Rust→Darwin, Go+CGO/DuckDB).

| tool | form | bundled binary | skills | runtime deps |
|---|---|---|---|---|
| **aria** (quantum DSL) | Rust binary | `aria/aria-linux-x86_64` (1.3M) | — (drives lh's `aria` tool + `docs/quantum`) | none (pure Rust) |
| **leanlift** (`lift`) | Rust binary | `leanlift/lift-linux-x86_64` (1.2M) | `leanlift/SKILL.md` (C++/Go/Solidity → Lean) | Lean 4 toolchain (elan/lake) on PATH |
| **security-toolkit** (`appsec`) | Go binary | `appsec/appsec-linux-x86_64` (57M) | `appsec/skills/{scan-repo,scan-running-app,triage}.md` | Docker + scanner images pinned in `appsec/tools.lock` |
| **lean4-skills** | skill pack (no binary) | — | `lean4-skills/{commands,agents,skills}/*.md` (56 files) | a Lean 4 toolchain + the upstream Python engine (see below) |

## Using them

```sh
# make a bundled binary runnable (or copy it onto your PATH)
export PATH="$PWD/aria:$PWD/leanlift:$PWD/appsec:$PATH"
mv aria/aria-linux-x86_64 aria/aria           # lh's `aria` tool looks for `aria` on PATH
lift-linux-x86_64 --help
appsec-linux-x86_64 --help
```

- **aria** — the pure-Rust quantum-circuit backend behind `lh`'s `aria` tool and the
  `docs/quantum/` KB + recipes. `lh` finds it via `aria` on PATH or `LH_ARIA_BIN=/abs/aria`.
- **leanlift** — "lift a function into a Lean 4 model and prove it's the same function by
  bit-exact differential execution." `SKILL.md` is the portable translation spec.
- **appsec** — orchestrates pinned scanners (gosec, gitleaks, semgrep, trivy, nuclei, …)
  into a one-file DuckDB store; needs Docker to pull the scanner images. The three
  `skills/*.md` are the agent entry points (scan a repo, scan a running app, triage).
- **lean4-skills** — a host-agnostic Lean 4 workflow pack (draft / prove / autoprove /
  golf / refactor / review …). We vendor the **agent-facing markdown** only; the full
  plugin (with its lib/scripts engine) lives upstream — install it from the source repo
  and point your agent host at `plugins/lean4`. `README-upstream.md` is its top-level guide.

## Rebuilding for macOS arm64 / linux arm64

Run the `build.sh` in each dir on the target machine, pointing `SRC=` at a checkout:

```sh
SRC=/path/to/aria-quantum-language-oss-public  ./aria/build.sh
SRC=/path/to/leanlift                          ./leanlift/build.sh
SRC=/path/to/security-toolkit                  ./appsec/build.sh   # needs Go + a C toolchain (CGO)
```

Each writes `‹tool›-‹os›-‹arch›` beside itself; `../check-env.sh` then reports it as
`bundled` for that platform.
