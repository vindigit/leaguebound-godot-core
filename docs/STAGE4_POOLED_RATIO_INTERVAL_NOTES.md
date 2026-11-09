# Pooled ratio uncertainty: implementation evidence

The Wilson endpoint correction does not solve pooled FG% or points-per-possession
uncertainty. The existing competition runner collects paired numerator and
denominator observations by team-game, computes a linearized ratio interval,
then attaches only aggregate totals to the report. `ReportAggregator` rebuilds
the metric from those totals and therefore cannot recover the original
team-game covariance. In particular, pooled FG% is currently rebuilt as a
binomial proportion even though the single-run report explicitly overrides
that interval with a team-game ratio interval. A pooled result must not be
interpreted as preserving the single-run uncertainty method.

An exact pooled reconstruction of the *existing* team-game calculation would
require, per shard, the number of observations and the additive moments
`sum(y)`, `sum(x)`, `sum(y*y)`, `sum(x*x)` and `sum(x*y)`. Once pooled, let
`R = sum(y)/sum(x)` and compute the residual sum of squares as
`sum(y*y) - 2*R*sum(x*y) + R*R*sum(x*x)`. These moments reproduce the
existing residual calculation algebraically, without averaging shard widths.
Floating-point cancellation means it is not necessarily bit-identical to
direct residual summation; constant-ratio inputs need numerical-stability
coverage before a production implementation. A known-answer
test should compare pooled moments against the original concatenated vectors,
including unequal denominators, covariance, empty shards and round-trip
serialization. Existing reports lacking the additional moments cannot acquire
them retrospectively and must not silently receive that interval.

The independent standard-library reference at
`analysis/pooled_ratio_followup/verify_moments.py` checks unequal-shard
pooling against direct residuals, verifies that averaging shard widths gives a
different answer, and demonstrates that regrouping the same team totals into
game clusters changes the interval. Its synthetic tests are algebraic
witnesses, not basketball measurements or a certification result. Its `None`
for insufficient observations or zero opportunity is a proposed missingness
signal; the current `MatchMetricAccumulator.ratio_half_width` returns `0.0`
in those cases. The reference does not yet validate production shard payloads
or their serialization.

This algebra does **not** establish that treating the two team observations in
one game as independent is appropriate. Game-level clustering, the corrected
fixture's quartet dependence, the intended sampling population and sparse
counts require explicit treatment before claiming §27.2 coverage. The
moment-based team-game calculation is an exact reproduction of the existing
estimator, not a newly validated certification method. No sample target,
simulation behavior or shooting rule is changed by this note.

The margin covariance runner had a separate Wilson serialization defect:
`_share` computed endpoints but passed only their half-width to a metric. The
candidate correction now retains the actual endpoints for judged and
informational metrics. Two-game-per-mode runner probes independently check
all four shape metrics, including their estimates and verdicts; they are
structural checks, not calibration evidence. Historical output remains
identifiable as historical. Other explicit interval producers retain their
declared methods rather than being reclassified as Wilson intervals merely
because they provide a half-width.

The correction also clears an old interval when a replacement aggregation
cannot calculate one. Six career-report chains explicitly set a mean width
before attaching mean moments: for two or more observations the aggregation's
existing width remains authoritative; for fewer than two, the previously
reported zero-width interval is now unavailable. This is a reporting
missingness change, not a change to career simulation, point estimates or
locked targets.

For the separate FGA/3PA denominator audit, source inspection identifies the
exact path: `PossessionEngine` emits `FIELD_GOAL_ATTEMPT` before resolving a
shooting foul; on a missed shot it emits `FIELD_GOAL_MISSED` before recording
the foul and awarding free throws. `BoxScoreProjector._apply_attempt` counts
every such attempt, including a three-point attempt when the event's zone is
three. Thus a missed shooting-foul event is included in both denominators as
applicable. A made and-one also counts. `SIMULATION_SPEC.md` §5.1 specifies
one shooter per attempt but does not, in that invariant, settle whether a
missed shooting-foul shot is an official statistical attempt. The owner-locked
competition bands alone do not resolve that definition. Event-ledger examples,
reconciliation tests and the authoritative statistical convention are needed
before proposing any projection or contract change; the observed accounting
is not by itself proof of a defect.

Two primary statistical references make the choice concrete. The
[FIBA Statisticians' Manual 2024, §2.1](https://basket29.com/public/4988/upload/files/faq/248/documents-corporate-fiba-statisticians-manual-2024.pdf)
excludes a fouled shot from FGA unless it is made. The
[2026–27 NCAA Basketball Statisticians' Manual, §1 art. 1](https://s3.amazonaws.com/fs.ncaa.org/Docs/stats/Stats_Manuals/Basketball.pdf)
excludes an unsuccessful attempt when the shooting foul occurs before the
ball is in flight, and has additional context-dependent exceptions. These
are evidence of real-world conventions, not evidence that every fictional
LeagueBound competition has adopted either governing body's full rules. The
FIBA-authored PDF is linked from a French departmental basketball organization
because the indexed FIBA asset URL returned 404 during review. A direct GET of
this copy returned a PDF (SHA-256 `085a164b6c1e63c36d8d33e3073a69d634b382b04ecba488158707e7e1174c3b`).
The NCAA PDF is linked from its current
official statistics resources page. The current ledger resolves its shooting
foul after emitting the attempt and does not in that ordering establish the
release-timing distinction. The owner has now directed LeagueBound to follow
real-world conventions; the competition mapping, source coverage and timing
semantics are being verified before changing official box-score projections.
