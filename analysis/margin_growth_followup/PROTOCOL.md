# Stage 4 signed margin growth follow-up protocol

Recorded before either retained cell is run. The 4-variation probe at
42,120,000–42,120,003 is excluded from all results. Both retained ranges below
are untouched by that probe and disjoint from the roster-pairing diagnostic and
validation ranges.

| Range | Variations | Games per arm, competition and environment |
| --- | --- | ---: |
| A | 43,290,000–43,290,039 | 40 |
| B | 47,970,000–47,970,039 | 40 |

Each range contains ten aligned roster quartets. Run college and top domestic
with the same numerical `variation+1` seed in three roster arms at environment
strength 0.0 and 0.5, for 240 games per competition and range, 960 games total.
All six cells of a competition/variation share match ID, game ID and opening
assignment, so derived random-stream names are identical within that
competition. Competition IDs deliberately differ, so the college/top comparison
is descriptive rather than a common-random-number counterfactual.

The arms are: ordinary catalog AB; identical AA using the ordinary fixture's
home roster on both sides; and reversed BA, swapping the ordinary roster
indices while retaining venue and opener assignment. AA changes the away full
roster and is an equalization intervention, not an isolated percentage of
margin variance caused by pregame strength. BA is a paired reversal, not an
exact sign-reversed replay. Home-minus-neutral changes only environment
strength within the same arm and seed.

Archive every completed game as one NDJSON row, with a header and an exact-count
completion footer. The ledger instrument must reconcile scoring events to
period scores and the final result, shot probes to attempts, and its six-term
and conditional seven-term signed-margin identities. The analysis must reject
duplicates, missing matched keys and incomplete cells. Channels are accounting
identities and covariance shares; they are not causal allocations. The
conditional shot innovation captures the make-roll residual after the observed
block decision, not all shooting or game-state uncertainty.

Report signed margin and its SD cumulatively by native period and by four equal
elapsed-regulation bins, plus the final 120 seconds and overtime separately.
Report the pre-120 leader-aligned increment, absolute-margin expansion, and
close-to-wide transitions to avoid treating an absolute value as signed
growth. `live_ms` in raw rows means charged game-clock milliseconds, including
charged inbound time. Compare final close/blowout shares, mean signed margin,
SD, and matched contrasts. Quartets are the uncertainty cluster. With only ten
quartets per range, these new arms are mechanism diagnostics, not a new
acceptance sample; retain both ranges separately and disclose sparse events.

The earlier two 468-game untouched roster-pairing ranges remain the strongest
replicated observation of the top-domestic close-game failure. This follow-up
must not alter targets, tolerances, outcomes or §27.1 certification status.
