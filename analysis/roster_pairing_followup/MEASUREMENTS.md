# Matched roster-pairing measurements

Each cell has 468 games in 117 quartet clusters. Intervals are exploratory,
conditional on fixed schedule slices; no multiplicity adjustment, equivalence
claim or §27.1 certification. Canonical targets/verdicts are unchanged.
Population home-win verdicts are not controlled even-team venue judgments.

## diagnosis

### high_school

| Home-environment metric | Before | After | Paired change ± 95% half-width | Before → after canonical verdict |
| --- | ---: | ---: | ---: | --- |
| possessions_per_game | 66.457265 | 66.504274 | 0.047009 ± 0.292883 | pass → pass |
| points_per_game | 63.212607 | 63.439103 | 0.226496 ± 0.586830 | informational → informational |
| points_per_possession | 0.951177 | 0.953910 | 0.002733 ± 0.007895 | pass → pass |
| field_goal_percentage | 0.383536 | 0.384365 | 0.000829 ± 0.003255 | fail → fail |
| three_point_percentage | 0.301657 | 0.301059 | -0.000597 ± 0.006693 | pass → pass |
| free_throw_percentage | 0.670689 | 0.669027 | -0.001662 ± 0.006928 | pass → pass |
| three_point_attempt_rate | 0.319887 | 0.321361 | 0.001474 ± 0.003365 | pass → pass |
| free_throw_attempt_rate | 0.201431 | 0.202329 | 0.000898 ± 0.004884 | pass → pass |
| turnovers_per_100_possessions | 16.396052 | 16.381249 | -0.014803 ± 0.233107 | pass → pass |
| offensive_rebound_percentage | 0.251715 | 0.253024 | 0.001310 ± 0.004490 | pass → pass |
| assist_percentage | 0.493157 | 0.493378 | 0.000222 ± 0.006753 | pass → pass |
| home_win_rate | 0.566239 | 0.525641 | -0.040598 ± 0.050106 | fail → fail |
| overtime_rate | 0.029915 | 0.042735 | 0.012821 ± 0.023678 | fail → pass |
| close_game_rate | 0.307692 | 0.267094 | -0.040598 ± 0.059470 | pass → pass |
| blowout_rate | 0.113248 | 0.149573 | 0.036325 ± 0.036311 | pass → pass |
| regulation_possessions | 66.212607 | 66.127137 | -0.085470 ± 0.201004 | diagnostic → diagnostic |
| overtime_possessions | 0.244658 | 0.377137 | 0.132479 ± 0.203424 | diagnostic → diagnostic |
| Final margin SD | 12.466782 | 13.543877 | +1.077095 [+0.227557, +1.902397] | diagnostic |

Two-arm venue diagnostics (home minus neutral; no controlled §17.4 verdict):

| Metric | Before ± half-width | After ± half-width | Difference ± half-width |
| --- | ---: | ---: | ---: |
| home_win_difference | 0.053419 ± 0.031379 | 0.010684 ± 0.031695 | -0.042735 ± 0.040905 |
| home_minus_neutral_final_margin | 1.305556 ± 0.555361 | 1.132479 ± 0.637145 | -0.173077 ± 0.834653 |

Actual rounded-roster strength distributions (diagnostic units):

| Strength measure / source | Home mean ± SD | Away mean ± SD | Gap SD | Home stronger / away stronger / equal | Gap 5th / 50th / 95th percentiles |
| --- | ---: | ---: | ---: | --- | --- |
| mean_attribute / baseline | 60.233419 ± 1.318420 | 60.233419 ± 1.318420 | 1.653340 | 396 / 72 / 0 | -3.900000 / +0.700000 / +0.900000 |
| mean_attribute / candidate | 60.233419 ± 1.318420 | 60.233419 ± 1.318420 | 1.933011 | 222 / 222 / 24 | -3.200000 / +0.000000 / +3.200000 |
| mean_raw_overall / baseline | 61.057919 ± 1.318420 | 61.057919 ± 1.318420 | 1.653340 | 396 / 72 / 0 | -3.900000 / +0.700000 / +0.900000 |
| mean_raw_overall / candidate | 61.057919 ± 1.318420 | 61.057919 ± 1.318420 | 1.933011 | 222 / 222 / 24 | -3.200000 / +0.000000 / +3.200000 |
| starter_raw_overall / baseline | 65.497235 ± 1.339073 | 65.497235 ± 1.339073 | 1.703907 | 396 / 72 / 0 | -4.200000 / +0.400000 / +1.400000 |
| starter_raw_overall / candidate | 65.497235 ± 1.339073 | 65.497235 ± 1.339073 | 1.939734 | 220 / 220 / 28 | -3.200000 / +0.000000 / +3.200000 |

Full marginal/gap quantiles, event and discordant-quartet counts,
neutral-arm metrics and intervals are retained in the phase summary JSON.


All canonical failures, including neutral-arm reports retained for audit:

- `baseline_home`: sample.meets_certification_size=0.000000000; high_school.field_goal_percentage=0.383536441; high_school.home_win_rate=0.566239316; high_school.overtime_rate=0.029914530
- `baseline_neutral`: sample.meets_certification_size=0.000000000; high_school.field_goal_percentage=0.384438352; high_school.home_win_rate=0.512820513; high_school.overtime_rate=0.023504274
- `candidate_home`: sample.meets_certification_size=0.000000000; high_school.field_goal_percentage=0.384365150; high_school.home_win_rate=0.525641026
- `candidate_neutral`: sample.meets_certification_size=0.000000000; high_school.field_goal_percentage=0.384104168; high_school.home_win_rate=0.514957265; high_school.overtime_rate=0.034188034

### college

| Home-environment metric | Before | After | Paired change ± 95% half-width | Before → after canonical verdict |
| --- | ---: | ---: | ---: | --- |
| possessions_per_game | 68.309829 | 68.331197 | 0.021368 ± 0.280078 | pass → pass |
| points_per_game | 70.952991 | 71.285256 | 0.332265 ± 0.756353 | informational → informational |
| points_per_possession | 1.038694 | 1.043231 | 0.004538 ± 0.009895 | pass → pass |
| field_goal_percentage | 0.407516 | 0.407850 | 0.000334 ± 0.003903 | fail → fail |
| three_point_percentage | 0.320082 | 0.323390 | 0.003308 ± 0.006138 | pass → pass |
| free_throw_percentage | 0.718441 | 0.722700 | 0.004259 ± 0.007440 | pass → pass |
| three_point_attempt_rate | 0.340515 | 0.339099 | -0.001417 ± 0.003530 | pass → pass |
| free_throw_attempt_rate | 0.252985 | 0.250564 | -0.002421 ± 0.005203 | pass → pass |
| turnovers_per_100_possessions | 15.771529 | 15.547703 | -0.223825 ± 0.278147 | pass → pass |
| offensive_rebound_percentage | 0.255430 | 0.255647 | 0.000217 ± 0.003569 | pass → pass |
| assist_percentage | 0.519183 | 0.519536 | 0.000354 ± 0.005841 | pass → pass |
| home_win_rate | 0.538462 | 0.527778 | -0.010684 ± 0.050259 | pass → fail |
| overtime_rate | 0.036325 | 0.040598 | 0.004274 ± 0.023024 | fail → pass |
| close_game_rate | 0.275641 | 0.301282 | 0.025641 ± 0.053661 | pass → pass |
| blowout_rate | 0.113248 | 0.136752 | 0.023504 ± 0.040335 | pass → pass |
| regulation_possessions | 67.974359 | 67.958333 | -0.016026 ± 0.171665 | diagnostic → diagnostic |
| overtime_possessions | 0.335470 | 0.372863 | 0.037393 ± 0.216770 | diagnostic → diagnostic |
| Final margin SD | 13.135038 | 13.128629 | -0.006409 [-1.021409, +1.026032] | diagnostic |

Two-arm venue diagnostics (home minus neutral; no controlled §17.4 verdict):

| Metric | Before ± half-width | After ± half-width | Difference ± half-width |
| --- | ---: | ---: | ---: |
| home_win_difference | 0.023504 ± 0.035182 | 0.025641 ± 0.035880 | 0.002137 ± 0.049587 |
| home_minus_neutral_final_margin | 0.814103 ± 0.652525 | 0.555556 ± 0.663146 | -0.258547 ± 0.956262 |

Actual rounded-roster strength distributions (diagnostic units):

| Strength measure / source | Home mean ± SD | Away mean ± SD | Gap SD | Home stronger / away stronger / equal | Gap 5th / 50th / 95th percentiles |
| --- | ---: | ---: | ---: | --- | --- |
| mean_attribute / baseline | 66.238547 ± 1.339537 | 66.238547 ± 1.339537 | 1.658667 | 396 / 72 / 0 | -3.965000 / +0.700000 / +0.900000 |
| mean_attribute / candidate | 66.238547 ± 1.339537 | 66.238547 ± 1.339537 | 1.956705 | 230 / 230 / 8 | -3.200000 / +0.000000 / +3.200000 |
| mean_raw_overall / baseline | 67.063047 ± 1.339537 | 67.063047 ± 1.339537 | 1.658667 | 396 / 72 / 0 | -3.965000 / +0.700000 / +0.900000 |
| mean_raw_overall / candidate | 67.063047 ± 1.339537 | 67.063047 ± 1.339537 | 1.956705 | 230 / 230 / 8 | -3.200000 / +0.000000 / +3.200000 |
| starter_raw_overall / baseline | 71.228859 ± 1.359314 | 71.228859 ± 1.359314 | 1.714331 | 388 / 72 / 8 | -4.200000 / +0.400000 / +1.400000 |
| starter_raw_overall / candidate | 71.228859 ± 1.359314 | 71.228859 ± 1.359314 | 1.976652 | 226 / 226 / 16 | -3.200000 / +0.000000 / +3.200000 |

Full marginal/gap quantiles, event and discordant-quartet counts,
neutral-arm metrics and intervals are retained in the phase summary JSON.


All canonical failures, including neutral-arm reports retained for audit:

- `baseline_home`: sample.meets_certification_size=0.000000000; college.field_goal_percentage=0.407515943; college.overtime_rate=0.036324786
- `baseline_neutral`: sample.meets_certification_size=0.000000000; college.field_goal_percentage=0.408701593; college.home_win_rate=0.514957265; college.overtime_rate=0.027777778
- `candidate_home`: sample.meets_certification_size=0.000000000; college.field_goal_percentage=0.407850226; college.home_win_rate=0.527777778
- `candidate_neutral`: sample.meets_certification_size=0.000000000; college.field_goal_percentage=0.406960310; college.home_win_rate=0.502136752; college.overtime_rate=0.038461538

### development

