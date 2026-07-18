# Scan Running Application

Scan a live application (web API, web app) using DAST and SCA tools.

## Workflow

1. `appsec scan . --tools trivy,semgrep` — SAST scan of source code
2. `appsec ingest reports/trivy.sarif --target <url> --kind dast` — ingest DAST results
3. `appsec query "SELECT * FROM findings WHERE status='open' ORDER BY severity DESC" --json` — review findings
4. `appsec triage --limit 50` — send findings to Ollama for analysis
5. `appsec report --mode triaged --format json` — generate triage report

## Options

- `--target https://example.com` — DAST target URL
- `--kind dast` — mark as DAST scan
- `--model qwen2.5-coder:14b` — Ollama model for triage
