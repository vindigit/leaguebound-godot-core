"""Independent, offline recount of SportsDataverse ESPN schedule snapshots.

No simulation imports, tuning, downloads, or third-party Python dependencies.
Malformed season files are rejected whole; record-level exclusions are reported.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
import re
from collections import Counter, defaultdict
from pathlib import Path


def integer(value):
    number = float(value)
    if not math.isfinite(number) or not number.is_integer():
        raise ValueError("expected finite integer")
    return int(number)


def proportion(k, n):
    if not 0 <= k <= n or n == 0:
        raise ValueError("invalid binomial counts")
    p, z = k / n, 1.959963984540054
    d = 1 + z*z/n
    centre = (p + z*z/(2*n))/d
    radius = z*math.sqrt(p*(1-p)/n + z*z/(4*n*n))/d
    return {"overtime_games": k, "games": n, "rate": p,
            "wilson_95": [max(0., centre-radius), min(1., centre+radius)]}


def classify(row, league):
    """Return (exclusion, phase, OT flag, line-score coverage)."""
    if row['status_type_completed'].lower() != 'true':
        return 'not_completed', None, None, False
    if league == 'nba' and row.get('type_abbreviation') in ('ALLSTAR', 'CC'):
        return 'all_star_or_cup_final', None, None, False
    phase = integer(row['season_type'])
    if phase not in (2, 3, 5) or (league == 'mbb' and phase == 5):
        return 'other_season_type', None, None, False
    regulation = integer(row['format_regulation_periods'])
    period = integer(row['status_period'])
    if regulation != (2 if league == 'mbb' else 4):
        return 'nonstandard_regulation', None, None, False
    if period < regulation:
        return 'not_full_game_or_forfeit', None, None, False
    home, away = integer(row['home_score']), integer(row['away_score'])
    if min(home, away) < 0 or home == away:
        return 'invalid_final_score', None, None, False
    ot = period > regulation
    values = [re.findall(r"'value':\s*([0-9.]+)", row.get(side+'_linescores', ''))
              for side in ('home', 'away')]
    coverage = all(values)
    if coverage:
        hp, ap = ([integer(v) for v in values[0]], [integer(v) for v in values[1]])
        if len(hp) != period or len(ap) != period or sum(hp) != home or sum(ap) != away:
            return 'line_score_totals_or_period_count_disagree', None, None, True
        if (sum(hp[:regulation]) == sum(ap[:regulation])) != ot:
            return 'regulation_tie_disagrees_with_period', None, None, True
    return None, phase, ot, coverage


def inspect_file(path, league, season):
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    quality = {'file': str(path.name), 'sha256': digest, 'season': season, 'league': league}
    with path.open(newline='', encoding='utf-8') as stream:
        rows = list(csv.DictReader(stream, strict=True))
    quality['raw_rows'] = len(rows)
    if any(None in row or any(v is None for v in row.values()) for row in rows):
        return {**quality, 'rejected_season': 'malformed_or_truncated_csv'}, []
    seen, accepted, exclusions = {}, [], Counter()
    issues = []
    for row in rows:
        key = row['game_id']
        if not key or integer(row['season']) != season:
            return {**quality, 'rejected_season': 'missing_id_or_wrong_season'}, []
        if key in seen:
            if row != seen[key]:
                return {**quality, 'rejected_season': 'conflicting_duplicate_id'}, []
            exclusions['identical_duplicate'] += 1
            continue
        seen[key] = row
        try:
            reason, phase, ot, covered = classify(row, league)
        except (ValueError, TypeError):
            reason, phase, ot, covered = 'invalid_numeric_field', None, None, False
        if reason:
            exclusions[reason] += 1
            if 'disagree' in reason or 'invalid' in reason:
                issues.append({'game_id': key, 'reason': reason})
            continue
        accepted.append({'id': key, 'season': season, 'league': league, 'phase': phase,
                         'ot': ot, 'conference': row['conference_competition'].lower() == 'true',
                         'date': row['date'], 'line_score_verified': covered})
    quality.update(retained=len(accepted), exclusions=dict(sorted(exclusions.items())), issues=issues,
                   line_score_verified=sum(r['line_score_verified'] for r in accepted))
    if accepted:
        quality['first_game'] = min(r['date'] for r in accepted)
        quality['last_game'] = max(r['date'] for r in accepted)
    # Completeness guard for these full 82-game NBA regular seasons.
    if league == 'nba' and sum(r['phase'] == 2 for r in accepted) != 1230:
        return {**quality, 'rejected_season': 'nba_regular_season_not_1230'}, []
    return quality, accepted


def build(root):
    records, quality, sources = [], [], []
    tags = {'mbb': 'espn_mens_college_basketball_schedules', 'nba': 'espn_nba_schedules'}
    for league in ('mbb', 'nba'):
        for season in range(2022, 2027):
            path = root/f'{league}_schedule'/f'{league}_schedule_{season}.csv'
            q, games = inspect_file(path, league, season)
            quality.append(q)
            records.extend(games)
            sources.append('https://github.com/sportsdataverse/sportsdataverse-data/releases/download/'
                           + tags[league] + '/' + path.name)
    ids = [(r['league'], r['id']) for r in records]
    if len(set(ids)) != len(ids):
        raise ValueError('cross-season duplicate game IDs')
    groups = defaultdict(list)
    for r in records:
        names = [r['league']+'_type_'+str(r['phase'])]
        if r['phase'] in (2, 3):
            names.append(r['league']+'_types_2_3')
        if r['league'] == 'mbb' and r['conference']:
            names.append('mbb_conference_types_2_3')
        for name in names:
            groups[(name, r['season'])].append(r['ot'])
            groups[(name, 'pooled')].append(r['ot'])
    summaries = [{'population': name, 'season': season, **proportion(sum(flags), len(flags))}
                 for (name, season), flags in sorted(groups.items(), key=lambda kv: str(kv[0]))]
    return {'schema': 'overtime-reference-recount-v1', 'review_date': '2026-09-15',
            'source_urls': sources, 'quality': quality, 'summaries': summaries,
            'definitions': {'overtime': 'completed unique game; final period > regulation periods',
                'nba_type_2': 'regular season; exclude ALLSTAR and CC (Cup final); retain other Cup games',
                'type_3': 'provider postseason; not necessarily NCAA tournament alone',
                'type_5': 'NBA play-in, separate',
                'mbb_type_2': 'provider type 2; includes conference tournaments, not strict regular season',
                'conference': 'provider conference_competition flag; not equal-strength control',
                'intervals': '95% Wilson binomial; descriptive, not team/season-cluster robust',
                'missing_linescores': 'retain otherwise eligible game, report verification coverage',
                'rejected_seasons': 'excluded whole from pooled estimates, never silently repaired'}}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--raw-root', type=Path, required=True)
    args = parser.parse_args()
    print(json.dumps(build(args.raw_root), indent=2, sort_keys=True))
