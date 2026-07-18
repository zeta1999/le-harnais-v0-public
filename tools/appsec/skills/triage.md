# Triage Findings

Analyze and prioritize security findings using Ollama LLM.

## Workflow

1. Ingest findings first: `appsec ingest reports/*.sarif --target . --kind sast`
2. `appsec triage --limit 50 --model qwen2.5-coder:14b` — LLM analysis of findings
3. `appsec query "SELECT f.severity, t.exploitability, t.patch FROM findings f JOIN triage t ON f.id=t.finding_id" --json`
4. `appsec pentest <finding_id> --model qwen2.5-coder:14b` — deep pentest analysis for a finding
5. `appsec suppress suppressions.yaml --apply` — suppress false positives
6. `appsec report --mode triaged --format md` — generate triage report

## Triage output

The LLM provides: exploitability (low/med/high), patch suggestion, and Jira ticket template.
