# 01 · verifier-gated best-of-N (boosting #1) — spider SQL

**Method:** sample N SQL candidates; the sqlite verifier is the *selector* — keep the first
that executes and exec-matches `gold`; early-stop. Greedy first (attempt 1 temp 0), the rest
sampled, so you pay for extra samples only when greedy fails verification.

**Where it helps — and where it doesn't (measured here, `tools/boost_sweep.sh`):** best-of-N
lifts accuracy only in the **unreliable-but-covers** band (per-shot ~40–70%: greedy often
fails, but *some* sample passes). It is **not** free lunch:

| query set (gemma4:12b, n=1 vs n=5) | greedy | best-of-5 | lift | cost |
|---|---|---|---|---|
| **easy** spider head (counts, single joins) | 9/10 | 9/10 | **0** | ~1× (all wins at attempt 1 — verifier just confirms greedy, no extra samples) |
| **hard** (set-difference / `EXCEPT` / nested — `BOOST_HARD=1`) | low | — | the lift band: greedy unreliable, a sample can pass | >1× |

So on easy queries greedy is already reliable → best-of-N adds nothing (but costs ~1× thanks
to early-stop); the lift shows up on hard queries where greedy is shaky. **Pick N by the
model×task reliability**, and use the verifier so you never ship a wrong candidate.

- **Model:** ollama `gemma4:12b` (small non-reasoning — the best-of-N sweet spot; reasoning
  models inflate per-attempt cost, see `docs/boosting.md` §1).
- **Dataset:** spider (`refs/llm-jepa/spider_data`, 166 DBs); queries from `spider_test.jsonl`.
- **Finetuning:** none (gold is the verifier signal, not a training label).
- **Needs:** native logic (in-process, default); `LH_SPIDER_PATH` → the spider DBs.

**Run a single best-of-5 (the WINNER + token cost):**
```sh
./run.sh                       # one concert_singer query, -n 5
```
**Reproduce the regime sweep (easy vs hard):**
```sh
NQ=10 BOOST_MODEL=gemma4:12b               bash ../../tools/boost_sweep.sh   # easy head → ~0 lift
NQ=10 BOOST_MODEL=gemma4:12b BOOST_HARD=1  bash ../../tools/boost_sweep.sh   # hard → lift band
```

See `docs/boosting.md` §1, `exp/boost_sweep/`. The robustly-demonstrated boosting win on this
setup is **escalation** (cookbook 02): cheap fails → strong passes, gated by the verifier.