| Home-environment metric | Before | After | Paired change ± 95% half-width | Before → after canonical verdict |
| --- | ---: | ---: | ---: | --- |
| possessions_per_game | 94.762821 | 94.896368 | 0.133547 ± 0.356743 | pass → pass |
| points_per_game | 103.670940 | 104.163462 | 0.492521 ± 0.898236 | informational → informational |
| points_per_possession | 1.094004 | 1.097655 | 0.003651 ± 0.008062 | pass → pass |
| field_goal_percentage | 0.430434 | 0.431558 | 0.001124 ± 0.003012 | pass → pass |
| three_point_percentage | 0.342369 | 0.350950 | 0.008581 ± 0.005441 | pass → pass |
| free_throw_percentage | 0.760311 | 0.759591 | -0.000719 ± 0.006520 | pass → pass |
| three_point_attempt_rate | 0.350707 | 0.350198 | -0.000509 ± 0.003141 | pass → pass |
| free_throw_attempt_rate | 0.226477 | 0.226654 | 0.000178 ± 0.004505 | pass → pass |
| turnovers_per_100_possessions | 15.291213 | 15.192011 | -0.099202 ± 0.195614 | pass → pass |
| offensive_rebound_percentage | 0.258572 | 0.255770 | -0.002802 ± 0.003954 | pass → pass |
| assist_percentage | 0.535021 | 0.536541 | 0.001520 ± 0.004516 | pass → pass |
| home_win_rate | 0.540598 | 0.512821 | -0.027778 ± 0.048608 | pass → fail |
| overtime_rate | 0.036325 | 0.034188 | -0.002137 ± 0.022647 | fail → fail |
| close_game_rate | 0.222222 | 0.220085 | -0.002137 ± 0.053035 | pass → pass |
| blowout_rate | 0.170940 | 0.262821 | 0.091880 ± 0.047808 | pass → fail |
| regulation_possessions | 94.336538 | 94.489316 | 0.152778 ± 0.189134 | diagnostic → diagnostic |
| overtime_possessions | 0.426282 | 0.407051 | -0.019231 ± 0.289280 | diagnostic → diagnostic |
| Final margin SD | 14.921993 | 16.973967 | +2.051974 [+0.744195, +3.287945] | diagnostic |

Two-arm venue diagnostics (home minus neutral; no controlled §17.4 verdict):

| Metric | Before ± half-width | After ± half-width | Difference ± half-width |
| --- | ---: | ---: | ---: |
| home_win_difference | 0.023504 ± 0.037612 | 0.034188 ± 0.030854 | 0.010684 ± 0.046607 |
| home_minus_neutral_final_margin | 1.083333 ± 0.898776 | 0.923077 ± 0.693818 | -0.160256 ± 1.190311 |

Actual rounded-roster strength distributions (diagnostic units):

| Strength measure / source | Home mean ± SD | Away mean ± SD | Gap SD | Home stronger / away stronger / equal | Gap 5th / 50th / 95th percentiles |
| --- | ---: | ---: | ---: | --- | --- |
| mean_attribute / baseline | 72.233419 ± 1.318745 | 72.233419 ± 1.318745 | 1.654583 | 396 / 72 / 0 | -3.800000 / +0.700000 / +0.900000 |
| mean_attribute / candidate | 72.233419 ± 1.318745 | 72.233419 ± 1.318745 | 1.933099 | 226 / 226 / 16 | -3.200000 / +0.000000 / +3.200000 |
| mean_raw_overall / baseline | 73.057919 ± 1.318745 | 73.057919 ± 1.318745 | 1.654583 | 396 / 72 / 0 | -3.800000 / +0.700000 / +0.900000 |
| mean_raw_overall / candidate | 73.057919 ± 1.318745 | 73.057919 ± 1.318745 | 1.933099 | 226 / 226 / 16 | -3.200000 / +0.000000 / +3.200000 |
| starter_raw_overall / baseline | 76.941679 ± 1.339471 | 76.941679 ± 1.339471 | 1.710729 | 380 / 72 / 16 | -4.200000 / +0.400000 / +1.400000 |
| starter_raw_overall / candidate | 76.941679 ± 1.339471 | 76.941679 ± 1.339471 | 1.931060 | 226 / 226 / 16 | -3.200000 / +0.000000 / +3.200000 |

Full marginal/gap quantiles, event and discordant-quartet counts,
neutral-arm metrics and intervals are retained in the phase summary JSON.


All canonical failures, including neutral-arm reports retained for audit:

- `baseline_home`: sample.meets_certification_size=0.000000000; development.overtime_rate=0.036324786
- `baseline_neutral`: sample.meets_certification_size=0.000000000; development.home_win_rate=0.517094017; development.overtime_rate=0.025641026; development.close_game_rate=0.188034188; development.blowout_rate=0.183760684
- `candidate_home`: sample.meets_certification_size=0.000000000; development.home_win_rate=0.512820513; development.overtime_rate=0.034188034; development.blowout_rate=0.262820513
- `candidate_neutral`: sample.meets_certification_size=0.000000000; development.home_win_rate=0.478632479; development.overtime_rate=0.014957265; development.close_game_rate=0.205128205; development.blowout_rate=0.235042735

### overseas

| Home-environment metric | Before | After | Paired change ± 95% half-width | Before → after canonical verdict |
| --- | ---: | ---: | ---: | --- |
| possessions_per_game | 75.690171 | 75.660256 | -0.029915 ± 0.285619 | pass → pass |
| points_per_game | 83.631410 | 83.752137 | 0.120726 ± 0.694838 | informational → informational |
| points_per_possession | 1.104918 | 1.106950 | 0.002033 ± 0.007860 | pass → pass |
| field_goal_percentage | 0.437934 | 0.438304 | 0.000370 ± 0.003296 | pass → pass |
| three_point_percentage | 0.356971 | 0.357399 | 0.000427 ± 0.005193 | pass → pass |
| free_throw_percentage | 0.771579 | 0.776435 | 0.004856 ± 0.006559 | pass → pass |
| three_point_attempt_rate | 0.350137 | 0.349892 | -0.000245 ± 0.003017 | pass → pass |
| free_throw_attempt_rate | 0.228592 | 0.233473 | 0.004881 ± 0.005422 | pass → pass |
| turnovers_per_100_possessions | 14.851932 | 14.921348 | 0.069415 ± 0.225693 | pass → pass |
| offensive_rebound_percentage | 0.252188 | 0.251573 | -0.000615 ± 0.003618 | pass → pass |
| assist_percentage | 0.542582 | 0.545755 | 0.003173 ± 0.005173 | pass → pass |
| home_win_rate | 0.512821 | 0.493590 | -0.019231 ± 0.046516 | fail → fail |
| overtime_rate | 0.029915 | 0.027778 | -0.002137 ± 0.020168 | fail → fail |
| close_game_rate | 0.245726 | 0.258547 | 0.012821 ± 0.052482 | pass → pass |
| blowout_rate | 0.181624 | 0.181624 | 0.000000 ± 0.036667 | fail → fail |
| regulation_possessions | 75.362179 | 75.361111 | -0.001068 ± 0.171406 | diagnostic → diagnostic |
| overtime_possessions | 0.327991 | 0.299145 | -0.028846 ± 0.223364 | diagnostic → diagnostic |
| Final margin SD | 14.805451 | 14.808101 | +0.002650 [-0.891923, +0.932708] | diagnostic |

Two-arm venue diagnostics (home minus neutral; no controlled §17.4 verdict):

| Metric | Before ± half-width | After ± half-width | Difference ± half-width |
| --- | ---: | ---: | ---: |
| home_win_difference | 0.017094 ± 0.032431 | 0.004274 ± 0.029731 | -0.012821 ± 0.041996 |
| home_minus_neutral_final_margin | 0.705128 ± 0.623223 | 0.799145 ± 0.593462 | 0.094017 ± 0.815208 |

Actual rounded-roster strength distributions (diagnostic units):

| Strength measure / source | Home mean ± SD | Away mean ± SD | Gap SD | Home stronger / away stronger / equal | Gap 5th / 50th / 95th percentiles |
| --- | ---: | ---: | ---: | --- | --- |
| mean_attribute / baseline | 74.233419 ± 1.318745 | 74.233419 ± 1.318745 | 1.654583 | 396 / 72 / 0 | -3.800000 / +0.700000 / +0.900000 |
| mean_attribute / candidate | 74.233419 ± 1.318745 | 74.233419 ± 1.318745 | 1.933099 | 226 / 226 / 16 | -3.200000 / +0.000000 / +3.200000 |
| mean_raw_overall / baseline | 75.057919 ± 1.318745 | 75.057919 ± 1.318745 | 1.654583 | 396 / 72 / 0 | -3.800000 / +0.700000 / +0.900000 |
| mean_raw_overall / candidate | 75.057919 ± 1.318745 | 75.057919 ± 1.318745 | 1.933099 | 226 / 226 / 16 | -3.200000 / +0.000000 / +3.200000 |
| starter_raw_overall / baseline | 78.941679 ± 1.339471 | 78.941679 ± 1.339471 | 1.710729 | 380 / 72 / 16 | -4.200000 / +0.400000 / +1.400000 |
| starter_raw_overall / candidate | 78.941679 ± 1.339471 | 78.941679 ± 1.339471 | 1.931060 | 226 / 226 / 16 | -3.200000 / +0.000000 / +3.200000 |

Full marginal/gap quantiles, event and discordant-quartet counts,
neutral-arm metrics and intervals are retained in the phase summary JSON.


All canonical failures, including neutral-arm reports retained for audit:

- `baseline_home`: sample.meets_certification_size=0.000000000; overseas.home_win_rate=0.512820513; overseas.overtime_rate=0.029914530; overseas.blowout_rate=0.181623932
- `baseline_neutral`: sample.meets_certification_size=0.000000000; overseas.home_win_rate=0.495726496; overseas.overtime_rate=0.034188034; overseas.blowout_rate=0.205128205
- `candidate_home`: sample.meets_certification_size=0.000000000; overseas.home_win_rate=0.493589744; overseas.overtime_rate=0.027777778; overseas.blowout_rate=0.181623932
- `candidate_neutral`: sample.meets_certification_size=0.000000000; overseas.home_win_rate=0.489316239; overseas.overtime_rate=0.036324786

### top_domestic_pro

| Home-environment metric | Before | After | Paired change ± 95% half-width | Before → after canonical verdict |
| --- | ---: | ---: | ---: | --- |
| possessions_per_game | 99.355769 | 99.246795 | -0.108974 ± 0.359876 | pass → pass |
| points_per_game | 116.067308 | 115.420940 | -0.646368 ± 0.890800 | informational → informational |
| points_per_possession | 1.168199 | 1.162969 | -0.005230 ± 0.007247 | pass → pass |
| field_goal_percentage | 0.454220 | 0.452983 | -0.001237 ± 0.002693 | pass → pass |
| three_point_percentage | 0.375424 | 0.373011 | -0.002413 ± 0.004825 | pass → pass |
| free_throw_percentage | 0.799113 | 0.795425 | -0.003688 ± 0.006290 | pass → pass |
| three_point_attempt_rate | 0.362368 | 0.361390 | -0.000978 ± 0.002580 | pass → pass |
| free_throw_attempt_rate | 0.226259 | 0.226237 | -0.000021 ± 0.004648 | pass → pass |
| turnovers_per_100_possessions | 13.921954 | 14.095484 | 0.173530 ± 0.183879 | pass → pass |
| offensive_rebound_percentage | 0.250105 | 0.251294 | 0.001189 ± 0.003308 | pass → pass |
| assist_percentage | 0.573858 | 0.572376 | -0.001482 ± 0.004580 | pass → pass |
| home_win_rate | 0.591880 | 0.579060 | -0.012821 ± 0.046016 | fail → fail |
| overtime_rate | 0.032051 | 0.021368 | -0.010684 ± 0.021769 | fail → fail |
| close_game_rate | 0.207265 | 0.213675 | 0.006410 ± 0.053687 | fail → fail |
| blowout_rate | 0.275641 | 0.252137 | -0.023504 ± 0.049044 | fail → fail |
| regulation_possessions | 98.943376 | 99.005342 | 0.061966 ± 0.227877 | diagnostic → diagnostic |
| overtime_possessions | 0.412393 | 0.241453 | -0.170940 ± 0.276267 | diagnostic → diagnostic |
| Final margin SD | 17.371228 | 16.414487 | -0.956741 [-2.166814, +0.241532] | diagnostic |

