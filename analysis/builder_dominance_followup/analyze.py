"""Recount Builder NDJSON, matched quartet intervals and finite Pareto evidence.

Standard library only. Run `python analysis/builder_dominance_followup/analyze.py
reports/builder_followup --output analysis/builder_dominance_followup/summary.json`.
The optional --ranges argument is for exploration/smoke; confirmation requires
both frozen validation ranges and refuses partial raw archives.
"""
from __future__ import annotations
import argparse
import collections
import hashlib
import json
import math
import pathlib
import statistics
from functools import lru_cache

ROOT = pathlib.Path(__file__).resolve().parents[2]
PRIMARY_IDS = ["balanced_flat", "perimeter_offense", "finishing_offense", "creation",
               "perimeter_defense", "rim_defense", "rebounding", "speed_physical",
               "strength_physical", "three_and_defense", "creator_defender",
               "exploit_three_handle", "exploit_iq_only", "exploit_low_cost",
               "body_small", "body_large", "tendency_score", "tendency_defense"]
SECONDARY_IDS = ["profile_ready_now", "profile_high_upside", "family_guard", "family_big"]
RANGE_START = {"exploration": 61000000, "validation_a": 71000000, "validation_b": 81000000, "smoke": 91000000}
FAMILYWISE_COMPARISONS = 17 * 11 * 2
# Each tuple is numerator terms, denominator, multiplier, favorable direction.
METRICS = {
    "effective_field_goal_percentage": ({"field_goals_made": 1, "three_pointers_made": .5}, "field_goals_attempted", 100, 1),
    "points_per_32_minutes": ({"points": 1}, "seconds_played", 1920, 1),
    "created_field_goals_per_100_touches": ({"created_field_goals_made": 1}, "touches", 100, 1),
    "turnovers_per_100_touches": ({"turnovers": 1}, "touches", 100, -1),
    "steals_per_100_on_court_defense_possessions": ({"steals": 1}, "on_court_defense_possessions", 100, 1),
    "blocks_per_100_on_court_defense_possessions": ({"blocks": 1}, "on_court_defense_possessions", 100, 1),
    "offensive_rebounds_per_100_on_court_offense_possessions": ({"offensive_rebounds": 1}, "on_court_offense_possessions", 100, 1),
    "defensive_rebounds_per_100_on_court_defense_possessions": ({"defensive_rebounds": 1}, "on_court_defense_possessions", 100, 1),
    "advantages_per_100_touches": ({"advantages_created": 1}, "touches", 100, 1),
    "team_margin_per_game": ({"team_margin": 1}, "games", 1, 1),
    "allowed_effective_field_goal_percentage": ({"defended_makes": 1, "defended_three_makes": .5}, "defended_attempts", 100, -1),
}
EXTRA_METRICS = {
    "minutes_per_game": ({"seconds_played": 1}, "games", 1/60, 1),
    "points_per_game": ({"points": 1}, "games", 1, 1),
    "field_goal_attempts_per_32_minutes": ({"field_goals_attempted": 1}, "seconds_played", 1920, 1),
    "free_throw_attempts_per_32_minutes": ({"free_throws_attempted": 1}, "seconds_played", 1920, 1),
    "free_throw_percentage": ({"free_throws_made": 1}, "free_throws_attempted", 100, 1),
    "assists_per_32_minutes": ({"assists": 1}, "seconds_played", 1920, 1),
    "passes_per_100_touches": ({"passes_completed": 1}, "touches", 100, 1),
    "screens_per_32_minutes": ({"screens_set": 1}, "seconds_played", 1920, 1),
    "screen_advantages_per_32_minutes": ({"screen_advantages_created": 1}, "seconds_played", 1920, 1),
    "plus_minus_per_32_minutes": ({"plus_minus": 1}, "seconds_played", 1920, 1),
    "win_percentage": ({"team_win": 1}, "games", 100, 1),
}


