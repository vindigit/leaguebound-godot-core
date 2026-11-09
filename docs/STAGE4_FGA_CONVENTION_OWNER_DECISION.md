# Owner decision: official field-goal attempt convention

**Owner direction on November 9, 2026:** use the real-world conventions for
each competition. The mapping and implementation are being researched and
tested; no projection change has been made yet. LeagueBound's current
ledger and box-score projection count a shot attempt even when the shooter
misses and receives free throws for a shooting foul. The locked simulation
specification requires official statistics to derive from ordered domain
events (§24.3) and says an attempt has one shooter (§5.1), but those clauses
do not state whether a fouled miss is an official FGA. The locked competition
bands alone do not choose a statistical convention. The previous college-FG%
owner package did not establish this denominator question as a cause or rule
out another implementation cause.

## Concrete evidence

In `PossessionEngine`, `FIELD_GOAL_ATTEMPT` is emitted before shooting-foul
resolution. When that shot misses, `FIELD_GOAL_MISSED` is emitted before the
foul is recorded and free throws are awarded. `BoxScoreProjector` increments
FGA for every attempt event, and increments 3PA when the zone is three. Made
and-ones also count as attempts. This is an observed implementation path; the
ordering alone does not establish whether the ball was in flight at contact.

FIBA's 2024 statistician manual excludes a fouled shot from official FGA
unless made. The current NCAA manual excludes an unsuccessful shot when the
shooting foul occurs before the ball is in flight, with additional contextual
exceptions. [Direct source links and provenance](STAGE4_POOLED_RATIO_INTERVAL_NOTES.md)
are retained. Neither manual automatically establishes rules for every
fictional LeagueBound competition, and the current event ordering does not
encode the NCAA release-timing distinction. Their existence is not evidence
that a particular target should be changed or that this issue uniquely causes
the college-FG% miss.

For illustration only: 2 makes in 5 currently counted attempts is 40%; if one
of the three misses were excluded from the official denominator, the same two
makes would be 50%. Actual frequency, composition and confidence intervals
are not established by this example. Removing a missed fouled three also
changes both 3PA and FGA; the direction of 3PA/FGA depends on shot mix. FTA/FGA
and classic possession estimates also change. Engine possession counts and
score are separately defined and must be checked independently.

## Choices

1. **Adopt a unified fouled-miss exclusion for official FGA/3PA.** Treat the
   attempt event as an action record, but do not charge the official attempt
   for a missed shooting-foul shot; retain made and-ones as FGA. This resembles
   the cited FIBA rule. It changes projected box scores and ratio denominators;
   it does not by itself settle other officials' exceptions or authorize tuning.
2. **Adopt explicitly named competition-specific statistical conventions.**
   Specify which conventions apply to high school, college, development,
   overseas and top domestic, including how release timing and unusual cases
   are represented or handled when the current ledger lacks that information.
   This can preserve distinctions, but requires a more detailed decision and
   potentially additional event evidence. Do not assume NCAA or FIBA adoption
   merely from competition names.
3. **Keep the current action-attempt convention.** Explicitly define the
   current totals and their relationship to the spec's “official statistics”
   and §14 calibration bands. This preserves existing projections but requires
   owner acceptance of the distinction from the cited real-world rules; it
   does not make statistical misses or missing evidence pass automatically.

The owner selected competition-specific conventions and then directed that
they follow real life. The following research supplies the working mapping;
fictional leagues are analogues rather than licensed implementations, and
uncertainties are explicit:

| LeagueBound competition | Real-world reference and treatment |
| --- | --- |
| High school | [NFHS's available 2003 statistics manual](https://assets.nfhs.org/umbraco/media/865876/stat_manual_2003.pdf) and an [Ohio high-school association summary](https://www.ohsaa.org/sports/bk/girls/2011/RR2.pdf) distinguish a pre-release foul from a foul after the ball is clearly in flight; made shots count either way. These are older statistical references, so current NFHS statistics wording needs verification. |
| College | The [2026–27 NCAA statistician manual](https://s3.amazonaws.com/fs.ncaa.org/Docs/stats/Stats_Manuals/Basketball.pdf), §1 arts. 3–4, excludes a missed shot fouled before release, counts an attempt after the ball clearly is in flight, and says that remaining doubt is interpreted as not in flight. Made shots count either way. |
| Overseas | The FIBA-authored 2024 manual linked in the [evidence note](STAGE4_POOLED_RATIO_INTERVAL_NOTES.md) excludes a missed shot fouled in the act of shooting; its examples distinguish a later, post-release non-shooting foul. Made shots count. |
| Domestic development and top domestic | The existing profiles are domestic 48-minute, 24-second-shot-clock analogues. A [2011 primary NBA/WNBA data study](https://ratio.huji.ac.il/files/dp593.pdf) describes NBA statistical treatment as counting fouled shot attempts only when made. The [NBA G League's official rule overview](https://gleague.nba.com/gleague-playing-rules) describes its listed experimental playing rules as additions to standard NBA rules, but is not a statistical manual. A current official NBA/G League statistician rule has not yet been independently located. Do not import G League's unrelated experimental free-throw or overtime rules into LeagueBound. |

The NCAA's stated doubt rule is a defensible fallback for the current college
ledger, which does not record release timing; it must not be presented as
observed pre-release contact. For high school, the older available source
specifies what to do when the ball is clearly in flight but does not establish
an explicit unknown-timing fallback in the cited passage. For domestic pro
and development, current official statistical wording remains to be checked.
The implementation must surface any unresolved timing coverage and must not
invent a randomized release-timing distribution or claim to simulate post-release
fouls when it has no evidence for them.

## Required implementation and verification after a ruling

Do not simply suppress `FIELD_GOAL_ATTEMPT`: `MatchStateReducer` counts that
event as a player usage event, and `ParticipantSelector` consumes usage when
selecting participants. Changing the event stream can therefore affect match
behavior. A projection-level approach that retains the action event may be
possible, but must be demonstrated rather than assumed to leave gameplay
unchanged. If release timing is required, decide how it is recorded before
claiming an NCAA-style classification.

Add deterministic ledger cases for missed fouled two- and three-point shots,
made and-ones, ordinary misses, blocks, unrelated fouls, and any authorized
release-timing cases. Reconcile player/team FGA, 3PA, makes, attempts, scores
and possession estimates; verify event order, duplicate handling and seeded
replay. Compare actual events and golden differences if any behavior changes,
and rerun the required home-court and five-competition checks. Re-measure
affected calibration observables on appropriately balanced, predeclared ranges
without changing targets or shooting probabilities to manufacture a pass.
Keep current reporting results and their historical denominator visible.