Two-arm venue diagnostics (home minus neutral; no controlled §17.4 verdict):

| Metric | Before ± half-width | After ± half-width | Difference ± half-width |
| --- | ---: | ---: | ---: |
| home_win_difference | 0.027778 ± 0.033531 | 0.047009 ± 0.036148 | 0.019231 ± 0.050175 |
| home_minus_neutral_final_margin | 1.100427 ± 0.729263 | 1.940171 ± 0.867459 | 0.839744 ± 1.135749 |

Actual rounded-roster strength distributions (diagnostic units):

| Strength measure / source | Home mean ± SD | Away mean ± SD | Gap SD | Home stronger / away stronger / equal | Gap 5th / 50th / 95th percentiles |
| --- | ---: | ---: | ---: | --- | --- |
| mean_attribute / baseline | 78.233932 ± 1.317809 | 78.233932 ± 1.317809 | 1.648212 | 396 / 72 / 0 | -3.861750 / +0.700000 / +0.865000 |
| mean_attribute / candidate | 78.233932 ± 1.317809 | 78.233932 ± 1.317809 | 1.929923 | 226 / 226 / 16 | -3.161750 / +0.000000 / +3.161750 |
| mean_raw_overall / baseline | 79.058338 ± 1.317669 | 79.058338 ± 1.317669 | 1.648001 | 396 / 72 / 0 | -3.860856 / +0.700000 / +0.865000 |
| mean_raw_overall / candidate | 79.058338 ± 1.317669 | 79.058338 ± 1.317669 | 1.929696 | 226 / 226 / 16 | -3.160856 / +0.000000 / +3.160856 |
| starter_raw_overall / baseline | 82.672432 ± 1.339294 | 82.672432 ± 1.339294 | 1.709495 | 368 / 72 / 28 | -4.130000 / +0.400000 / +1.400000 |
| starter_raw_overall / candidate | 82.672432 ± 1.339294 | 82.672432 ± 1.339294 | 1.977203 | 220 / 220 / 28 | -3.321712 / +0.000000 / +3.321712 |

Full marginal/gap quantiles, event and discordant-quartet counts,
neutral-arm metrics and intervals are retained in the phase summary JSON.


All canonical failures, including neutral-arm reports retained for audit:

- `baseline_home`: sample.meets_certification_size=0.000000000; top_domestic_pro.home_win_rate=0.591880342; top_domestic_pro.overtime_rate=0.032051282; top_domestic_pro.close_game_rate=0.207264957; top_domestic_pro.blowout_rate=0.275641026
- `baseline_neutral`: sample.meets_certification_size=0.000000000; top_domestic_pro.home_win_rate=0.564102564; top_domestic_pro.overtime_rate=0.027777778; top_domestic_pro.close_game_rate=0.217948718; top_domestic_pro.blowout_rate=0.254273504
- `candidate_home`: sample.meets_certification_size=0.000000000; top_domestic_pro.home_win_rate=0.579059829; top_domestic_pro.overtime_rate=0.021367521; top_domestic_pro.close_game_rate=0.213675214; top_domestic_pro.blowout_rate=0.252136752
- `candidate_neutral`: sample.meets_certification_size=0.000000000; top_domestic_pro.overtime_rate=0.021367521; top_domestic_pro.close_game_rate=0.215811966; top_domestic_pro.blowout_rate=0.275641026

## validation_a

### high_school

| Home-environment metric | Before | After | Paired change ± 95% half-width | Before → after canonical verdict |
| --- | ---: | ---: | ---: | --- |
| possessions_per_game | 66.607906 | 66.617521 | 0.009615 ± 0.320353 | pass → pass |
| points_per_game | 63.318376 | 63.621795 | 0.303419 ± 0.602936 | informational → informational |
| points_per_possession | 0.950614 | 0.955031 | 0.004417 ± 0.008658 | pass → pass |
| field_goal_percentage | 0.382949 | 0.383200 | 0.000250 ± 0.003453 | fail → fail |
| three_point_percentage | 0.303249 | 0.307413 | 0.004164 ± 0.006024 | pass → pass |
| free_throw_percentage | 0.670950 | 0.670018 | -0.000932 ± 0.008590 | pass → pass |
| three_point_attempt_rate | 0.320907 | 0.319588 | -0.001318 ± 0.003397 | pass → pass |
| free_throw_attempt_rate | 0.203468 | 0.205987 | 0.002519 ± 0.004740 | pass → pass |
| turnovers_per_100_possessions | 16.503328 | 16.433589 | -0.069739 ± 0.260832 | pass → pass |
| offensive_rebound_percentage | 0.251405 | 0.254465 | 0.003060 ± 0.004177 | pass → pass |
| assist_percentage | 0.488195 | 0.491190 | 0.002995 ± 0.006235 | pass → pass |
| home_win_rate | 0.495726 | 0.504274 | 0.008547 ± 0.047187 | fail → fail |
| overtime_rate | 0.029915 | 0.036325 | 0.006410 ± 0.023389 | fail → fail |
| close_game_rate | 0.290598 | 0.282051 | -0.008547 ± 0.060932 | pass → pass |
| blowout_rate | 0.102564 | 0.106838 | 0.004274 ± 0.034161 | pass → pass |
| regulation_possessions | 66.347222 | 66.204060 | -0.143162 ± 0.201304 | diagnostic → diagnostic |
| overtime_possessions | 0.260684 | 0.413462 | 0.152778 ± 0.244116 | diagnostic → diagnostic |
| Final margin SD | 12.369518 | 12.582075 | +0.212557 [-0.779122, +1.213774] | diagnostic |

Two-arm venue diagnostics (home minus neutral; no controlled §17.4 verdict):

| Metric | Before ± half-width | After ± half-width | Difference ± half-width |
| --- | ---: | ---: | ---: |
| home_win_difference | 0.036325 ± 0.032723 | 0.061966 ± 0.027197 | 0.025641 ± 0.046222 |
| home_minus_neutral_final_margin | 1.299145 ± 0.537296 | 1.500000 ± 0.547853 | 0.200855 ± 0.757982 |

Actual rounded-roster strength distributions (diagnostic units):

| Strength measure / source | Home mean ± SD | Away mean ± SD | Gap SD | Home stronger / away stronger / equal | Gap 5th / 50th / 95th percentiles |
| --- | ---: | ---: | ---: | --- | --- |
| mean_attribute / baseline | 60.233419 ± 1.318420 | 60.233419 ± 1.318420 | 1.653340 | 396 / 72 / 0 | -3.900000 / +0.700000 / +0.900000 |
| mean_attribute / candidate | 60.233419 ± 1.318420 | 60.233419 ± 1.318420 | 1.729601 | 226 / 226 / 16 | -2.500000 / +0.000000 / +2.500000 |
| mean_raw_overall / baseline | 61.057919 ± 1.318420 | 61.057919 ± 1.318420 | 1.653340 | 396 / 72 / 0 | -3.900000 / +0.700000 / +0.900000 |
| mean_raw_overall / candidate | 61.057919 ± 1.318420 | 61.057919 ± 1.318420 | 1.729601 | 226 / 226 / 16 | -2.500000 / +0.000000 / +2.500000 |
| starter_raw_overall / baseline | 65.497235 ± 1.339073 | 65.497235 ± 1.339073 | 1.703907 | 396 / 72 / 0 | -4.200000 / +0.400000 / +1.400000 |
| starter_raw_overall / candidate | 65.497235 ± 1.339073 | 65.497235 ± 1.339073 | 1.779445 | 226 / 226 / 16 | -2.730000 / +0.000000 / +2.730000 |

Full marginal/gap quantiles, event and discordant-quartet counts,
neutral-arm metrics and intervals are retained in the phase summary JSON.


All canonical failures, including neutral-arm reports retained for audit:

- `baseline_home`: sample.meets_certification_size=0.000000000; high_school.field_goal_percentage=0.382949293; high_school.home_win_rate=0.495726496; high_school.overtime_rate=0.029914530
- `baseline_neutral`: sample.meets_certification_size=0.000000000; high_school.field_goal_percentage=0.385182804; high_school.home_win_rate=0.459401709; high_school.overtime_rate=0.023504274
- `candidate_home`: sample.meets_certification_size=0.000000000; high_school.field_goal_percentage=0.383199758; high_school.home_win_rate=0.504273504; high_school.overtime_rate=0.036324786
- `candidate_neutral`: sample.meets_certification_size=0.000000000; high_school.field_goal_percentage=0.384345538; high_school.home_win_rate=0.442307692; high_school.overtime_rate=0.038461538

### college

| Home-environment metric | Before | After | Paired change ± 95% half-width | Before → after canonical verdict |
| --- | ---: | ---: | ---: | --- |
| possessions_per_game | 68.138889 | 68.083333 | -0.055556 ± 0.259286 | pass → pass |
| points_per_game | 71.472222 | 71.026709 | -0.445513 ± 0.626245 | informational → informational |
| points_per_possession | 1.048920 | 1.043232 | -0.005688 ± 0.008446 | pass → pass |
| field_goal_percentage | 0.411418 | 0.410309 | -0.001109 ± 0.003541 | fail → fail |
| three_point_percentage | 0.328014 | 0.326017 | -0.001997 ± 0.005811 | pass → pass |
| free_throw_percentage | 0.716500 | 0.713700 | -0.002800 ± 0.007563 | pass → pass |
| three_point_attempt_rate | 0.337170 | 0.336897 | -0.000273 ± 0.003126 | pass → pass |
| free_throw_attempt_rate | 0.252611 | 0.247631 | -0.004980 ± 0.005504 | pass → pass |
| turnovers_per_100_possessions | 15.677820 | 15.616860 | -0.060960 ± 0.235022 | pass → pass |
| offensive_rebound_percentage | 0.257331 | 0.256596 | -0.000735 ± 0.004147 | pass → pass |
| assist_percentage | 0.523586 | 0.524212 | 0.000626 ± 0.005912 | pass → pass |
| home_win_rate | 0.544872 | 0.523504 | -0.021368 ± 0.050673 | pass → fail |
| overtime_rate | 0.025641 | 0.032051 | 0.006410 ± 0.018297 | fail → fail |
| close_game_rate | 0.290598 | 0.245726 | -0.044872 ± 0.060840 | pass → pass |
| blowout_rate | 0.113248 | 0.136752 | 0.023504 ± 0.044107 | pass → pass |
| regulation_possessions | 67.871795 | 67.759615 | -0.112179 ± 0.165629 | diagnostic → diagnostic |
| overtime_possessions | 0.267094 | 0.323718 | 0.056624 ± 0.210922 | diagnostic → diagnostic |
| Final margin SD | 12.355440 | 13.127813 | +0.772373 [-0.240922, +1.738080] | diagnostic |

Two-arm venue diagnostics (home minus neutral; no controlled §17.4 verdict):

| Metric | Before ± half-width | After ± half-width | Difference ± half-width |
| --- | ---: | ---: | ---: |
| home_win_difference | 0.055556 ± 0.034228 | 0.034188 ± 0.034636 | -0.021368 ± 0.045133 |
| home_minus_neutral_final_margin | 1.514957 ± 0.624093 | 0.980769 ± 0.608182 | -0.534188 ± 0.863642 |