def beta_continued_fraction(a: float, b: float, x: float) -> float:
    qab, qap, qam = a+b, a+1, a-1
    c, d = 1.0, 1-qab*x/qap
    d = 1/max(abs(d), 1e-300) * (1 if d >= 0 else -1)
    h = d
    for m in range(1, 201):
        m2 = 2*m
        aa = m*(b-m)*x/((qam+m2)*(a+m2))
        d = 1+aa*d
        if abs(d) < 1e-300: d = 1e-300
        c = 1+aa/c
        if abs(c) < 1e-300: c = 1e-300
        d = 1/d
        h *= d*c
        aa = -(a+m)*(qab+m)*x/((a+m2)*(qap+m2))
        d = 1+aa*d
        if abs(d) < 1e-300: d = 1e-300
        c = 1+aa/c
        if abs(c) < 1e-300: c = 1e-300
        d = 1/d
        delta = d*c
        h *= delta
        if abs(delta-1) < 3e-14:
            return h
    raise ValueError("Student-t beta fraction failed to converge")


def regularized_beta(x: float, a: float, b: float) -> float:
    if x <= 0: return 0.0
    if x >= 1: return 1.0
    bt = math.exp(math.lgamma(a+b)-math.lgamma(a)-math.lgamma(b)+a*math.log(x)+b*math.log1p(-x))
    if x < (a+1)/(a+b+2):
        return bt*beta_continued_fraction(a, b, x)/a
    return 1-bt*beta_continued_fraction(b, a, 1-x)/b


def student_cdf(t: float, df: int) -> float:
    tail = .5*regularized_beta(df/(df+t*t), df/2, .5)
    return 1-tail if t >= 0 else tail


@lru_cache(maxsize=None)
def student_quantile(p: float, df: int) -> float:
    assert .5 < p < 1 and df > 0
    lo, hi = 0.0, 1.0
    while student_cdf(hi, df) < p: hi *= 2
    for _ in range(100):
        mid = (lo+hi)/2
        if student_cdf(mid, df) < p: lo = mid
        else: hi = mid
    return (lo+hi)/2


def totals(rows: list[dict]) -> dict:
    result = collections.defaultdict(float)
    for row in rows:
        for key, value in row.items():
            if type(value) in (int, float):
                result[key] += value
    result["games"] = len(rows)
    return dict(result)


def numerator(t: dict, terms: dict) -> float:
    return sum(t.get(key, 0)*weight for key, weight in terms.items())


def ratio(t: dict, definition: tuple) -> float | None:
    terms, denominator, multiplier, _ = definition
    d = t.get(denominator, 0)
    return multiplier*numerator(t, terms)/d if d > 0 else None


def raw_overall(values: list[int]) -> float:
    """Independent report arithmetic over archived immutable rating facts."""
    ordered = sorted(values)
    assert len(ordered) == 20
    return .65*sum(ordered)/20 + .25*sum(ordered[-8:])/8 + .10*sum(ordered[:6])/6


def summarize(rows: list[dict]) -> dict:
    t = totals(rows)
    # Retain only actual basketball counters, not sums of seeds/identity fields.
    raw_keys = ["games", "seconds_played", "points", "field_goals_made", "field_goals_attempted",
                "three_pointers_made", "three_pointers_attempted", "free_throws_made", "free_throws_attempted",
                "offensive_rebounds", "defensive_rebounds", "assists", "steals", "blocks", "turnovers",
                "personal_fouls", "plus_minus", "touches", "passes_completed", "screens_set",
                "screen_advantages_created", "off_ball_actions", "advantages_created", "created_field_goals_made",
                "on_court_offense_possessions", "on_court_defense_possessions",
                "terminal_on_court_offense_possessions", "terminal_on_court_defense_possessions",
                "defended_attempts", "defended_makes", "defended_three_makes", "defended_points",
                "offense_rebound_events_on_court", "defense_rebound_events_on_court",
                "team_points", "opponent_points", "team_possessions", "opponent_possessions", "team_margin", "team_win"]
    return {"raw": {key: t.get(key, 0) for key in raw_keys},
            "metrics": {key: ratio(t, definition) for key, definition in (METRICS | EXTRA_METRICS).items()},
            "n_quartets": len({(r["cell"], r["quartet"]) for r in rows}),
            "ovr_range": sorted({r["build"]["current_overall"] for r in rows}),
            "raw_ovr_mean": statistics.mean(raw_overall(r["build"]["ratings"]) for r in rows),
            "mean_attribute_mean": statistics.mean(statistics.mean(r["build"]["ratings"]) for r in rows),
            "potential_ovr_range": sorted({r["build"]["maximum_potential"] for r in rows}),
            "seed_intervals": [[min(r["seed"] for r in rows if r["cell"] == c),
                                max(r["seed"] for r in rows if r["cell"] == c)] for c in sorted({r["cell"] for r in rows})]}


