"""Independent arithmetic, schedule and mutation witnesses for report tooling."""
import copy
import math
import pathlib
import sys
import unittest
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import analyze as a
	

def rows_for(label="validation_a"):
    rows = []
    cells = range(8) if label.startswith("validation") else [0]
    for build in a.PRIMARY_IDS+a.SECONDARY_IDS:
        for cell in cells if build in a.PRIMARY_IDS else [0]:
            for q in range(2):
                for phase in range(4):
                    seed = a.RANGE_START[label]+cell*1000+q*4+phase+1
                    prospect = 0 if build=="profile_ready_now" else 2 if build=="profile_high_upside" else 1
                    family = 0 if build=="family_guard" else 2 if build=="family_big" else 1
                    row = {"range":label,"build_id":build,"cell":cell,"quartet":q,"phase":phase,
                           "seed":seed,"variation":seed-1,"home_subject":phase in [0,3],"subject_opens":phase in [0,1],
                           "fixture_version":"builder-dominance-fixtures-v1","audit_version":"builder-dominance-audit-v1",
                           "context":{"cell":cell},"subject_roster":q,"opponent_roster":q+1,
                           "teammate_signature":"held","opponent_signature":"held", "errors":[],"reconciliation_errors":[],
                           "seconds_played":600,"touches":20,"on_court_offense_possessions":30,"on_court_defense_possessions":30,
                           "points":9,"field_goals_made":3,"field_goals_attempted":6,"three_pointers_made":1,"three_pointers_attempted":2,
                           "free_throws_made":2,"free_throws_attempted":3,"offensive_rebounds":1,"defensive_rebounds":2,
                           "assists":1,"steals":1,"blocks":1,"turnovers":1,"personal_fouls":1,"defended_attempts":7,
                           "defended_makes":3,"defended_three_makes":1,"created_field_goals_made":2,"advantages_created":3,
                           "team_margin":phase-1,"team_win":int(phase>=2),"ledger_points":9,"ledger_attempts":6,"ledger_touches":20,
                           "possession_records":100,"possession_starts":100,"possession_ends":100,
                           "build":{"prospect":prospect,"family":family,"ratings":[45]*20,"caps":[80]*20,
                                    "body":[74,169,76,98],"bases":[35]*20,"ap_granted":[235,195,155][prospect],
                                    "ap_spent":[235,195,155][prospect],"ap_remaining":0,"confirmed":True,
                                    "seed":90000+q,"current_overall":45,"maximum_potential":80}}
                    rows.append(row)
    return rows