Actual rounded-roster strength distributions (diagnostic units):

| Strength measure / source | Home mean ± SD | Away mean ± SD | Gap SD | Home stronger / away stronger / equal | Gap 5th / 50th / 95th percentiles |
| --- | ---: | ---: | ---: | --- | --- |
| mean_attribute / baseline | 66.238547 ± 1.339537 | 66.238547 ± 1.339537 | 1.658667 | 396 / 72 / 0 | -3.965000 / +0.700000 / +0.900000 |
| mean_attribute / candidate | 66.238547 ± 1.339537 | 66.238547 ± 1.339537 | 1.757602 | 226 / 226 / 16 | -2.600000 / +0.000000 / +2.600000 |
| mean_raw_overall / baseline | 67.063047 ± 1.339537 | 67.063047 ± 1.339537 | 1.658667 | 396 / 72 / 0 | -3.965000 / +0.700000 / +0.900000 |
| mean_raw_overall / candidate | 67.063047 ± 1.339537 | 67.063047 ± 1.339537 | 1.757602 | 226 / 226 / 16 | -2.600000 / +0.000000 / +2.600000 |
| starter_raw_overall / baseline | 71.228859 ± 1.359314 | 71.228859 ± 1.359314 | 1.714331 | 388 / 72 / 8 | -4.200000 / +0.400000 / +1.400000 |
| starter_raw_overall / candidate | 71.228859 ± 1.359314 | 71.228859 ± 1.359314 | 1.778289 | 222 / 222 / 24 | -2.800000 / +0.000000 / +2.800000 |

Full marginal/gap quantiles, event and discordant-quartet counts,
neutral-arm metrics and intervals are retained in the phase summary JSON.


All canonical failures, including neutral-arm reports retained for audit:

- `baseline_home`: sample.meets_certification_size=0.000000000; college.field_goal_percentage=0.411417815; college.overtime_rate=0.025641026
- `baseline_neutral`: sample.meets_certification_size=0.000000000; college.field_goal_percentage=0.412666922; college.home_win_rate=0.489316239; college.overtime_rate=0.029914530
- `candidate_home`: sample.meets_certification_size=0.000000000; college.field_goal_percentage=0.410308935; college.home_win_rate=0.523504274; college.overtime_rate=0.032051282
- `candidate_neutral`: sample.meets_certification_size=0.000000000; college.field_goal_percentage=0.411544941; college.home_win_rate=0.489316239; college.overtime_rate=0.034188034

### development

| Home-environment metric | Before | After | Paired change ± 95% half-width | Before → after canonical verdict |
| --- | ---: | ---: | ---: | --- |
| possessions_per_game | 94.404915 | 94.426282 | 0.021368 ± 0.354935 | pass → pass |
| points_per_game | 102.631410 | 103.412393 | 0.780983 ± 0.772929 | informational → informational |
| points_per_possession | 1.087141 | 1.095165 | 0.008025 ± 0.007483 | pass → pass |
| field_goal_percentage | 0.430892 | 0.433520 | 0.002627 ± 0.002902 | pass → pass |
| three_point_percentage | 0.348063 | 0.349998 | 0.001935 ± 0.004651 | pass → pass |
| free_throw_percentage | 0.759239 | 0.757064 | -0.002175 ± 0.006708 | pass → pass |
| three_point_attempt_rate | 0.347870 | 0.348087 | 0.000217 ± 0.002971 | pass → pass |
| free_throw_attempt_rate | 0.222569 | 0.224067 | 0.001498 ± 0.004079 | pass → pass |
| turnovers_per_100_possessions | 15.429535 | 15.411335 | -0.018200 ± 0.211606 | pass → pass |
| offensive_rebound_percentage | 0.252607 | 0.255551 | 0.002944 ± 0.003874 | pass → pass |
| assist_percentage | 0.543077 | 0.544601 | 0.001525 ± 0.004972 | pass → pass |
| home_win_rate | 0.544872 | 0.581197 | 0.036325 ± 0.049505 | pass → fail |
| overtime_rate | 0.019231 | 0.029915 | 0.010684 ± 0.019176 | fail → fail |
| close_game_rate | 0.202991 | 0.224359 | 0.021368 ± 0.053723 | fail → pass |
| blowout_rate | 0.207265 | 0.200855 | -0.006410 ± 0.044696 | fail → fail |
| regulation_possessions | 94.208333 | 94.079060 | -0.129274 ± 0.239393 | diagnostic → diagnostic |
| overtime_possessions | 0.196581 | 0.347222 | 0.150641 ± 0.246108 | diagnostic → diagnostic |
| Final margin SD | 15.185543 | 15.331706 | +0.146163 [-0.931528, +1.216027] | diagnostic |

Two-arm venue diagnostics (home minus neutral; no controlled §17.4 verdict):

| Metric | Before ± half-width | After ± half-width | Difference ± half-width |
| --- | ---: | ---: | ---: |
| home_win_difference | -0.008547 ± 0.030869 | 0.049145 ± 0.033246 | 0.057692 ± 0.044267 |
| home_minus_neutral_final_margin | 0.585470 ± 0.740340 | 0.989316 ± 0.829123 | 0.403846 ± 1.062688 |

Actual rounded-roster strength distributions (diagnostic units):

| Strength measure / source | Home mean ± SD | Away mean ± SD | Gap SD | Home stronger / away stronger / equal | Gap 5th / 50th / 95th percentiles |
| --- | ---: | ---: | ---: | --- | --- |
| mean_attribute / baseline | 72.233419 ± 1.318745 | 72.233419 ± 1.318745 | 1.654583 | 396 / 72 / 0 | -3.800000 / +0.700000 / +0.900000 |
| mean_attribute / candidate | 72.233419 ± 1.318745 | 72.233419 ± 1.318745 | 1.729799 | 226 / 226 / 16 | -2.565000 / +0.000000 / +2.565000 |
| mean_raw_overall / baseline | 73.057919 ± 1.318745 | 73.057919 ± 1.318745 | 1.654583 | 396 / 72 / 0 | -3.800000 / +0.700000 / +0.900000 |
| mean_raw_overall / candidate | 73.057919 ± 1.318745 | 73.057919 ± 1.318745 | 1.729799 | 226 / 226 / 16 | -2.565000 / +0.000000 / +2.565000 |
| starter_raw_overall / baseline | 76.941679 ± 1.339471 | 76.941679 ± 1.339471 | 1.710729 | 380 / 72 / 16 | -4.200000 / +0.400000 / +1.400000 |
| starter_raw_overall / candidate | 76.941679 ± 1.339471 | 76.941679 ± 1.339471 | 1.741692 | 224 / 224 / 20 | -2.800000 / +0.000000 / +2.800000 |

Full marginal/gap quantiles, event and discordant-quartet counts,
neutral-arm metrics and intervals are retained in the phase summary JSON.


All canonical failures, including neutral-arm reports retained for audit:

- `baseline_home`: sample.meets_certification_size=0.000000000; development.overtime_rate=0.019230769; development.close_game_rate=0.202991453; development.blowout_rate=0.207264957
- `baseline_neutral`: sample.meets_certification_size=0.000000000; development.overtime_rate=0.014957265; development.blowout_rate=0.185897436
- `candidate_home`: sample.meets_certification_size=0.000000000; development.home_win_rate=0.581196581; development.overtime_rate=0.029914530; development.blowout_rate=0.200854701
- `candidate_neutral`: sample.meets_certification_size=0.000000000; development.overtime_rate=0.021367521; development.blowout_rate=0.200854701

### overseas

| Home-environment metric | Before | After | Paired change ± 95% half-width | Before → after canonical verdict |
| --- | ---: | ---: | ---: | --- |
| possessions_per_game | 75.817308 | 75.790598 | -0.026709 ± 0.311458 | pass → pass |
| points_per_game | 83.712607 | 83.873932 | 0.161325 ± 0.656022 | informational → informational |
| points_per_possession | 1.104136 | 1.106654 | 0.002518 ± 0.007394 | pass → pass |
| field_goal_percentage | 0.436293 | 0.436682 | 0.000389 ± 0.003176 | pass → pass |
| three_point_percentage | 0.351159 | 0.348521 | -0.002638 ± 0.005420 | pass → pass |
| free_throw_percentage | 0.773551 | 0.771708 | -0.001843 ± 0.006635 | pass → pass |
| three_point_attempt_rate | 0.351226 | 0.352198 | 0.000972 ± 0.003468 | pass → pass |
| free_throw_attempt_rate | 0.230888 | 0.236325 | 0.005437 ± 0.005289 | pass → pass |
| turnovers_per_100_possessions | 14.839710 | 14.757542 | -0.082168 ± 0.250349 | pass → pass |
| offensive_rebound_percentage | 0.254517 | 0.253395 | -0.001121 ± 0.003400 | pass → pass |
| assist_percentage | 0.544802 | 0.542867 | -0.001935 ± 0.005410 | pass → pass |
| home_win_rate | 0.502137 | 0.532051 | 0.029915 ± 0.049468 | fail → pass |
| overtime_rate | 0.036325 | 0.027778 | -0.008547 ± 0.023742 | fail → fail |
| close_game_rate | 0.262821 | 0.239316 | -0.023504 ± 0.051163 | pass → pass |
| blowout_rate | 0.130342 | 0.128205 | -0.002137 ± 0.040121 | pass → pass |
| regulation_possessions | 75.431624 | 75.523504 | 0.091880 ± 0.189655 | diagnostic → diagnostic |
| overtime_possessions | 0.385684 | 0.267094 | -0.118590 ± 0.244979 | diagnostic → diagnostic |
| Final margin SD | 12.923124 | 13.539932 | +0.616808 [-0.307344, +1.542547] | diagnostic |

Two-arm venue diagnostics (home minus neutral; no controlled §17.4 verdict):

| Metric | Before ± half-width | After ± half-width | Difference ± half-width |
| --- | ---: | ---: | ---: |
| home_win_difference | 0.023504 ± 0.031466 | 0.027778 ± 0.034055 | 0.004274 ± 0.047950 |
| home_minus_neutral_final_margin | 1.192308 ± 0.676099 | 1.004274 ± 0.674097 | -0.188034 ± 0.944853 |

Actual rounded-roster strength distributions (diagnostic units):

| Strength measure / source | Home mean ± SD | Away mean ± SD | Gap SD | Home stronger / away stronger / equal | Gap 5th / 50th / 95th percentiles |
| --- | ---: | ---: | ---: | --- | --- |
| mean_attribute / baseline | 74.233419 ± 1.318745 | 74.233419 ± 1.318745 | 1.654583 | 396 / 72 / 0 | -3.800000 / +0.700000 / +0.900000 |
| mean_attribute / candidate | 74.233419 ± 1.318745 | 74.233419 ± 1.318745 | 1.729799 | 226 / 226 / 16 | -2.565000 / +0.000000 / +2.565000 |
| mean_raw_overall / baseline | 75.057919 ± 1.318745 | 75.057919 ± 1.318745 | 1.654583 | 396 / 72 / 0 | -3.800000 / +0.700000 / +0.900000 |
| mean_raw_overall / candidate | 75.057919 ± 1.318745 | 75.057919 ± 1.318745 | 1.729799 | 226 / 226 / 16 | -2.565000 / +0.000000 / +2.565000 |
| starter_raw_overall / baseline | 78.941679 ± 1.339471 | 78.941679 ± 1.339471 | 1.710729 | 380 / 72 / 16 | -4.200000 / +0.400000 / +1.400000 |
| starter_raw_overall / candidate | 78.941679 ± 1.339471 | 78.941679 ± 1.339471 | 1.741692 | 224 / 224 / 20 | -2.800000 / +0.000000 / +2.800000 |