def paired_comparison(left: list[dict], right: list[dict], definition: tuple,
                      family: int = FAMILYWISE_COMPARISONS) -> dict:
    lclusters, rclusters = collections.defaultdict(list), collections.defaultdict(list)
    for r in left: lclusters[(r["cell"], r["quartet"])].append(r)
    for r in right: rclusters[(r["cell"], r["quartet"])].append(r)
    assert lclusters.keys() == rclusters.keys(), "matched cluster support mismatch"
    terms, denominator, multiplier, direction = definition
    lt, rt = totals(left), totals(right)
    lm, rm = ratio(lt, definition), ratio(rt, definition)
    if lm is None or rm is None:
        return {"difference": None, "interval": None, "simultaneous_interval": None, "unavailable": "zero aggregate denominator"}
    keys = sorted(lclusters)
    n = len(keys)
    ldbar, rdbar = lt[denominator]/n, rt[denominator]/n
    influences = []
    event_clusters = [0, 0]
    for key in keys:
        l, r = totals(lclusters[key]), totals(rclusters[key])
        event_clusters[0] += int(numerator(l, terms) != 0)
        event_clusters[1] += int(numerator(r, terms) != 0)
        influences.append(multiplier*(numerator(l, terms)-(lm/multiplier)*l[denominator])/ldbar
                          -multiplier*(numerator(r, terms)-(rm/multiplier)*r[denominator])/rdbar)
    difference = lm-rm
    result = {"left": lm, "right": rm, "difference": difference,
              "favorable_difference": direction*difference, "n_quartets": n,
              "left_games": len(left), "right_games": len(right),
              "left_numerator": numerator(lt, terms), "right_numerator": numerator(rt, terms),
              "left_denominator": lt[denominator], "right_denominator": rt[denominator],
              "nonzero_numerator_quartets": event_clusters,
              "interval": None, "simultaneous_interval": None,
              "practical_importance": "unclassified: no locked minimum for this contrast"}
    if n < 8:
        result["unavailable"] = "fewer than eight quartet clusters"
        return result
    standard_error = statistics.stdev(influences)/math.sqrt(n)
    if standard_error <= 1e-12:
        result["unavailable"] = "zero empirical influence variance"
        return result
    result["standard_error"] = standard_error
    result["sparse_event_warning"] = min(event_clusters) < 8
    for field, p in [("interval", .975), ("simultaneous_interval", 1-.05/(2*family))]:
        width = student_quantile(p, n-1)*standard_error
        result[field] = [difference-width, difference+width]
    return result


