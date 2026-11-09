# Offline overtime-reference recount

Read `docs/STAGE4_CLOCK_EVIDENCE_REVIEW.md` for interpretation and limitations.
This directory contains only original analysis code and derived aggregates;
no real basketball data enters the production simulation.

Requires Python 3.10+ standard library. From the repository root:

```bash
python -m unittest discover -s analysis/overtime_reference -v
python analysis/overtime_reference/recount.py --raw-root /path/to/raw_snapshots
```

The raw root has `mbb_schedule/mbb_schedule_YEAR.csv` and
`nba_schedule/nba_schedule_YEAR.csv` for season-ending years 2022–2026.
Exact source asset URLs and SHA-256 hashes are in `recount.json`. Assets may
change upstream; match those hashes for exact historical reproduction. The
original college-2024 input was damaged and rejected whole in
`snapshot_audit.json`. `recount.json` uses a fresh complete publisher copy,
matching the earlier complete snapshot's recorded hash. The two files preserve
the recovery explicitly; do not mix their numerators and denominators.

The CLI writes JSON to stdout. Regeneration is intentional; do not overwrite a
published version without explaining changed source hashes or methodology.
Raw-data availability is not a CI prerequisite: the standalone tests use small
synthetic rows and temporary files only. No third-party Python libraries are
needed for these tests or the recount.

Coverage includes game grain, phase separation, multi-OT counting, special
events, final-score and line-score reconciliation, invalid numeric fields,
empty denominators, malformed seasons and conflicting duplicates. Intervals
are descriptive Wilson binomial intervals, not team/season-cluster robust.

The upstream repository LICENSE concerns software; this review does not assert
an independently verified license to redistribute the ESPN-derived raw assets.