Full marginal/gap quantiles, event and discordant-quartet counts,
neutral-arm metrics and intervals are retained in the phase summary JSON.


All canonical failures, including neutral-arm reports retained for audit:

- `baseline_home`: sample.meets_certification_size=0.000000000; overseas.home_win_rate=0.502136752; overseas.overtime_rate=0.036324786
- `baseline_neutral`: sample.meets_certification_size=0.000000000; overseas.home_win_rate=0.478632479; overseas.overtime_rate=0.023504274
- `candidate_home`: sample.meets_certification_size=0.000000000; overseas.overtime_rate=0.027777778
- `candidate_neutral`: sample.meets_certification_size=0.000000000; overseas.home_win_rate=0.504273504; overseas.overtime_rate=0.027777778; overseas.close_game_rate=0.215811966

### top_domestic_pro

| Home-environment metric | Before | After | Paired change ± 95% half-width | Before → after canonical verdict |
| --- | ---: | ---: | ---: | --- |
| possessions_per_game | 99.456197 | 99.259615 | -0.196581 ± 0.285769 | pass → pass |
| points_per_game | 115.502137 | 115.086538 | -0.415598 ± 0.852406 | informational → informational |
| points_per_possession | 1.161337 | 1.159450 | -0.001887 ± 0.007607 | pass → pass |
| field_goal_percentage | 0.452948 | 0.451280 | -0.001669 ± 0.003024 | pass → pass |
| three_point_percentage | 0.370021 | 0.369594 | -0.000427 ± 0.005032 | pass → pass |
| free_throw_percentage | 0.804648 | 0.802791 | -0.001857 ± 0.005587 | pass → pass |
| three_point_attempt_rate | 0.361520 | 0.359928 | -0.001593 ± 0.002660 | pass → fail |
| free_throw_attempt_rate | 0.218128 | 0.220170 | 0.002042 ± 0.004509 | pass → pass |
| turnovers_per_100_possessions | 13.961607 | 14.124878 | 0.163270 ± 0.221172 | pass → pass |
| offensive_rebound_percentage | 0.252906 | 0.255512 | 0.002607 ± 0.003228 | pass → pass |
| assist_percentage | 0.572673 | 0.570153 | -0.002520 ± 0.004390 | pass → pass |
| home_win_rate | 0.525641 | 0.527778 | 0.002137 ± 0.048868 | fail → fail |
| overtime_rate | 0.027778 | 0.014957 | -0.012821 ± 0.019590 | fail → fail |
| close_game_rate | 0.239316 | 0.194444 | -0.044872 ± 0.045927 | pass → fail |
| blowout_rate | 0.220085 | 0.250000 | 0.029915 ± 0.046519 | fail → fail |
| regulation_possessions | 99.170940 | 99.082265 | -0.088675 ± 0.216030 | diagnostic → diagnostic |
| overtime_possessions | 0.285256 | 0.177350 | -0.107906 ± 0.208229 | diagnostic → diagnostic |
| Final margin SD | 16.805681 | 16.986457 | +0.180777 [-0.972846, +1.354314] | diagnostic |

Two-arm venue diagnostics (home minus neutral; no controlled §17.4 verdict):

| Metric | Before ± half-width | After ± half-width | Difference ± half-width |
| --- | ---: | ---: | ---: |
| home_win_difference | 0.044872 ± 0.037908 | 0.014957 ± 0.036807 | -0.029915 ± 0.049824 |
| home_minus_neutral_final_margin | 1.367521 ± 0.844726 | 0.696581 ± 0.856565 | -0.670940 ± 1.234540 |

Actual rounded-roster strength distributions (diagnostic units):

| Strength measure / source | Home mean ± SD | Away mean ± SD | Gap SD | Home stronger / away stronger / equal | Gap 5th / 50th / 95th percentiles |
| --- | ---: | ---: | ---: | --- | --- |
| mean_attribute / baseline | 78.233932 ± 1.317809 | 78.233932 ± 1.317809 | 1.648212 | 396 / 72 / 0 | -3.861750 / +0.700000 / +0.865000 |
| mean_attribute / candidate | 78.233932 ± 1.317809 | 78.233932 ± 1.317809 | 1.727025 | 230 / 230 / 8 | -2.565000 / +0.000000 / +2.565000 |
| mean_raw_overall / baseline | 79.058338 ± 1.317669 | 79.058338 ± 1.317669 | 1.648001 | 396 / 72 / 0 | -3.860856 / +0.700000 / +0.865000 |
| mean_raw_overall / candidate | 79.058338 ± 1.317669 | 79.058338 ± 1.317669 | 1.726848 | 230 / 230 / 8 | -2.565000 / +0.000000 / +2.565000 |
| starter_raw_overall / baseline | 82.672432 ± 1.339294 | 82.672432 ± 1.339294 | 1.709495 | 368 / 72 / 28 | -4.130000 / +0.400000 / +1.400000 |
| starter_raw_overall / candidate | 82.672432 ± 1.339294 | 82.672432 ± 1.339294 | 1.793738 | 224 / 224 / 20 | -2.730000 / +0.000000 / +2.730000 |

Full marginal/gap quantiles, event and discordant-quartet counts,
neutral-arm metrics and intervals are retained in the phase summary JSON.


All canonical failures, including neutral-arm reports retained for audit:

- `baseline_home`: sample.meets_certification_size=0.000000000; top_domestic_pro.home_win_rate=0.525641026; top_domestic_pro.overtime_rate=0.027777778; top_domestic_pro.blowout_rate=0.220085470
- `baseline_neutral`: sample.meets_certification_size=0.000000000; top_domestic_pro.home_win_rate=0.480769231; top_domestic_pro.overtime_rate=0.019230769; top_domestic_pro.close_game_rate=0.215811966; top_domestic_pro.blowout_rate=0.192307692
- `candidate_home`: sample.meets_certification_size=0.000000000; top_domestic_pro.three_point_attempt_rate=0.359927522; top_domestic_pro.home_win_rate=0.527777778; top_domestic_pro.overtime_rate=0.014957265; top_domestic_pro.close_game_rate=0.194444444; top_domestic_pro.blowout_rate=0.250000000
- `candidate_neutral`: sample.meets_certification_size=0.000000000; top_domestic_pro.home_win_rate=0.512820513; top_domestic_pro.overtime_rate=0.017094017; top_domestic_pro.close_game_rate=0.179487179; top_domestic_pro.blowout_rate=0.235042735

## validation_b

### high_school

| Home-environment metric | Before | After | Paired change ± 95% half-width | Before → after canonical verdict |
| --- | ---: | ---: | ---: | --- |
| possessions_per_game | 66.460470 | 66.394231 | -0.066239 ± 0.311497 | pass → pass |
| points_per_game | 63.400641 | 63.116453 | -0.284188 ± 0.534587 | informational → informational |
| points_per_possession | 0.953960 | 0.950632 | -0.003329 ± 0.006637 | pass → pass |
| field_goal_percentage | 0.384541 | 0.383339 | -0.001202 ± 0.003200 | fail → fail |
| three_point_percentage | 0.302595 | 0.301693 | -0.000903 ± 0.005666 | pass → pass |
| free_throw_percentage | 0.669214 | 0.662980 | -0.006233 ± 0.008161 | pass → pass |
| three_point_attempt_rate | 0.318623 | 0.318147 | -0.000476 ± 0.003647 | pass → pass |
| free_throw_attempt_rate | 0.203206 | 0.203005 | -0.000202 ± 0.004310 | pass → pass |
| turnovers_per_100_possessions | 16.379186 | 16.369780 | -0.009405 ± 0.249877 | pass → pass |
| offensive_rebound_percentage | 0.251750 | 0.253016 | 0.001266 ± 0.003684 | pass → pass |
| assist_percentage | 0.489467 | 0.489365 | -0.000102 ± 0.006959 | pass → pass |
| home_win_rate | 0.517094 | 0.525641 | 0.008547 ± 0.050097 | fail → fail |
| overtime_rate | 0.034188 | 0.029915 | -0.004274 ± 0.024513 | fail → fail |
| close_game_rate | 0.290598 | 0.311966 | 0.021368 ± 0.056296 | pass → pass |
| blowout_rate | 0.119658 | 0.160256 | 0.040598 ± 0.037600 | pass → pass |
| regulation_possessions | 66.088675 | 66.148504 | 0.059829 ± 0.178784 | diagnostic → diagnostic |
| overtime_possessions | 0.371795 | 0.245726 | -0.126068 ± 0.266487 | diagnostic → diagnostic |
| Final margin SD | 13.199134 | 13.620336 | +0.421201 [-0.615173, +1.489914] | diagnostic |

Two-arm venue diagnostics (home minus neutral; no controlled §17.4 verdict):

| Metric | Before ± half-width | After ± half-width | Difference ± half-width |
| --- | ---: | ---: | ---: |
| home_win_difference | 0.023504 ± 0.034161 | 0.019231 ± 0.031562 | -0.004274 ± 0.046451 |
| home_minus_neutral_final_margin | 0.967949 ± 0.541178 | 0.311966 ± 0.583229 | -0.655983 ± 0.777987 |

Actual rounded-roster strength distributions (diagnostic units):

| Strength measure / source | Home mean ± SD | Away mean ± SD | Gap SD | Home stronger / away stronger / equal | Gap 5th / 50th / 95th percentiles |
| --- | ---: | ---: | ---: | --- | --- |
| mean_attribute / baseline | 60.233419 ± 1.318420 | 60.233419 ± 1.318420 | 1.653340 | 396 / 72 / 0 | -3.900000 / +0.700000 / +0.900000 |
| mean_attribute / candidate | 60.233419 ± 1.318420 | 60.233419 ± 1.318420 | 2.048909 | 230 / 230 / 8 | -3.565000 / +0.000000 / +3.565000 |
| mean_raw_overall / baseline | 61.057919 ± 1.318420 | 61.057919 ± 1.318420 | 1.653340 | 396 / 72 / 0 | -3.900000 / +0.700000 / +0.900000 |
| mean_raw_overall / candidate | 61.057919 ± 1.318420 | 61.057919 ± 1.318420 | 2.048909 | 230 / 230 / 8 | -3.565000 / +0.000000 / +3.565000 |
| starter_raw_overall / baseline | 65.497235 ± 1.339073 | 65.497235 ± 1.339073 | 1.703907 | 396 / 72 / 0 | -4.200000 / +0.400000 / +1.400000 |
| starter_raw_overall / candidate | 65.497235 ± 1.339073 | 65.497235 ± 1.339073 | 2.083811 | 224 / 224 / 20 | -3.600000 / +0.000000 / +3.600000 |

Full marginal/gap quantiles, event and discordant-quartet counts,
neutral-arm metrics and intervals are retained in the phase summary JSON.


All canonical failures, including neutral-arm reports retained for audit:

