# Independent Validation B fixture and source review

**VALIDATION B FIXTURE CONSTRUCTION AND SOURCE SCOPE ACCEPT.** Independently
adapted and executed the A construction audit against all 20 completed B cells:
five competitions, baseline/candidate, home/neutral. The analysis-only script
is `verify_validation_b_fixtures.py`; its successful output is
`validation_b_fixture_review.json`. No game process or outcome analysis was
performed.

All raw hashes match their process records. Every cell contains 468 rows with
variations 32760000–32760467, corresponding seeds one greater, correct quartet
IDs, and the declared alternating opener. All 10-player by 20-rating vectors
on both sides match the independent 117-state construction archive under the
appropriate baseline or candidate pairing formula.

Every cell has all 117 states exactly four times on each side and 234 home
openers. Candidate combinations of roster state, venue side, and opening-side
flag each appear twice. Home and neutral arms preserve exactly the same
roster vectors, strength summaries, and opener assignment for every fixture.

Candidate self-pairing occurs precisely in the four retained variations
**32760332–32760335**, across all competitions and both arms. This is one
diagonal quartet, not a missing or duplicated observation. Baseline has no
diagonal pairs in this range. Candidate local joint support is 231 ordered
roster cells and 25/169 ladder cells, compared with baseline's 117 and 13.
These aligned marginals and crossings do not establish independent joint
sampling or full Cartesian coverage in a 468-game slice.

The source-drift check from completed-gate start `a15bdd00` passes. Separately
reran `verify_change_scope.py`; its complete successful output is archived as
`change_scope_review_after_b.json`. Relative to roster-follow-up baseline
`11c4eae`, protected production, specification, workflow, project, and golden
paths remain unchanged; calibration/test changes are exactly the reviewed
sets, including only the three disclosed numerical changes in the existing
FG fixture test. No runtime or test source was edited by this review.

Raw observations expose ratings and strength summaries; they do not serialize
every body/role field. Broader field preservation is covered by separate
construction tests. This acceptance concerns fixture construction and source
scope, not statistical outcomes, exact-prefix replay, publication, or CI.
No §27.1 certification is claimed.
