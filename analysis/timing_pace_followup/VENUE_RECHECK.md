# Controlled venue recheck

200 matched fixtures per competition on the established diagnosis variations
710000–710199, each run at home, neutral and reversed venue: 1000 triples / 3000
complete games. Mirror rosters, environment 0.5, frozen v17 timing and v2 pace.
This is a diagnostic recheck, not a new pace holdout or §27.1 certification.
No venue value was tuned from these results.

## Canonical paired estimators

| Competition | Attributable home-win ±95% half-width | §14.2 verdict | Paired points/100 ±95% half-width | §17.4 cap verdict | Report checkout |
| --- | ---: | --- | ---: | --- | --- |
| high school | 0.5575 ±0.0334 | pass | 2.0322 ±0.9181 | pass | `743d845` |
| college | 0.5375 ±0.0318 | pass | 1.7317 ±0.8187 | pass | `743d845` |
| development | 0.5450 ±0.0320 | pass | 1.4049 ±0.7732 | pass | `401be24` |
| overseas | 0.5575 ±0.0334 | pass | 1.9446 ±0.8024 | pass | `743d845` |
| top domestic pro | 0.5350 ±0.0330 | pass | 1.3933 ±0.7492 | pass | `401be24` |

All five paired home-win and paired cap verdicts pass. The win band is the
unchanged 0.53–0.56; the paired points cap remains 2.5. Judgments use canonical
point estimates, not whether intervals overlap bands. The points interval uses
the report's existing fixed observed possession denominator; it does not
incorporate denominator uncertainty as a ratio-influence interval would.

For each fixture, let h/n/r be home/neutral/reversed venue-side margins and
w(m) be 1/0.5/0 for win/tie/loss. The symmetrized win estimate is
mean[0.5(w(h)+w(r))]. Paired margin gain is mean[0.5(h+r)], and paired points/100
is 100 times that gain divided by mean[(home possessions + neutral possessions
+ reversed possessions)/3]. The neutral terms cancel algebraically in the
symmetrized numerator; every complete triple is nevertheless retained and
validated by the canonical estimator.

## Retained legacy and informational readings

| Competition | Legacy efficiency-gap contribution | Legacy cap verdict | Home-only informational points/100 |
| --- | ---: | --- | ---: |
| high school | 2.442982 | pass | 2.602595 |
| college | 1.474889 | pass | 1.584275 |
| development | 1.930095 | pass | 2.009224 |
| overseas | 2.632164 | fail | 2.486573 |
| top domestic pro | 0.632684 | pass | 0.668711 |

The sole failed judged metric across these five reports is overseas
`home.combined_cap_respected`: its legacy efficiency-gap contribution is
2.63216429108761, above 2.5. That report therefore remains FAIL. Its paired
`venue.cap_respected` passes at 1.9445730537734. Neither verdict is hidden or
substituted for the other.

The legacy contribution subtracts the neutral arm's venue-minus-visitor
points/possession gap from the home arm's gap, then multiplies by 100. The
home-only informational metric instead uses the paired home-minus-neutral
margin divided by home-arm venue possessions. High school's informational
2.602595 exceeds 2.5 but has no judged cap verdict. The estimator section also
retains a home-only value using the all-three-arm possession base; that is
another denominator and is not the identically named printed metric. These
figures must not be conflated with each other or the canonical paired cap.

The full reports preserve all eight judged metrics per competition, including
reversal, completeness and probability-cap checks, plus all informational rows
and all raw triples. HS, college, development and top domestic each have zero
failed judged metrics. Per-profile passes on this small diagnosis block do not
close broader home-court calibration or certification questions. They also do
not erase the distinct population raw-home-win failures in the pace holdouts.

Report HEADs differ only because the test-fixture commit occurred between
launches. `401be24` has identical production/calibration/project inputs to
frozen `743d845`; no simulation inputs changed during these runs.