- `baseline_home`: sample.meets_certification_size=0.000000000; high_school.field_goal_percentage=0.384541389; high_school.home_win_rate=0.517094017; high_school.overtime_rate=0.034188034
- `baseline_neutral`: sample.meets_certification_size=0.000000000; high_school.field_goal_percentage=0.384256441; high_school.home_win_rate=0.493589744; high_school.overtime_rate=0.029914530
- `candidate_home`: sample.meets_certification_size=0.000000000; high_school.field_goal_percentage=0.383338960; high_school.home_win_rate=0.525641026; high_school.overtime_rate=0.029914530
- `candidate_neutral`: sample.meets_certification_size=0.000000000; high_school.field_goal_percentage=0.384450194; high_school.home_win_rate=0.506410256; high_school.overtime_rate=0.036324786

### college

| Home-environment metric | Before | After | Paired change ± 95% half-width | Before → after canonical verdict |
| --- | ---: | ---: | ---: | --- |
| possessions_per_game | 68.278846 | 68.168803 | -0.110043 ± 0.319828 | pass → pass |
| points_per_game | 71.263889 | 71.019231 | -0.244658 ± 0.696659 | informational → informational |
| points_per_possession | 1.043718 | 1.041814 | -0.001904 ± 0.009499 | pass → pass |
| field_goal_percentage | 0.409411 | 0.408312 | -0.001099 ± 0.003833 | fail → fail |
| three_point_percentage | 0.323881 | 0.322013 | -0.001868 ± 0.006484 | pass → pass |
| free_throw_percentage | 0.717862 | 0.717770 | -0.000092 ± 0.007626 | pass → pass |
| three_point_attempt_rate | 0.338819 | 0.339376 | 0.000557 ± 0.003508 | pass → pass |
| free_throw_attempt_rate | 0.250972 | 0.250266 | -0.000706 ± 0.006322 | pass → pass |
| turnovers_per_100_possessions | 15.501729 | 15.412344 | -0.089385 ± 0.241827 | pass → pass |
| offensive_rebound_percentage | 0.252006 | 0.251459 | -0.000547 ± 0.003992 | pass → pass |
| assist_percentage | 0.519711 | 0.520060 | 0.000349 ± 0.005995 | pass → pass |
| home_win_rate | 0.512821 | 0.549145 | 0.036325 ± 0.050914 | fail → pass |
| overtime_rate | 0.038462 | 0.027778 | -0.010684 ± 0.025510 | fail → fail |
| close_game_rate | 0.235043 | 0.294872 | 0.059829 ± 0.055049 | pass → pass |
| blowout_rate | 0.149573 | 0.145299 | -0.004274 ± 0.037612 | pass → pass |
| regulation_possessions | 67.896368 | 67.860043 | -0.036325 ± 0.162820 | diagnostic → diagnostic |
| overtime_possessions | 0.382479 | 0.308761 | -0.073718 ± 0.278984 | diagnostic → diagnostic |
| Final margin SD | 13.597530 | 13.494167 | -0.103363 [-1.032095, +0.826797] | diagnostic |

Two-arm venue diagnostics (home minus neutral; no controlled §17.4 verdict):

| Metric | Before ± half-width | After ± half-width | Difference ± half-width |
| --- | ---: | ---: | ---: |
| home_win_difference | 0.029915 ± 0.028627 | 0.066239 ± 0.031132 | 0.036325 ± 0.041324 |
| home_minus_neutral_final_margin | 1.844017 ± 0.575068 | 1.273504 ± 0.642713 | -0.570513 ± 0.899305 |

Actual rounded-roster strength distributions (diagnostic units):

| Strength measure / source | Home mean ± SD | Away mean ± SD | Gap SD | Home stronger / away stronger / equal | Gap 5th / 50th / 95th percentiles |
| --- | ---: | ---: | ---: | --- | --- |
| mean_attribute / baseline | 66.238547 ± 1.339537 | 66.238547 ± 1.339537 | 1.658667 | 396 / 72 / 0 | -3.965000 / +0.700000 / +0.900000 |
| mean_attribute / candidate | 66.238547 ± 1.339537 | 66.238547 ± 1.339537 | 2.067719 | 226 / 226 / 16 | -3.565000 / +0.000000 / +3.565000 |
| mean_raw_overall / baseline | 67.063047 ± 1.339537 | 67.063047 ± 1.339537 | 1.658667 | 396 / 72 / 0 | -3.965000 / +0.700000 / +0.900000 |
| mean_raw_overall / candidate | 67.063047 ± 1.339537 | 67.063047 ± 1.339537 | 2.067719 | 226 / 226 / 16 | -3.565000 / +0.000000 / +3.565000 |
| starter_raw_overall / baseline | 71.228859 ± 1.359314 | 71.228859 ± 1.359314 | 1.714331 | 388 / 72 / 8 | -4.200000 / +0.400000 / +1.400000 |
| starter_raw_overall / candidate | 71.228859 ± 1.359314 | 71.228859 ± 1.359314 | 2.100352 | 222 / 222 / 24 | -3.400000 / +0.000000 / +3.400000 |

Full marginal/gap quantiles, event and discordant-quartet counts,
neutral-arm metrics and intervals are retained in the phase summary JSON.


All canonical failures, including neutral-arm reports retained for audit:

- `baseline_home`: sample.meets_certification_size=0.000000000; college.field_goal_percentage=0.409411256; college.home_win_rate=0.512820513; college.overtime_rate=0.038461538
- `baseline_neutral`: sample.meets_certification_size=0.000000000; college.field_goal_percentage=0.409290856; college.home_win_rate=0.482905983; college.overtime_rate=0.034188034
- `candidate_home`: sample.meets_certification_size=0.000000000; college.field_goal_percentage=0.408312267; college.overtime_rate=0.027777778
- `candidate_neutral`: sample.meets_certification_size=0.000000000; college.field_goal_percentage=0.407140359; college.home_win_rate=0.482905983; college.overtime_rate=0.029914530

### development

| Home-environment metric | Before | After | Paired change ± 95% half-width | Before → after canonical verdict |
| --- | ---: | ---: | ---: | --- |
| possessions_per_game | 94.394231 | 94.493590 | 0.099359 ± 0.282002 | pass → pass |
| points_per_game | 103.322650 | 103.408120 | 0.085470 ± 0.733420 | informational → informational |
| points_per_possession | 1.094586 | 1.094340 | -0.000246 ± 0.007476 | pass → pass |
| field_goal_percentage | 0.433319 | 0.433586 | 0.000267 ± 0.002910 | pass → pass |
| three_point_percentage | 0.346186 | 0.347111 | 0.000926 ± 0.004855 | pass → pass |
| free_throw_percentage | 0.761350 | 0.760938 | -0.000412 ± 0.005377 | pass → pass |
| three_point_attempt_rate | 0.347774 | 0.350207 | 0.002433 ± 0.002942 | pass → pass |
| free_throw_attempt_rate | 0.221643 | 0.223570 | 0.001927 ± 0.004492 | pass → pass |
| turnovers_per_100_possessions | 15.310176 | 15.320082 | 0.009906 ± 0.201847 | pass → pass |
| offensive_rebound_percentage | 0.255678 | 0.252301 | -0.003377 ± 0.003290 | pass → pass |
| assist_percentage | 0.540874 | 0.539129 | -0.001745 ± 0.004398 | pass → pass |
| home_win_rate | 0.527778 | 0.538462 | 0.010684 ± 0.048468 | fail → pass |
| overtime_rate | 0.025641 | 0.027778 | 0.002137 ± 0.020168 | fail → fail |
| close_game_rate | 0.239316 | 0.241453 | 0.002137 ± 0.049229 | pass → pass |
| blowout_rate | 0.181624 | 0.202991 | 0.021368 ± 0.052726 | fail → fail |
| regulation_possessions | 94.111111 | 94.194444 | 0.083333 ± 0.186020 | diagnostic → diagnostic |
| overtime_possessions | 0.283120 | 0.299145 | 0.016026 ± 0.223486 | diagnostic → diagnostic |
| Final margin SD | 15.354422 | 15.702193 | +0.347771 [-1.002716, +1.684382] | diagnostic |

Two-arm venue diagnostics (home minus neutral; no controlled §17.4 verdict):

| Metric | Before ± half-width | After ± half-width | Difference ± half-width |
| --- | ---: | ---: | ---: |
| home_win_difference | 0.010684 ± 0.031132 | 0.042735 ± 0.034832 | 0.032051 ± 0.048155 |
| home_minus_neutral_final_margin | 0.944444 ± 0.637216 | 1.264957 ± 0.858885 | 0.320513 ± 1.125695 |

Actual rounded-roster strength distributions (diagnostic units):

| Strength measure / source | Home mean ± SD | Away mean ± SD | Gap SD | Home stronger / away stronger / equal | Gap 5th / 50th / 95th percentiles |
| --- | ---: | ---: | ---: | --- | --- |
| mean_attribute / baseline | 72.233419 ± 1.318745 | 72.233419 ± 1.318745 | 1.654583 | 396 / 72 / 0 | -3.800000 / +0.700000 / +0.900000 |
| mean_attribute / candidate | 72.233419 ± 1.318745 | 72.233419 ± 1.318745 | 2.049745 | 230 / 230 / 8 | -3.565000 / +0.000000 / +3.565000 |
| mean_raw_overall / baseline | 73.057919 ± 1.318745 | 73.057919 ± 1.318745 | 1.654583 | 396 / 72 / 0 | -3.800000 / +0.700000 / +0.900000 |
| mean_raw_overall / candidate | 73.057919 ± 1.318745 | 73.057919 ± 1.318745 | 2.049745 | 230 / 230 / 8 | -3.565000 / +0.000000 / +3.565000 |
| starter_raw_overall / baseline | 76.941679 ± 1.339471 | 76.941679 ± 1.339471 | 1.710729 | 380 / 72 / 16 | -4.200000 / +0.400000 / +1.400000 |
| starter_raw_overall / candidate | 76.941679 ± 1.339471 | 76.941679 ± 1.339471 | 2.075244 | 220 / 220 / 28 | -3.530000 / +0.000000 / +3.530000 |

Full marginal/gap quantiles, event and discordant-quartet counts,
neutral-arm metrics and intervals are retained in the phase summary JSON.


All canonical failures, including neutral-arm reports retained for audit:

- `baseline_home`: sample.meets_certification_size=0.000000000; development.home_win_rate=0.527777778; development.overtime_rate=0.025641026; development.blowout_rate=0.181623932
- `baseline_neutral`: sample.meets_certification_size=0.000000000; development.home_win_rate=0.517094017; development.overtime_rate=0.036324786; development.blowout_rate=0.181623932
- `candidate_home`: sample.meets_certification_size=0.000000000; development.overtime_rate=0.027777778; development.blowout_rate=0.202991453
- `candidate_neutral`: sample.meets_certification_size=0.000000000; development.home_win_rate=0.495726496; development.overtime_rate=0.034188034; development.blowout_rate=0.202991453

### overseas