def validate_rows(rows: list[dict], label: str, quartets: int = 2) -> dict:
    if label not in RANGE_START: raise ValueError("unknown predeclared range")
    groups = collections.defaultdict(list)
    for r in rows:
        if r["range"] != label or r["errors"] or r["reconciliation_errors"]:
            raise ValueError("raw row error/range discrepancy")
        if r["fixture_version"] != "builder-dominance-fixtures-v1" or r["audit_version"] != "builder-dominance-audit-v1":
            raise ValueError("fixture/instrument version mismatch")
        for k in ["seconds_played", "touches", "on_court_offense_possessions", "on_court_defense_possessions"]:
            if type(r[k]) not in (int, float) or not math.isfinite(r[k]) or r[k] <= 0:
                raise ValueError("missing minute/opportunity coverage: " + k)
        for k in ["points", "field_goals_made", "field_goals_attempted", "three_pointers_made", "three_pointers_attempted",
                  "free_throws_made", "free_throws_attempted", "offensive_rebounds", "defensive_rebounds", "assists",
                  "steals", "blocks", "turnovers", "personal_fouls", "defended_attempts", "defended_makes", "defended_three_makes"]:
            if type(r[k]) not in (int, float) or not math.isfinite(r[k]) or r[k] < 0 or r[k] != int(r[k]):
                raise ValueError("invalid finite nonnegative count: " + k)
        if r["points"] != 2*r["field_goals_made"]+r["three_pointers_made"]+r["free_throws_made"]:
            raise ValueError("point identity discrepancy")
        if r["created_field_goals_made"] < r["assists"]:
            raise ValueError("creator/assist denominator discrepancy")
        if r["ledger_points"] != r["points"] or r["ledger_attempts"] != r["field_goals_attempted"] or r["ledger_touches"] != r["touches"]:
            raise ValueError("ledger counter mismatch")
        if r["possession_records"] != r["possession_starts"] or r["possession_records"] != r["possession_ends"]:
            raise ValueError("possession denominator discrepancy")
        groups[r["build_id"]].append(r)
    expected_ids = PRIMARY_IDS+SECONDARY_IDS
    if set(groups) != set(expected_ids): raise ValueError("missing/unexpected build coverage")
    cells = list(range(8)) if label.startswith("validation") else [0]
    for build, group in groups.items():
        expected_cells = cells if build in PRIMARY_IDS else [0]
        expected = {(cell, q, phase) for cell in expected_cells for q in range(quartets) for phase in range(4)}
        observed = [(r["cell"], r["quartet"], r["phase"]) for r in group]
        if len(observed) != len(set(observed)): raise ValueError("duplicate fixture row")
        if set(observed) != expected: raise ValueError("incomplete context/quartet coverage")
        seeds = [r["seed"] for r in group]
        if len(seeds) != len(set(seeds)): raise ValueError("duplicate simulation seed within build")
        for r in group:
            if r["seed"] != RANGE_START[label]+r["cell"]*1000+r["quartet"]*4+r["phase"]+1:
                raise ValueError("predeclared seed schedule mismatch")
            if r["home_subject"] != (r["phase"] in [0,3]) or r["subject_opens"] != (r["phase"] in [0,1]):
                raise ValueError("unbalanced venue/opener")
            b = r["build"]
            expected_ap = [235,195,155][b["prospect"]]
            if b["ap_granted"] != expected_ap or b["ap_spent"] != expected_ap or b["ap_remaining"] != 0 or not b["confirmed"]:
                raise ValueError("AP/confirmation discrepancy")
            if build in PRIMARY_IDS and (b["family"] != 1 or b["prospect"] != 1):
                raise ValueError("unequal resources/family in primary cohort")
    reference = {(r["cell"],r["quartet"],r["phase"]):r for r in groups["balanced_flat"]}
    for build in PRIMARY_IDS[1:]:
        for r in groups[build]:
            b = reference[(r["cell"],r["quartet"],r["phase"])]
            for k in ["seed", "variation", "home_subject", "subject_opens", "context", "subject_roster", "opponent_roster",
                      "teammate_signature", "opponent_signature"]:
                if r[k] != b[k]: raise ValueError("controlled matchup mismatch: " + k)
            if build.startswith("tendency_"):
                for k in ["ratings", "caps", "body", "bases", "ap_granted", "ap_spent", "seed"]:
                    if r["build"][k] != b["build"][k]: raise ValueError("tendency-only construction mismatch")
    return {"groups":groups,"games":len(rows),"unique_seeds":len({r["seed"] for r in rows}),
            "primary_cells":cells,"roster_pairs":sorted({(r["subject_roster"],r["opponent_roster"]) for r in rows})}


