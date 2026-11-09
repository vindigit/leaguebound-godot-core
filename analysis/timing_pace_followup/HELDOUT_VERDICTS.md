# Heldout scoring and game-shape inventory

Frozen v17 engine and fitted v2 competition vector, 400 games/profile/range.
A: variations 18000000–18000399; B: 19000000–19000399. Seeds are variation+1.
Both ranges are untouched by fitting. These are diagnostic samples, not §27.1
certification. Point estimates below retain canonical judgments; supplemental
95% game-cluster intervals for every metric are in the corresponding summaries.
Raw home-win is a population diagnostic, distinct from controlled venue effect.

| Range | Competition | Points/team | PPP | FG | OT | Close | Blowout | Raw home-win |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| A | high school | 63.3800 | 0.9573 | 0.3864 | 0.0400 | 0.3300 | 0.1250 | 0.5900 |
| A | college | 71.4363 | 1.0455 | 0.4105 | 0.0350 | 0.2275 | 0.1500 | 0.5075 |
| A | development | 102.5438 | 1.0839 | 0.4287 | 0.0325 | 0.2125 | 0.2475 | 0.5825 |
| A | overseas | 83.1412 | 1.0966 | 0.4332 | 0.0275 | 0.2600 | 0.1600 | 0.5250 |
| A | top domestic pro | 116.4387 | 1.1702 | 0.4539 | 0.0300 | 0.2100 | 0.1825 | 0.5350 |
| B | high school | 63.2150 | 0.9516 | 0.3848 | 0.0300 | 0.2850 | 0.1000 | 0.5675 |
| B | college | 70.3912 | 1.0326 | 0.4044 | 0.0050 | 0.2500 | 0.1425 | 0.5175 |
| B | development | 102.4887 | 1.0862 | 0.4289 | 0.0275 | 0.2350 | 0.1875 | 0.5725 |
| B | overseas | 83.4262 | 1.1023 | 0.4331 | 0.0325 | 0.2375 | 0.1325 | 0.5375 |
| B | top domestic pro | 115.6525 | 1.1633 | 0.4535 | 0.0150 | 0.2150 | 0.2175 | 0.5975 |

## Every failed canonical metric

All ten reports also fail `sample.meets_certification_size` (400 games versus
100000 required). Those sample failures are stated once here; every other
failed row is listed below without filtering. No failure is relabeled as a
sampling artifact or an accepted regression, and no band or tolerance changes.

| Range | Competition | Metric | Estimate | Original band |
| --- | --- | --- | ---: | --- |
| A | high school | field_goal_percentage | 0.386439 | 0.39–0.47 |
| A | high school | home_win_rate | 0.590000 | 0.53–0.56 |
| A | college | field_goal_percentage | 0.410532 | 0.42–0.49 |
| A | college | home_win_rate | 0.507500 | 0.53–0.56 |
| A | college | overtime_rate | 0.035000 | 0.04–0.08 |
| A | development | field_goal_percentage | 0.428743 | 0.43–0.5 |
| A | development | home_win_rate | 0.582500 | 0.53–0.56 |
| A | development | overtime_rate | 0.032500 | 0.04–0.08 |
| A | development | close_game_rate | 0.212500 | 0.22–0.34 |
| A | development | blowout_rate | 0.247500 | 0.08–0.18 |
| A | overseas | home_win_rate | 0.525000 | 0.53–0.56 |
| A | overseas | overtime_rate | 0.027500 | 0.04–0.08 |
| A | top domestic pro | overtime_rate | 0.030000 | 0.04–0.08 |
| A | top domestic pro | close_game_rate | 0.210000 | 0.22–0.34 |
| A | top domestic pro | blowout_rate | 0.182500 | 0.08–0.18 |
| B | high school | field_goal_percentage | 0.384819 | 0.39–0.47 |
| B | high school | home_win_rate | 0.567500 | 0.53–0.56 |
| B | high school | overtime_rate | 0.030000 | 0.04–0.08 |
| B | college | field_goal_percentage | 0.404412 | 0.42–0.49 |
| B | college | home_win_rate | 0.517500 | 0.53–0.56 |
| B | college | overtime_rate | 0.005000 | 0.04–0.08 |
| B | development | field_goal_percentage | 0.428928 | 0.43–0.5 |
| B | development | home_win_rate | 0.572500 | 0.53–0.56 |
| B | development | overtime_rate | 0.027500 | 0.04–0.08 |
| B | development | blowout_rate | 0.187500 | 0.08–0.18 |
| B | overseas | overtime_rate | 0.032500 | 0.04–0.08 |
| B | top domestic pro | three_point_attempt_rate | 0.359987 | 0.36–0.49 |
| B | top domestic pro | home_win_rate | 0.597500 | 0.53–0.56 |
| B | top domestic pro | overtime_rate | 0.015000 | 0.04–0.08 |
| B | top domestic pro | close_game_rate | 0.215000 | 0.22–0.34 |
| B | top domestic pro | blowout_rate | 0.217500 | 0.08–0.18 |
