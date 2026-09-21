# Capability-edge upset reachability correction

Authority: `BALANCE_SPEC.md` §3, principle 2 says that ability is not destiny. It defines no minimum upset frequency for this artificial +5-rating mirrored-roster fixture. The possession-derived score contract remains in force. The original fixed 24-game portfolio's `upsets > 0` assertion failed; that failure is retained below and in the raw JSON. This is an explicit test-contract correction, **not an unchanged green gate**.

All original portfolio indices 0–23, `EDGE_SAMPLE = 24`, seed formula `index * 15485863 + 3`, roster construction, opening possession, zero home environment, overlap assertion, slope bounds, and margin-distribution guards remain unchanged. The portfolio-only existential proxy is replaced by a separately named, deterministic full-game upset witness. No production code, locked target, or numerical tolerance was changed.

## Matched audit

Pinned Godot: `4.7.1.stable.official.a13da4feb`. Historical engines run in isolated git-archive snapshots; the exact fixture test was unchanged between those heads. The current production engine is the frozen v17 pace state at `743d845145268d223736e1bfb3a53bd2bf52fa6b`; subsequent commits changed evidence/tests only.

| Engine | Top-domestic pace | +5 portfolio losses / games | Mean home-minus-away margin |
| --- | ---: | ---: | ---: |
| Baseline `15225e8cab5fca2bca9dc2ea4757e2f9e74bbc87` | 0.891 | 3 / 24 | 19.291667 |
| Timing-only `928ebcf` | 0.891 | 3 / 24 | 15.208333 |
| Final pace `743d845` | 0.956 | **0 / 24** | 20.791667 |

The local portfolio loses its upset witness in the pace step. This is an attribution of these fixed seeds, not an estimate of a population change. All three raw margin arrays and cache checks are retained in `score_margin_baseline.json`, `score_margin_timing.json`, and `score_margin_current.json`.

Current mean margins at edges 0, 2, and 5 are 2.541667, 6.375000, and 20.791667. The unchanged slope is 3.65, inside the original 1–7 guard; the unchanged overlap condition is 2 < 26. Fresh index-0 games match the cached +5 margin on each of the three engines, and each fresh repeat has an identical full ledger; see the three `score_margin_*_cache_replay.json` files. No cache contamination was found.

## Selected structural witness

The separately recorded bounded search examined indices 24 through 33 of a declared 24–128 reachability search and stopped at the first stronger-team loss: index 33, seed 511033482, stronger home 99 versus away 115. Independent event totals are also 99 and 115; box-score reconciliation is empty. The full ledger SHA256 is `157a8019310f491e6a04115ad87635a4b4d3e2ac9d12fb0b43d355fee16f9055`.

This selected witness is **not unbiased upset-rate evidence**. It proves that the current engine can produce a full, ledger-reconciled loss for this genuinely stronger roster. The new test verifies every home rating equals its matched away rating plus five, subject only to the existing rating maximum, and verifies that actual ratings increased. It also verifies completed periods/match, independently summed scoring events, final-score and box-score reconciliation, and identical whole-ledger replay. The existing 24-game numerical portfolio remains separate.

The mutation runner replaces only the isolated `MatchEngine.simulate_match` return path with a deterministic reroll policy that keeps producing complete, valid ledgers until the stronger home team wins. This preserves reconciliation and repeated-input determinism, so killing it demonstrates sensitivity to forced winner selection rather than only malformed scoring. See `run_upset_witness_mutation.ps1` and its JSON/log evidence. Shared production source is never mutated; the isolated engine is restored in `finally`.

## Reproduction

From repository root, with `$GodotBin` set to the pinned executable:

```powershell
& $GodotBin --headless --path . -s analysis/timing_pace_followup/audit_score_margin.gd -- --label=current --edges=all --search=yes
.\analysis\timing_pace_followup\run_score_margin_attribution.ps1 -GodotBin $GodotBin
& $GodotBin --headless --path . -s analysis/timing_pace_followup/audit_score_margin_cache.gd -- --label=current
.\analysis\timing_pace_followup\run_upset_witness_mutation.ps1 -GodotBin $GodotBin
& $GodotBin --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a tests/simulation/test_score_margin.gd
```

The failed initial diagnostic-only launch and restart are disclosed in `score_margin_audit_restart_note.txt`; it supplied no accepted measurements. The full focused suite output is `score_margin_focused_recheck.log`. The complete eight-step gate must be rerun after this correction; focused successes are not stitched into an earlier failed gate.

Verification results: full score-margin suite **19/19 passed**, 0 errors, 0 failures, exit 0 (2min 27s 558ms). Isolated witness baseline **1/1 passed**; the valid-ledger forced-favorite mutant was killed by exactly **2 upset-reachability assertion failures**, with all rating, ledger, completion, reconciliation, and repeat checks passing. The restored engine and final test hashes are recorded in upset_witness_mutation.json.