def analyze_range(rows: list[dict], label: str) -> dict:
    checked = validate_rows(rows, label)
    groups = checked.pop("groups")
    summaries = {build:summarize(group) for build,group in groups.items()}
    cell_summaries = {build:{str(c):summarize([r for r in group if r["cell"] == c])
                            for c in sorted({r["cell"] for r in group})} for build,group in groups.items()}
    primary = {build:{key:paired_comparison(group,groups["balanced_flat"],definition)
                       for key,definition in METRICS.items()} for build,group in groups.items() if build in PRIMARY_IDS[1:]}
    # Compare unequal budgets only in their common cell; never pool against the
    # primary arm's eight-context mean or call it equal-resource fairness.
    profile = {build:{key:paired_comparison(groups[build],[r for r in groups["balanced_flat"] if r["cell"]==0],definition)
                      for key,definition in METRICS.items()} for build in SECONDARY_IDS}
    frontier = []
    pairwise = []
    for a in PRIMARY_IDS:
        is_dominated = False
        for b in PRIMARY_IDS:
            if a == b: continue
            differences = {key:(summaries[b]["metrics"][key]-summaries[a]["metrics"][key])*definition[3]
                           if summaries[b]["metrics"][key] is not None and summaries[a]["metrics"][key] is not None else None
                           for key,definition in METRICS.items()}
            dominates = all(x is not None and x>=0 for x in differences.values()) and any(x>0 for x in differences.values() if x is not None)
            is_dominated |= dominates
            if PRIMARY_IDS.index(a) < PRIMARY_IDS.index(b):
                pairwise.append({"left":a,"right":b,"right_minus_left_favorable":differences,
                                 "right_descriptively_dominates":dominates,
                                 "left_descriptively_dominates":all(x is not None and x<=0 for x in differences.values()) and any(x<0 for x in differences.values() if x is not None)})
        if not is_dominated: frontier.append(a)
    supported = []
    for build, metrics in primary.items():
        signs = []
        for key, metric in metrics.items():
            ci = metric["simultaneous_interval"]
            direction = METRICS[key][3]
            signs.append(ci is not None and not metric.get("sparse_event_warning",False)
                         and (ci[0]>0 if direction>0 else ci[1]<0))
        if all(signs): supported.append(build)
    builds = {}
    for r in rows:
        builds[(r["build_id"],r["build"]["seed"])] = r["build"]
    hist = collections.defaultdict(collections.Counter)
    maxima, exhausted = 0, 0
    specialist_count = collections.Counter()
    for b in builds.values():
        touched = sum(v>base for v,base in zip(b["ratings"],b["bases"]))
        extreme = touched<=6  # Same disclosed operational label as Stage2.
        hist[str(b["prospect"])][str(b["current_overall"])] += 1
        specialist_count["extreme" if extreme else "ordinary"] += 1
        maxima = max(maxima,b["current_overall"])
        exhausted += int(b["ap_remaining"]==0 and b["ap_spent"]==b["ap_granted"])
    return checked | {"summaries":summaries,"cells":cell_summaries,"primary_comparisons":primary,
                      "separate_profile_family_comparisons":profile,"descriptive_frontier":frontier,
                      "descriptive_pairwise":pairwise,"all_observable_simultaneous_superiority_vs_balanced":supported,
                      "universal_guardrail_verdict":"UNTESTED / INCONCLUSIVE: finite portfolio and n2 cells cannot establish universal dominance or its absence",
                      "unique_build_draws":len(builds),"creation_exhausted":exhausted,"maximum_completed_ovr":maxima,
                      "completed_ovr_histogram_by_prospect":{k:dict(v) for k,v in hist.items()},
                      "operational_specialist_counts":dict(specialist_count)}


def sha256(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("raw_directory", type=pathlib.Path)
    parser.add_argument("--ranges", default="validation_a,validation_b")
    parser.add_argument("--output", type=pathlib.Path, default=ROOT/"analysis/builder_dominance_followup/summary.json")
    args = parser.parse_args()
    result = {"analysis_version":"builder-dominance-analysis-v1","familywise_comparisons":FAMILYWISE_COMPARISONS,
              "confidence_method":"matched quartet ratio influences, Student-t conditional schedule intervals; Bonferroni374 primary family",
              "no_certification":True,"production_behavior_changed":False,"ranges":{},"raw_sha256":{},
              "source_sha256":{p:sha256(ROOT/p) for p in ["analysis/builder_dominance_followup/protocol.json",
                "analysis/builder_dominance_followup/analyze.py","calibration/harness/builder_dominance_fixtures.gd",
                "calibration/harness/builder_dominance_audit.gd","calibration/runners/run_builder_dominance_followup.gd"]}}
    for label in args.ranges.split(","):
        path = args.raw_directory/(label+".ndjson")
        rows = [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
        result["ranges"][label] = analyze_range(rows,label)
        result["raw_sha256"][str(path)] = sha256(path)
        print(label, len(rows), "games;", len(result["ranges"][label]["descriptive_frontier"]), "builds on descriptive frontier")
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(result,indent=2,allow_nan=False)+"\n",encoding="utf-8")


if __name__ == "__main__": main()
