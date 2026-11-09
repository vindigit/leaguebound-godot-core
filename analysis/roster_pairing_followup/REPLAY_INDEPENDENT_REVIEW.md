# Independent exact-row replay review

Verdict: ACCEPT `final_20260924` for exact observed raw-row reproducibility, twenty cells and eighty games.

The independent verifier confirms the summary binds all twenty distinct result files by SHA256, covering both baseline/candidate trees, all five competitions and both environment arms without omissions. Every result is completed with exact-match true, no differences, no timeout or error, and an accepted exit code consistent with its tiny-sample canonical failures. External replay stderr is empty.

Each original process/raw/report hash, expected-row hash, replay raw/report hash, log hash, source snapshot and executable hash reconciles. Recorded before/after runtime source snapshots agree and match current bytes. Frozen source checks preserve the exact candidate-only consumer-width exception and retain the baseline without that exception. The replay script hash and protocol/freeze plan hashes match.

The four diagnostic-prefix variations are 23400000–23400003 and seeds 23400001–23400004. The replay command uses four games and shard 5850000, preserving `shard * games = 23400000`. Original/replay competition, catalog and environment metadata agree. All complete per-game raw rows match their original prefix exactly under canonical JSON serialization, including numeric representation; there is no tolerance-based comparison. Runtime logs contain no script, parse, error, warning, fatal, exception or traceback diagnostics. Canonical tiny-sample metric failures are retained and match report identities.

`verify_replay_archive.py` is a reproducible analysis-only verifier. Its first draft rejected legitimate metric identifiers containing digits (for example turnovers_per_100_possessions); the identifier parser was corrected before the successful independent check. No replay or measurement artifact was changed for that audit-parser correction.

This proves equality of the instrumented raw observation rows. It does not prove event-ledger byte identity or constitute eighty additional calibration observations. The replay remains separate from the 28,080 completed experiment observations. Final published-head, clean-tree, draft/unmerged PR and exact-head CI verification remain separate requirements.

Machine-readable hash bindings are retained in `replay_independent_review.json`.
