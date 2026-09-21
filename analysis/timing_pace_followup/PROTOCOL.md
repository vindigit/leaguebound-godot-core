# Timing/pace follow-up measurement protocol

Baseline remote/PR head verified before edits: `15225e8cab5fca2bca9dc2ea4757e2f9e74bbc87`.
PR #1 open, draft, unmerged; clean local worktree fast-forwarded from `74ca367`.
Pinned local Godot: `4.7.1.stable.official.a13da4feb`.

Timing behavior is frozen before pace training. The retained 7000ms coaching cap
is not represented as derived mathematical necessity. Only proven timing
corrections are allowed. Shooting, scoring, overtime and targets are not fitted.

Training: 200 games/profile, variations 17000000–17000199 (seeds +1), matched
arms at shipped pace and 1.10 times shipped pace. Fit a local inverse-duration
response to canonical FULL-game engine possessions per team, including overtime.
Aim at locked §14.1 band interiors while maintaining shipped multiplier order
HS < top domestic < development < overseas < college. Midpoints are an initial
objective, not new acceptance targets. Re-measure fitted values on the training
range; any further training iterations must be archived and disclosed.

Freeze all five values before opening validation A (400 games/profile,
variations 18000000–18000399) and B (19000000–19000399). These ranges were
searched in existing repository evidence and have no prior named use. Both must
pass the original possession bands; no target or tolerance changes. If values
change after reading a range, it ceases to be untouched and replacement ranges
must be declared. Report game-cluster uncertainty, using matched differences for
arm comparisons; two teams in the same game are not independent samples.

The runner inherits canonical competition judgments, verifies every copied rule
field, checks ledger vs accumulator possession totals, and retains per-game raw
terms. Full-game pace is judged; regulation/OT components are diagnostics. All
other metric verdicts remain visible, including failed sample-size certification.
These measurements are not §27.1 certification.

## Training freeze provenance

The engine behavior used for both training arms is the timing change committed
as `928ebcf` (the processes began before the commit, against identical source
bytes). `training-source-hashes.json` and the committed source diff retain that
identity. Test/fixture documentation work during those runs does not affect
`CompetitionCatalog.match_for` or the measurement path. Final pace will receive
its own competition-profile version and source freeze before validation.

Canonical band judgments use point estimates; the supplemental Python
`analyze.py` reports 95% normal-approximation game-cluster intervals and paired
ratio-influence intervals. Those intervals are diagnostic and do not replace
or weaken the canonical target/tolerance rules.