| Home-environment metric | Before | After | Paired change ± 95% half-width | Before → after canonical verdict |
| --- | ---: | ---: | ---: | --- |
| possessions_per_game | 75.759615 | 75.550214 | -0.209402 ± 0.294931 | pass → pass |
| points_per_game | 83.910256 | 83.488248 | -0.422009 ± 0.753427 | informational → informational |
| points_per_possession | 1.107586 | 1.105070 | -0.002516 ± 0.008875 | pass → pass |
| field_goal_percentage | 0.436309 | 0.435783 | -0.000527 ± 0.003423 | pass → pass |
| three_point_percentage | 0.356166 | 0.353063 | -0.003103 ± 0.005490 | pass → pass |
| free_throw_percentage | 0.771687 | 0.770503 | -0.001183 ± 0.007807 | pass → pass |
| three_point_attempt_rate | 0.348323 | 0.348957 | 0.000634 ± 0.003065 | pass → pass |
| free_throw_attempt_rate | 0.237634 | 0.233510 | -0.004125 ± 0.005339 | pass → pass |
| turnovers_per_100_possessions | 15.010365 | 14.747932 | -0.262433 ± 0.250578 | pass → pass |
| offensive_rebound_percentage | 0.256858 | 0.253492 | -0.003367 ± 0.004032 | pass → pass |
| assist_percentage | 0.538586 | 0.539634 | 0.001048 ± 0.005647 | pass → pass |
| home_win_rate | 0.532051 | 0.579060 | 0.047009 ± 0.048299 | pass → fail |
| overtime_rate | 0.032051 | 0.017094 | -0.014957 ± 0.019081 | fail → fail |
| close_game_rate | 0.250000 | 0.237179 | -0.012821 ± 0.055751 | pass → pass |
| blowout_rate | 0.158120 | 0.162393 | 0.004274 ± 0.040335 | pass → pass |
| regulation_possessions | 75.394231 | 75.361111 | -0.033120 ± 0.189585 | diagnostic → diagnostic |
| overtime_possessions | 0.365385 | 0.189103 | -0.176282 ± 0.227149 | diagnostic → diagnostic |
| Final margin SD | 13.734894 | 14.256120 | +0.521226 [-0.481035, +1.512421] | diagnostic |

Two-arm venue diagnostics (home minus neutral; no controlled §17.4 verdict):

| Metric | Before ± half-width | After ± half-width | Difference ± half-width |
| --- | ---: | ---: | ---: |
| home_win_difference | 0.032051 ± 0.028859 | 0.057692 ± 0.031127 | 0.025641 ± 0.040511 |
| home_minus_neutral_final_margin | 1.311966 ± 0.651134 | 1.380342 ± 0.744306 | 0.068376 ± 0.909589 |

Actual rounded-roster strength distributions (diagnostic units):

| Strength measure / source | Home mean ± SD | Away mean ± SD | Gap SD | Home stronger / away stronger / equal | Gap 5th / 50th / 95th percentiles |
| --- | ---: | ---: | ---: | --- | --- |
| mean_attribute / baseline | 74.233419 ± 1.318745 | 74.233419 ± 1.318745 | 1.654583 | 396 / 72 / 0 | -3.800000 / +0.700000 / +0.900000 |
| mean_attribute / candidate | 74.233419 ± 1.318745 | 74.233419 ± 1.318745 | 2.049745 | 230 / 230 / 8 | -3.565000 / +0.000000 / +3.565000 |
| mean_raw_overall / baseline | 75.057919 ± 1.318745 | 75.057919 ± 1.318745 | 1.654583 | 396 / 72 / 0 | -3.800000 / +0.700000 / +0.900000 |
| mean_raw_overall / candidate | 75.057919 ± 1.318745 | 75.057919 ± 1.318745 | 2.049745 | 230 / 230 / 8 | -3.565000 / +0.000000 / +3.565000 |
| starter_raw_overall / baseline | 78.941679 ± 1.339471 | 78.941679 ± 1.339471 | 1.710729 | 380 / 72 / 16 | -4.200000 / +0.400000 / +1.400000 |
| starter_raw_overall / candidate | 78.941679 ± 1.339471 | 78.941679 ± 1.339471 | 2.075244 | 220 / 220 / 28 | -3.530000 / +0.000000 / +3.530000 |

Full marginal/gap quantiles, event and discordant-quartet counts,
neutral-arm metrics and intervals are retained in the phase summary JSON.


All canonical failures, including neutral-arm reports retained for audit:

- `baseline_home`: sample.meets_certification_size=0.000000000; overseas.overtime_rate=0.032051282
- `baseline_neutral`: sample.meets_certification_size=0.000000000; overseas.home_win_rate=0.500000000; overseas.overtime_rate=0.036324786
- `candidate_home`: sample.meets_certification_size=0.000000000; overseas.home_win_rate=0.579059829; overseas.overtime_rate=0.017094017
- `candidate_neutral`: sample.meets_certification_size=0.000000000; overseas.home_win_rate=0.521367521; overseas.overtime_rate=0.025641026

### top_domestic_pro

| Home-environment metric | Before | After | Paired change ± 95% half-width | Before → after canonical verdict |
| --- | ---: | ---: | ---: | --- |
| possessions_per_game | 99.371795 | 99.232906 | -0.138889 ± 0.315254 | pass → pass |
| points_per_game | 115.325855 | 115.379274 | 0.053419 ± 0.822055 | informational → informational |
| points_per_possession | 1.160549 | 1.162712 | 0.002163 ± 0.007292 | pass → pass |
| field_goal_percentage | 0.452263 | 0.453018 | 0.000754 ± 0.002833 | pass → pass |
| three_point_percentage | 0.369373 | 0.372643 | 0.003270 ± 0.005294 | pass → pass |
| free_throw_percentage | 0.803762 | 0.802502 | -0.001260 ± 0.005439 | pass → pass |
| three_point_attempt_rate | 0.361558 | 0.361457 | -0.000101 ± 0.002962 | pass → pass |
| free_throw_attempt_rate | 0.222294 | 0.221887 | -0.000406 ± 0.004465 | pass → pass |
| turnovers_per_100_possessions | 14.060551 | 14.086691 | 0.026139 ± 0.182954 | pass → pass |
| offensive_rebound_percentage | 0.252493 | 0.253762 | 0.001270 ± 0.003033 | pass → pass |
| assist_percentage | 0.572066 | 0.572906 | 0.000840 ± 0.004340 | pass → pass |
| home_win_rate | 0.529915 | 0.523504 | -0.006410 ± 0.047011 | fail → fail |
| overtime_rate | 0.019231 | 0.021368 | 0.002137 ± 0.017338 | fail → fail |
| close_game_rate | 0.237179 | 0.173077 | -0.064103 ± 0.042957 | pass → fail |
| blowout_rate | 0.209402 | 0.230769 | 0.021368 ± 0.043942 | fail → fail |
| regulation_possessions | 99.128205 | 99.010684 | -0.117521 ± 0.220352 | diagnostic → diagnostic |
| overtime_possessions | 0.243590 | 0.222222 | -0.021368 ± 0.206103 | diagnostic → diagnostic |
| Final margin SD | 16.047945 | 16.351894 | +0.303949 [-0.836158, +1.420634] | diagnostic |

Two-arm venue diagnostics (home minus neutral; no controlled §17.4 verdict):

| Metric | Before ± half-width | After ± half-width | Difference ± half-width |
| --- | ---: | ---: | ---: |
| home_win_difference | 0.017094 ± 0.037960 | 0.023504 ± 0.036659 | 0.006410 ± 0.052689 |
| home_minus_neutral_final_margin | 1.429487 ± 0.879574 | 1.297009 ± 0.813322 | -0.132479 ± 1.177161 |

Actual rounded-roster strength distributions (diagnostic units):

| Strength measure / source | Home mean ± SD | Away mean ± SD | Gap SD | Home stronger / away stronger / equal | Gap 5th / 50th / 95th percentiles |
| --- | ---: | ---: | ---: | --- | --- |
| mean_attribute / baseline | 78.233932 ± 1.317809 | 78.233932 ± 1.317809 | 1.648212 | 396 / 72 / 0 | -3.861750 / +0.700000 / +0.865000 |
| mean_attribute / candidate | 78.233932 ± 1.317809 | 78.233932 ± 1.317809 | 2.046604 | 228 / 228 / 12 | -3.565000 / +0.000000 / +3.565000 |
| mean_raw_overall / baseline | 79.058338 ± 1.317669 | 79.058338 ± 1.317669 | 1.648001 | 396 / 72 / 0 | -3.860856 / +0.700000 / +0.865000 |
| mean_raw_overall / candidate | 79.058338 ± 1.317669 | 79.058338 ± 1.317669 | 2.046372 | 228 / 228 / 12 | -3.565000 / +0.000000 / +3.565000 |
| starter_raw_overall / baseline | 82.672432 ± 1.339294 | 82.672432 ± 1.339294 | 1.709495 | 368 / 72 / 28 | -4.130000 / +0.400000 / +1.400000 |
| starter_raw_overall / candidate | 82.672432 ± 1.339294 | 82.672432 ± 1.339294 | 2.098559 | 228 / 228 / 12 | -3.530000 / +0.000000 / +3.530000 |

Full marginal/gap quantiles, event and discordant-quartet counts,
neutral-arm metrics and intervals are retained in the phase summary JSON.


All canonical failures, including neutral-arm reports retained for audit:

- `baseline_home`: sample.meets_certification_size=0.000000000; top_domestic_pro.home_win_rate=0.529914530; top_domestic_pro.overtime_rate=0.019230769; top_domestic_pro.blowout_rate=0.209401709
- `baseline_neutral`: sample.meets_certification_size=0.000000000; top_domestic_pro.home_win_rate=0.512820513; top_domestic_pro.overtime_rate=0.023504274; top_domestic_pro.blowout_rate=0.213675214
- `candidate_home`: sample.meets_certification_size=0.000000000; top_domestic_pro.home_win_rate=0.523504274; top_domestic_pro.overtime_rate=0.021367521; top_domestic_pro.close_game_rate=0.173076923; top_domestic_pro.blowout_rate=0.230769231
- `candidate_neutral`: sample.meets_certification_size=0.000000000; top_domestic_pro.home_win_rate=0.500000000; top_domestic_pro.overtime_rate=0.023504274; top_domestic_pro.close_game_rate=0.194444444; top_domestic_pro.blowout_rate=0.230769231

## Untouched-range directional checks

A repeated interval exclusion is an exploratory directional signal on these
two schedule slices, not an adjusted significance claim or certification.