class TestBuilderAnalysis(unittest.TestCase):
    def test_student_quantiles_have_independent_known_values(self):
        self.assertAlmostEqual(a.student_quantile(.975,1),12.706204736,places=7)
        self.assertAlmostEqual(a.student_quantile(.975,15),2.131449546,places=7)
        self.assertAlmostEqual(a.student_quantile(.975,30),2.042272456,places=7)

    def test_sum_ratio_uses_opportunities_not_mean_game_percentages(self):
        t = a.totals([{"points":10,"seconds_played":100},{"points":10,"seconds_played":900}])
        self.assertAlmostEqual(a.ratio(t,a.METRICS["points_per_32_minutes"]),38.4)
        t = a.totals([{"field_goals_made":1,"three_pointers_made":0,"field_goals_attempted":1},
                      {"field_goals_made":0,"three_pointers_made":0,"field_goals_attempted":9}])
        self.assertEqual(a.ratio(t,a.METRICS["effective_field_goal_percentage"]),10)

    def test_low_counts_and_zero_empirical_variance_do_not_claim_exact_ci(self):
        r = rows_for("smoke")
        left = [x for x in r if x["build_id"]=="balanced_flat"]
        result = a.paired_comparison(left,left,a.METRICS["points_per_32_minutes"])
        self.assertIsNone(result["interval"])
        self.assertEqual(result["unavailable"],"fewer than eight quartet clusters")
        full = [x for x in rows_for() if x["build_id"]=="balanced_flat"]
        result = a.paired_comparison(full,full,a.METRICS["points_per_32_minutes"])
        self.assertIsNone(result["interval"])
        self.assertEqual(result["unavailable"],"zero empirical influence variance")

    def test_matched_cluster_covariance_and_familywise_intervals(self):
        left, right = [], []
        for cluster in range(16):
            for phase in range(4):
                right.append({"cell":cluster//2,"quartet":cluster%2,"phase":phase,"points":20+cluster,"seconds_played":600})
                left.append({"cell":cluster//2,"quartet":cluster%2,"phase":phase,"points":22+cluster+cluster%2,"seconds_played":600})
        result = a.paired_comparison(left,right,a.METRICS["points_per_32_minutes"])
        self.assertAlmostEqual(result["difference"],8.0)
        self.assertAlmostEqual(result["standard_error"],1.6/math.sqrt(15))
        self.assertLess(result["simultaneous_interval"][0],result["interval"][0])
        self.assertEqual(a.FAMILYWISE_COMPARISONS,374)

    def test_complete_schedule_counts_and_equal_resource_controls(self):
        result = a.validate_rows(rows_for(),"validation_a")
        self.assertEqual(result["games"],1184)
        self.assertEqual(result["unique_seeds"],64)
        self.assertEqual(result["primary_cells"],list(range(8)))

    def test_duplicate_seeds_missing_coverage_and_venue_bias_rejected(self):
        original = rows_for()
        duplicate = copy.deepcopy(original)
        duplicate.append(copy.deepcopy(duplicate[0]))
        with self.assertRaisesRegex(ValueError,"duplicate fixture row"): a.validate_rows(duplicate,"validation_a")
        with self.assertRaisesRegex(ValueError,"incomplete context"): a.validate_rows(original[1:],"validation_a")
        corrupt = copy.deepcopy(original)
        # Corrupt every matched arm identically, so cross-arm signature checks
        # cannot mask a missing venue/opener balance check.
        for r in corrupt:
            if r["phase"]==2: r["home_subject"] = True
        with self.assertRaisesRegex(ValueError,"unbalanced venue/opener"): a.validate_rows(corrupt,"validation_a")

    def test_minutes_and_denominator_corruptions_rejected(self):
        rows = rows_for()
        rows[0]["touches"] = float("nan")
        with self.assertRaisesRegex(ValueError,"missing minute/opportunity"): a.validate_rows(rows,"validation_a")
        rows = rows_for()
        rows[0]["possession_starts"] += 1
        with self.assertRaisesRegex(ValueError,"possession denominator"): a.validate_rows(rows,"validation_a")

    def test_tendency_facts_and_teammate_control_corruptions_rejected(self):
        rows = rows_for()
        r = next(x for x in rows if x["build_id"]=="tendency_score")
        r["build"]["ratings"][0] += 1
        with self.assertRaisesRegex(ValueError,"tendency-only construction"): a.validate_rows(rows,"validation_a")
        rows = rows_for()
        next(x for x in rows if x["build_id"]=="creation")["teammate_signature"] = "changed"
        with self.assertRaisesRegex(ValueError,"controlled matchup mismatch"): a.validate_rows(rows,"validation_a")

    def test_primary_metric_direction_and_zero_denominator(self):
        self.assertEqual(a.METRICS["turnovers_per_100_touches"][3],-1)
        self.assertEqual(a.METRICS["allowed_effective_field_goal_percentage"][3],-1)
        self.assertIsNone(a.ratio({"touches":0,"turnovers":0},a.METRICS["turnovers_per_100_touches"]))

    def test_descriptive_frontier_and_profile_separation_are_not_certification(self):
        result = a.analyze_range(rows_for(),"validation_a")
        self.assertEqual(set(result["descriptive_frontier"]),set(a.PRIMARY_IDS))
        self.assertEqual(result["all_observable_simultaneous_superiority_vs_balanced"],[])
        self.assertIn("UNTESTED / INCONCLUSIVE",result["universal_guardrail_verdict"])
        profile = result["separate_profile_family_comparisons"]["profile_ready_now"]["points_per_32_minutes"]
        self.assertEqual(profile["left_games"],8)
        self.assertEqual(profile["right_games"],8)
        self.assertEqual(set(result["primary_comparisons"]),set(a.PRIMARY_IDS)-{"balanced_flat"})


if __name__ == "__main__": unittest.main(verbosity=2)
