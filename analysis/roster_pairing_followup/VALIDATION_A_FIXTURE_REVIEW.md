# Independent Validation A fixture review

**VALIDATION A FIXTURE CONSTRUCTION ACCEPT.** Inspected the actual catalog and
instrumented runner, then independently verified all 20 Validation A raw cells
(five competitions, baseline/candidate, home/neutral), each with 468 rows.
`verify_validation_a_fixtures.py` reproduces the read-only checks and prints
JSON. It requires ordinary Python execution; optimized mode is rejected.

Every raw report's SHA256 matches its process record. All variations, seeds,
quartet block IDs, and opening-side assignments match the declared sequence.
Every side's complete 10-player by 20-rating vector matches the corresponding
state in the independent 117-state construction archive under the expected
baseline or candidate mapping.

Both versions contain all 117 roster states exactly four times on each side,
with 234 home openers. In the candidate, every combination of roster state,
venue side, and opening-side flag appears exactly twice. Matched home and
neutral arms have identical roster vectors, strength summaries, and opener
assignments for every row.

The candidate diagonal quartet is exactly variations **28080084–28080087** in
every competition and both arms. Its two roster indices coincide, so swapping
them preserves identical ratings; all four observations are retained. The
baseline contains no diagonal roster pairs in this range.

Candidate actual local support is **231 ordered roster-pair cells and 25 of
169 ladder-pair cells**; baseline support is 117 roster cells and 13 ladder
cells. Uniform marginals and the venue/opener crossing do not make this local
slice an independent joint population or cover the full Cartesian cycle.

The protected source diff since completed-gate start `a15bdd00` is empty for
`src`, `calibration`, `tests`, `tools`, project configuration, and the two
basketball specifications. No runtime or test source was edited for this audit.

The raw archive records ratings and strength summaries, not every body/role
field. This audit verifies those recorded values; broader fixture-field
preservation is supported separately by the focused construction tests.
No game-outcome fields were analyzed, no games were launched, and no
Validation B data was read. Statistical conclusions, exact-prefix replay,
publication, and CI require separate evidence. No §27.1 claim is made.