| Competition | Metric | Validation A change interval | Validation B change interval | Interpretation |
| --- | --- | --- | --- | --- |
| high_school | possessions_per_game | [-0.310737, +0.329968] | [-0.377736, +0.245258] | no replicated interval exclusion; unresolved |
| high_school | points_per_game | [-0.299517, +0.906355] | [-0.818775, +0.250399] | no replicated interval exclusion; unresolved |
| high_school | points_per_possession | [-0.004241, +0.013076] | [-0.009965, +0.003308] | no replicated interval exclusion; unresolved |
| high_school | field_goal_percentage | [-0.003203, +0.003704] | [-0.004403, +0.001998] | no replicated interval exclusion; unresolved |
| high_school | three_point_percentage | [-0.001859, +0.010188] | [-0.006568, +0.004763] | no replicated interval exclusion; unresolved |
| high_school | free_throw_percentage | [-0.009522, +0.007658] | [-0.014394, +0.001928] | no replicated interval exclusion; unresolved |
| high_school | three_point_attempt_rate | [-0.004715, +0.002079] | [-0.004123, +0.003171] | no replicated interval exclusion; unresolved |
| high_school | free_throw_attempt_rate | [-0.002221, +0.007259] | [-0.004511, +0.004108] | no replicated interval exclusion; unresolved |
| high_school | turnovers_per_100_possessions | [-0.330571, +0.191093] | [-0.259283, +0.240472] | no replicated interval exclusion; unresolved |
| high_school | offensive_rebound_percentage | [-0.001117, +0.007237] | [-0.002418, +0.004950] | no replicated interval exclusion; unresolved |
| high_school | assist_percentage | [-0.003240, +0.009231] | [-0.007061, +0.006857] | no replicated interval exclusion; unresolved |
| high_school | home_win_rate | [-0.038640, +0.055734] | [-0.041550, +0.058644] | no replicated interval exclusion; unresolved |
| high_school | overtime_rate | [-0.016979, +0.029799] | [-0.028786, +0.020239] | no replicated interval exclusion; unresolved |
| high_school | close_game_rate | [-0.069479, +0.052385] | [-0.034928, +0.077663] | no replicated interval exclusion; unresolved |
| high_school | blowout_rate | [-0.029888, +0.038435] | [+0.002998, +0.078198] | no replicated interval exclusion; unresolved |
| high_school | regulation_possessions | [-0.344466, +0.058141] | [-0.118955, +0.238613] | no replicated interval exclusion; unresolved |
| high_school | overtime_possessions | [-0.091338, +0.396894] | [-0.392556, +0.140419] | no replicated interval exclusion; unresolved |
| high_school | final_margin_sd | [-0.779122, +1.213774] | [-0.615173, +1.489914] | no replicated interval exclusion; unresolved |
| college | possessions_per_game | [-0.314841, +0.203730] | [-0.429871, +0.209785] | no replicated interval exclusion; unresolved |
| college | points_per_game | [-1.071758, +0.180732] | [-0.941317, +0.452001] | no replicated interval exclusion; unresolved |
| college | points_per_possession | [-0.014134, +0.002758] | [-0.011404, +0.007595] | no replicated interval exclusion; unresolved |
| college | field_goal_percentage | [-0.004650, +0.002432] | [-0.004932, +0.002734] | no replicated interval exclusion; unresolved |
| college | three_point_percentage | [-0.007808, +0.003815] | [-0.008353, +0.004616] | no replicated interval exclusion; unresolved |
| college | free_throw_percentage | [-0.010363, +0.004763] | [-0.007719, +0.007534] | no replicated interval exclusion; unresolved |
| college | three_point_attempt_rate | [-0.003399, +0.002853] | [-0.002951, +0.004066] | no replicated interval exclusion; unresolved |
| college | free_throw_attempt_rate | [-0.010484, +0.000524] | [-0.007028, +0.005615] | no replicated interval exclusion; unresolved |
| college | turnovers_per_100_possessions | [-0.295982, +0.174062] | [-0.331212, +0.152441] | no replicated interval exclusion; unresolved |
| college | offensive_rebound_percentage | [-0.004883, +0.003412] | [-0.004539, +0.003445] | no replicated interval exclusion; unresolved |
| college | assist_percentage | [-0.005286, +0.006537] | [-0.005646, +0.006344] | no replicated interval exclusion; unresolved |
| college | home_win_rate | [-0.072040, +0.029305] | [-0.014589, +0.087239] | no replicated interval exclusion; unresolved |
| college | overtime_rate | [-0.011886, +0.024707] | [-0.036194, +0.014827] | no replicated interval exclusion; unresolved |
| college | close_game_rate | [-0.105711, +0.015968] | [+0.004780, +0.114878] | no replicated interval exclusion; unresolved |
| college | blowout_rate | [-0.020602, +0.067611] | [-0.041885, +0.033338] | no replicated interval exclusion; unresolved |
| college | regulation_possessions | [-0.277809, +0.053450] | [-0.199144, +0.126495] | no replicated interval exclusion; unresolved |
| college | overtime_possessions | [-0.154298, +0.267546] | [-0.352702, +0.205266] | no replicated interval exclusion; unresolved |
| college | final_margin_sd | [-0.240922, +1.738080] | [-1.032095, +0.826797] | no replicated interval exclusion; unresolved |
| development | possessions_per_game | [-0.333568, +0.376303] | [-0.182643, +0.381361] | no replicated interval exclusion; unresolved |
| development | points_per_game | [+0.008054, +1.553912] | [-0.647950, +0.818890] | no replicated interval exclusion; unresolved |
| development | points_per_possession | [+0.000542, +0.015508] | [-0.007722, +0.007229] | no replicated interval exclusion; unresolved |
| development | field_goal_percentage | [-0.000275, +0.005530] | [-0.002643, +0.003176] | no replicated interval exclusion; unresolved |
| development | three_point_percentage | [-0.002715, +0.006586] | [-0.003929, +0.005780] | no replicated interval exclusion; unresolved |
| development | free_throw_percentage | [-0.008883, +0.004533] | [-0.005789, +0.004965] | no replicated interval exclusion; unresolved |
| development | three_point_attempt_rate | [-0.002754, +0.003188] | [-0.000509, +0.005375] | no replicated interval exclusion; unresolved |
| development | free_throw_attempt_rate | [-0.002581, +0.005577] | [-0.002565, +0.006418] | no replicated interval exclusion; unresolved |
| development | turnovers_per_100_possessions | [-0.229806, +0.193406] | [-0.191941, +0.211754] | no replicated interval exclusion; unresolved |
| development | offensive_rebound_percentage | [-0.000930, +0.006818] | [-0.006666, -0.000087] | no replicated interval exclusion; unresolved |
| development | assist_percentage | [-0.003447, +0.006496] | [-0.006143, +0.002653] | no replicated interval exclusion; unresolved |
| development | home_win_rate | [-0.013180, +0.085829] | [-0.037784, +0.059151] | no replicated interval exclusion; unresolved |
| development | overtime_rate | [-0.008492, +0.029860] | [-0.018031, +0.022304] | no replicated interval exclusion; unresolved |
| development | close_game_rate | [-0.032356, +0.075091] | [-0.047092, +0.051366] | no replicated interval exclusion; unresolved |
| development | blowout_rate | [-0.051106, +0.038285] | [-0.031358, +0.074094] | no replicated interval exclusion; unresolved |
| development | regulation_possessions | [-0.368666, +0.110119] | [-0.102686, +0.269353] | no replicated interval exclusion; unresolved |
| development | overtime_possessions | [-0.095467, +0.396749] | [-0.207460, +0.239512] | no replicated interval exclusion; unresolved |
| development | final_margin_sd | [-0.931528, +1.216027] | [-1.002716, +1.684382] | no replicated interval exclusion; unresolved |
| overseas | possessions_per_game | [-0.338168, +0.284749] | [-0.504333, +0.085529] | no replicated interval exclusion; unresolved |
| overseas | points_per_game | [-0.494698, +0.817347] | [-1.175436, +0.331418] | no replicated interval exclusion; unresolved |
| overseas | points_per_possession | [-0.004876, +0.009911] | [-0.011391, +0.006359] | no replicated interval exclusion; unresolved |
| overseas | field_goal_percentage | [-0.002788, +0.003565] | [-0.003950, +0.002897] | no replicated interval exclusion; unresolved |
| overseas | three_point_percentage | [-0.008058, +0.002783] | [-0.008593, +0.002387] | no replicated interval exclusion; unresolved |
| overseas | free_throw_percentage | [-0.008477, +0.004792] | [-0.008991, +0.006624] | no replicated interval exclusion; unresolved |
| overseas | three_point_attempt_rate | [-0.002496, +0.004439] | [-0.002431, +0.003699] | no replicated interval exclusion; unresolved |
| overseas | free_throw_attempt_rate | [+0.000148, +0.010726] | [-0.009464, +0.001215] | no replicated interval exclusion; unresolved |
| overseas | turnovers_per_100_possessions | [-0.332517, +0.168181] | [-0.513011, -0.011855] | no replicated interval exclusion; unresolved |
| overseas | offensive_rebound_percentage | [-0.004521, +0.002279] | [-0.007399, +0.000665] | no replicated interval exclusion; unresolved |
| overseas | assist_percentage | [-0.007345, +0.003476] | [-0.004599, +0.006696] | no replicated interval exclusion; unresolved |
| overseas | home_win_rate | [-0.019553, +0.079383] | [-0.001290, +0.095307] | no replicated interval exclusion; unresolved |
| overseas | overtime_rate | [-0.032289, +0.015195] | [-0.034039, +0.004124] | no replicated interval exclusion; unresolved |
| overseas | close_game_rate | [-0.074667, +0.027659] | [-0.068571, +0.042930] | no replicated interval exclusion; unresolved |
| overseas | blowout_rate | [-0.042258, +0.037984] | [-0.036062, +0.044609] | no replicated interval exclusion; unresolved |
| overseas | regulation_possessions | [-0.097774, +0.281535] | [-0.222704, +0.156465] | no replicated interval exclusion; unresolved |
| overseas | overtime_possessions | [-0.363569, +0.126389] | [-0.403431, +0.050867] | no replicated interval exclusion; unresolved |
| overseas | final_margin_sd | [-0.307344, +1.542547] | [-0.481035, +1.512421] | no replicated interval exclusion; unresolved |
| top_domestic_pro | possessions_per_game | [-0.482350, +0.089187] | [-0.454143, +0.176365] | no replicated interval exclusion; unresolved |
| top_domestic_pro | points_per_game | [-1.268005, +0.436808] | [-0.768637, +0.875474] | no replicated interval exclusion; unresolved |
| top_domestic_pro | points_per_possession | [-0.009494, +0.005720] | [-0.005129, +0.009454] | no replicated interval exclusion; unresolved |
| top_domestic_pro | field_goal_percentage | [-0.004693, +0.001355] | [-0.002078, +0.003587] | no replicated interval exclusion; unresolved |
| top_domestic_pro | three_point_percentage | [-0.005459, +0.004605] | [-0.002024, +0.008564] | no replicated interval exclusion; unresolved |
| top_domestic_pro | free_throw_percentage | [-0.007444, +0.003730] | [-0.006699, +0.004179] | no replicated interval exclusion; unresolved |
| top_domestic_pro | three_point_attempt_rate | [-0.004253, +0.001067] | [-0.003063, +0.002861] | no replicated interval exclusion; unresolved |
| top_domestic_pro | free_throw_attempt_rate | [-0.002467, +0.006551] | [-0.004872, +0.004059] | no replicated interval exclusion; unresolved |
| top_domestic_pro | turnovers_per_100_possessions | [-0.057902, +0.384443] | [-0.156815, +0.209093] | no replicated interval exclusion; unresolved |
| top_domestic_pro | offensive_rebound_percentage | [-0.000622, +0.005835] | [-0.001763, +0.004302] | no replicated interval exclusion; unresolved |
| top_domestic_pro | assist_percentage | [-0.006909, +0.001870] | [-0.003500, +0.005179] | no replicated interval exclusion; unresolved |
| top_domestic_pro | home_win_rate | [-0.046732, +0.051005] | [-0.053421, +0.040600] | no replicated interval exclusion; unresolved |
| top_domestic_pro | overtime_rate | [-0.032410, +0.006769] | [-0.015201, +0.019474] | no replicated interval exclusion; unresolved |
| top_domestic_pro | close_game_rate | [-0.090799, +0.001055] | [-0.107059, -0.021146] | no replicated interval exclusion; unresolved |
| top_domestic_pro | blowout_rate | [-0.016605, +0.076434] | [-0.022574, +0.065309] | no replicated interval exclusion; unresolved |
| top_domestic_pro | regulation_possessions | [-0.304705, +0.127355] | [-0.337874, +0.102831] | no replicated interval exclusion; unresolved |
| top_domestic_pro | overtime_possessions | [-0.316135, +0.100323] | [-0.227470, +0.184735] | no replicated interval exclusion; unresolved |
| top_domestic_pro | final_margin_sd | [-0.972846, +1.354314] | [-0.836158, +1.420634] | no replicated interval exclusion; unresolved |
