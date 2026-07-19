# Triage Findings

Analyze and prioritize security findings using Ollama LLM.

## Workflow

1. Ingest findings first: `appsec ingest reports/*.sarif --target . --kind sast`
2. `appsec triage --limit 50 --model qwen2.5-coder:14b` — LLM analysis of findings
   - add `--verify-with-lh` (needs `lh` on PATH) for the falsification pass: 3 refutation
     lenses (reachability / guard / controllability); ≥2 refuted ⇒ finding marked falsified
3. `appsec query "SELECT f.severity, t.exploitability, t.patch FROM findings f JOIN triage t ON f.id=t.finding_id" --json`
4. `appsec pentest <finding_id> --model qwen2.5-coder:14b` — deep pentest analysis for a finding
5. `appsec suppress suppressions.yaml --apply` — suppress false positives
6. `appsec report --mode triaged --format md` — generate triage report

## Triage output

The LLM provides: exploitability (low/med/high), patch suggestion, and Jira ticket template.

## Falsified findings

Fail-safe by default: reports and `appsec top` SHOW lh-falsified findings (a scanned repo
must not be able to hide its own bugs). Pass `--hide-falsified` for the cleaner view once you
trust the pass. `appsec top falsified` lists exactly what was flagged and why (`falsify_reason`,
`falsify_refuted`/`falsify_total`). Nothing is deleted — the verdict lives on the triage row;
SARIF and findings stay intact. A finding is falsified only when ≥2 lenses refute it at ≥medium
confidence.
