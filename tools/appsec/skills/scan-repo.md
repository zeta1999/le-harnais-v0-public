# Scan Repository

Scan a codebase with all available security scanners.

## Workflow

1. `appsec detect <path>` — discover languages and applicable scanners
2. `appsec scan <path> --tools <filter>` — run scanners (gosec, gitleaks, bandit, semgrep, trivy)
3. `appsec ingest reports/**/*.sarif --target <path> --kind sast` — load results into DuckDB
4. `appsec top open --db findings.duckdb` — review open findings
5. `appsec report --mode open --format md --db findings.duckdb` — generate report

## Options

- `--tools gosec,gitleaks` — filter to specific scanners
- `--runtime podman` — use podman instead of docker
- `--timeout 10m` — per-tool timeout
