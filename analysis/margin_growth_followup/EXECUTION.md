# Stage 4 margin follow-up execution record

All commands ran from `C:\Users\valexander\leaguebound-godot-core` with
Godot `4.7.1.stable.official.a13da4feb` (Windows console editor build,
assertions active). Starting local and fetched remote head were both
`74b2c55028bbb1a4cc43440ffec52f015c9ba7b2`; the worktree was clean and
PR #1 was open, draft and unmerged before any change.

## Retained matched cells

Run the following command four times, with the declared tuples below:

```text
Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://calibration/runners/run_margin_growth_followup.gd -- --first=FIRST --games=40 --competition=COMPETITION --label=LABEL
```

| Label | FIRST | COMPETITION | Complete rows | Exit |
| --- | ---: | --- | ---: | ---: |
| range_a | 43290000 | college | 240 | 0 |
| range_a | 43290000 | top_domestic_pro | 240 | 0 |
| range_b | 47970000 | college | 240 | 0 |
| range_b | 47970000 | top_domestic_pro | 240 | 0 |

The four processes launched in parallel. `PROTOCOL.md` was written before
retained outcomes. `RUN_PROVENANCE.json` was captured **after launch, before
completion**; its note discloses that limit. Post-run source-hash verification
checks the captured instrument, runner, helper and 286 tracked production/
target files. A separate 24-game probe at 42,120,000–42,120,003 is retained
as `excluded_probe_top_domestic_pro.ndjson` and excluded from every 960-game
summary and inference.

Summarize the four complete raw files with:

```text
node analysis/margin_growth_followup/summarize.mjs analysis/margin_growth_followup/raw/range_a_college.ndjson analysis/margin_growth_followup/raw/range_a_top_domestic_pro.ndjson analysis/margin_growth_followup/raw/range_b_college.ndjson analysis/margin_growth_followup/raw/range_b_top_domestic_pro.ndjson
```

The summarizer accepted exactly 960 game rows and 24 arm/environment cells.
It enforces exact declared ranges, Cartesian matched keys, roster/opener
construction, final score differences, charged-clock duration and aggregate
mechanism witnesses; the GDScript observer enforces component and partition
identities before writing a row. Independent review separately recomputed
373,954 numeric checks over 10,587 segments. Range B top domestic contains
no overtime across 240 arm games; that missing conditional witness is
reported, not filled from selected extra seeds.

## Fresh five-competition current-head revalidation

```text
Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://calibration/runners/run_competition_calibration.gd -- --games=40 --competition=all --label=margin_followup_current
```

This is **200 games total, 40 per competition**, on catalog variations 0–39
and seeds 1–40. The report context's aggregate `sample_count=200` is paired
with an imprecise `sample_unit="complete games per competition"`; its notes,
metric rows and the actual runner correctly identify 40 per competition.
The command exits **1** because nine locked verdicts fail (including the
sample-size gate); it is a preserved calibration outcome, not a fast-gate
failure. The copied JSON is `competition_calibration_current_40_each.json`,
SHA-256 `0cc9332b8cdba181d398a03c0b7b0de3602f93cf1ce883caa5fe26d324d2a7a0`.
It has 98 metrics, 74 judged rows (65 pass, nine fail) and 24 informational
rows. All 92 aggregation-backed estimates and 74 unchanged target/verdict
pairs were independently recomputed. Five informational scorer percentiles
have no stored raw aggregates for an independent numerical reconstruction.
This run uses an existing seed prefix and is not an untouched validation range
or a §27.1 sample.

## Deterministic checks

The focused audit suite passes ten cases, including six live golden output
signatures unchanged. The isolated mutation driver runs an initial nine-case
baseline and sixteen distinct actual-source mutants; all sixteen exit with
named assertion failures, zero parser/runtime errors and zero skipped/flaky/
orphan cases. The identity-preserving ORB-to-residual mutant is killed by
known-answer component assertions. The first isolated import exceeded the
original 240-second timeout and is preserved; the retry import completed.
The driver restored original bytes and verified matching SHA-256 for all four
recorded source files. See `focused_builder_tests.log` and `mutations/`.

## Complete fast gate and publication

The complete eight-step `tools/run_checks.sh` gate exited **0** on the
starting production head with the new observer and tests. Its GdUnit phase
ran 57/57 suites and 703/703 cases: zero errors, failures, flaky cases,
skips or orphans (XML: `reports/report_130/results.xml`, locally generated).
The committed golden-ledger hash, scenario-coverage and replay tests passed;
the home-environment invariants, identical-roster and margin suites passed.
The parser self-test deliberately supplied a malformed fixture and confirmed
nonzero rejection, then confirmed recovery. See `full_gate.log` and
`full_gate_exit.txt`; the expected negative-test diagnostics in the log are
not production parse failures. The evidence manifest recomputed the 960-row
summary byte-identically and verified all 291 captured source fingerprints.
Captured logs were normalized to LF and had trailing display padding removed
before hashing so their committed bytes match a clean checkout; raw game rows
and the computed summary were not edited.
Published-head CI must be checked after the fast-forward push. A calibration
runner's locked-band FAIL is distinct from any structural fast-gate FAIL.
No §27.1 certification is claimed.
