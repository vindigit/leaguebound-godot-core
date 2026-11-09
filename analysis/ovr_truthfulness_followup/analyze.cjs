/* Node standard-library analysis; no performance score is built from OVR weights.
 * Usage: node analysis/ovr_truthfulness_followup/analyze.cjs [REPORTS_DIRECTORY]
 *   [OUTPUT_JSON] [BUILDER_RAW_NDJSON ...]
 */
'use strict';
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const ROOT = path.resolve(__dirname, '../..');
const PRIMARY = ['team_margin', 'points_per32', 'field_goal_fraction', 'assists_per100_touches',
  'turnovers_per100_touches', 'rebounds_per32', 'steals_blocks_per32'];
const COUNTS = ['seconds_played', 'points', 'field_goals_made', 'field_goals_attempted', 'three_pointers_made',
  'three_pointers_attempted', 'free_throws_made', 'free_throws_attempted', 'offensive_rebounds', 'defensive_rebounds',
  'assists', 'steals', 'blocks', 'turnovers', 'personal_fouls', 'touches', 'passes_completed', 'screens_set',
  'screen_advantages_created', 'off_ball_actions', 'advantages_created', 'created_field_goals_made',
  'on_court_offense_possessions', 'on_court_defense_possessions', 'opponent_fga_on_court', 'opponent_fgm_on_court',
  'on_court_defensive_misses', 'team_possessions', 'opponent_possessions', 'team_score', 'opponent_score', 'won'];
const ARMS = ['baseline', 'all20_plus10_toward_caps', 'scoring5_plus10_toward_caps'];
const COMPETITIONS = ['high_school', 'college', 'development', 'overseas', 'top_domestic_pro'];
const FAMILIES = ['guard', 'wing', 'big'];
const BUILDER_PRIMARY = ['balanced_flat','perimeter_offense','finishing_offense','creation','perimeter_defense','rim_defense',
  'rebounding','speed_physical','strength_physical','three_and_defense','creator_defender','exploit_three_handle',
  'exploit_iq_only','exploit_low_cost','body_small','body_large','tendency_score','tendency_defense'];
const check = (condition, message) => { if (!condition) throw new Error(message); };
const sha = file => crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const json = file => JSON.parse(fs.readFileSync(file, 'utf8'));
const ndjson = file => fs.readFileSync(file, 'utf8').trim().split(/\r?\n/).filter(Boolean).map(JSON.parse);
function oracle(values) {
  check(Array.isArray(values) && values.length === 20, 'oracle requires exactly20 values');
  const s = values.slice().sort((a, b) => a - b);
  const sum = v => v.reduce((a, b) => a + b, 0);
  const numerator = 78 * sum(s) + 75 * sum(s.slice(12)) + 40 * sum(s.slice(0, 6));
  return {raw: numerator / 2400, display: Math.floor((Math.min(99 * 2400, Math.max(25 * 2400, numerator)) + 1200) / 2400)};
}
function pointCost(to) { return to <= 59 ? 1 : to <= 69 ? 2 : to <= 79 ? 3 : to <= 89 ? 5 : to <= 94 ? 8 : 12; }
function validateRow(r) {
  for (const key of COUNTS) check(Number.isInteger(r[key]) && r[key] >= 0, 'invalid raw count: ' + key);
  check(r.points === 2 * r.field_goals_made + r.three_pointers_made + r.free_throws_made, 'points do not reconcile');
  check(r.field_goals_made <= r.field_goals_attempted && r.three_pointers_made <= r.three_pointers_attempted,
    'make/attempt denominator corruption');
  check(r.three_pointers_attempted <= r.field_goals_attempted, 'three-point attempts exceed FGA');
  check(r.touches === r.ledger_touches, 'ledger touch denominator mismatch');
  check(r.on_court_offense_possessions <= r.team_possessions && r.on_court_defense_possessions <= r.opponent_possessions,
    'on-court possession denominator exceeds authoritative team count');
  check(r.opponent_fgm_on_court <= r.opponent_fga_on_court, 'opponent attempt denominator mismatch');
  check(r.team_margin === r.team_score - r.opponent_score, 'team margin arithmetic mismatch');
  check(r.values.every(v => Number.isInteger(v) && v >= 25 && v <= 99), 'invalid current attribute domain');
  check(oracle(r.values).display === r.current_ovr, 'current OVR disagrees with independent rational oracle');
  check(Math.abs(oracle(r.values).raw - r.raw_ovr) < 1e-9, 'raw OVR disagrees with independent rational oracle');
  if (r.caps) {
    check(r.caps.length === 20 && r.caps.every(v => Number.isInteger(v) && v >= 40 && v <= 99), 'invalid exact-cap domain');
    check(oracle(r.caps).display === r.maximum_potential, 'exact-cap potential disagrees with oracle');
  }
  return true;
}
function group(rows, key) {
  const map = new Map();
  for (const row of rows) { const k = key(row); if (!map.has(k)) map.set(k, []); map.get(k).push(row); }
  return map;
}
function validateWithin(rows, clustersPerFamily = 8, options = {}) {
  rows.forEach(validateRow);
  const clusters = group(rows, r => r.range + '/' + r.cluster);
  check(rows.length === clustersPerFamily * 3 * 3 * 4, 'missing complete within-player sample');
  check(clusters.size === clustersPerFamily * 3, 'missing source-player cluster');
  const familyCounts = {};
  const ranges = new Set(rows.map(r => r.range));
  check(ranges.size === 1 && ['A', 'B'].includes(rows[0].range), 'unknown or mixed confirmation range');
  const offset = rows[0].range === 'B' ? 100000 : 0;
  for (const [id, cluster] of clusters) {
    const arms = group(cluster, r => r.arm);
    check(arms.size === 3 && ARMS.every(a => arms.has(a)), 'missing intervention arm ' + id);
    const baseline = arms.get('baseline').slice().sort((a, b) => a.slot - b.slot);
    familyCounts[baseline[0].family] = (familyCounts[baseline[0].family] || 0) + 1;
    for (const arm of ARMS) {
      const rr = arms.get(arm).slice().sort((a, b) => a.slot - b.slot);
      check(rr.length === 4 && new Set(rr.map(r => r.slot)).size === 4, 'missing counterbalance slot');
      check(new Set(rr.map(r => r.seed)).size === 4, 'duplicate seed within arm');
      check(new Set(rr.map(r => `${r.subject_home}/${r.subject_opens}`)).size === 4, 'unbalanced venue/opener');
      rr.forEach((r, i) => {
        const b = baseline[i];
        check(Number.isInteger(r.cluster) && r.cluster >= 0 && r.cluster < 3 * clustersPerFamily, 'invalid cluster domain');
        check(Number.isInteger(r.slot) && r.slot >= 0 && r.slot <= 3, 'invalid slot domain');
        check(r.family === FAMILIES[Math.floor(r.cluster / clustersPerFamily)], 'family/cluster mapping changed');
        check(r.experiment === 'within', 'experiment identity changed');
        check(typeof r.teammates_sha256 === 'string' && /^[a-f0-9]{64}$/.test(r.teammates_sha256) &&
          typeof r.opponent_sha256 === 'string' && /^[a-f0-9]{64}$/.test(r.opponent_sha256), 'missing held-fixed roster hashes');
        if (!options.allowSynthetic) {
          check(clustersPerFamily === 8, 'confirmation cannot override frozen sample');
          check(r.competition === 'high_school' && r.creation_ap === 195, 'confirmation context or creation budget changed');
          check(r.source_seed === 9800001 + offset + r.cluster, 'confirmation source-player seed shifted');
          check(r.seed === 9810001 + offset + r.cluster * 4 + r.slot, 'confirmation gameplay seed shifted');
          check(r.teammate_seed_first === r.source_seed * 100 && r.opponent_seed_first === r.source_seed * 100 + 20,
            'confirmation controlled-roster seed shifted');
          check(r.subject_home === (r.slot === 0 || r.slot === 3) && r.subject_opens === (r.slot === 0 || r.slot === 1),
            'confirmation venue/opener assignment changed');
          check(r.tendencies.length === 10 && r.tendencies.every(v => v === 3), 'confirmation neutral tendencies changed');
        }
        check(r.seed === b.seed && r.slot === b.slot && r.source_seed === b.source_seed, 'unmatched arm seed');
        check(r.body === b.body && JSON.stringify(r.caps) === JSON.stringify(b.caps), 'arm changed body or exact caps');
        check(r.teammates_sha256 === b.teammates_sha256 && r.opponent_sha256 === b.opponent_sha256,
          'arm changed controlled teammates/opponent');
        check(r.position === b.position && r.rotation_role === b.rotation_role && r.tactical_role === b.tactical_role,
          'arm changed deployment');
        check(JSON.stringify(r.tendencies) === JSON.stringify(b.tendencies), 'arm changed tendencies');
        check(JSON.stringify(r.intervention.before) === JSON.stringify(b.values), 'intervention not within same player');
        const target = b.values.map((v, k) => arm === 'baseline' || (arm === ARMS[2] && k > 4) ? v : Math.min(v + 10, b.caps[k]));
        check(JSON.stringify(target) === JSON.stringify(r.values), 'intervention changed undeclared ratings');
        let expectedCost = 0, expectedPoints = 0;
        for (let k = 0; k < 20; k++) for (let d = b.values[k] + 1; d <= r.values[k]; d++) { expectedCost += pointCost(d); expectedPoints++; }
        check(r.intervention.ap_granted === expectedCost && r.intervention.rating_points_applied === expectedPoints,
          'intervention AP denominator/cost mismatch');
      });
    }
  }
  check(Object.keys(familyCounts).length === 3 && Object.values(familyCounts).every(n => n === clustersPerFamily),
    'unbalanced family sample');
  const baselineRows = rows.filter(r => r.arm === 'baseline');
  check(new Set(baselineRows.map(r => r.seed)).size === baselineRows.length, 'duplicate source-cluster gameplay seed');
  check(new Set([...clusters.values()].map(c => c[0].source_seed)).size === clusters.size, 'duplicate source-player seed');
  return {clusters: clusters.size, families: familyCounts, games: rows.length, unique_game_seeds: baselineRows.length,
    matched_reuse_per_seed: 3, complete: true, equal_resource_experiment: false};
}
function validatePopulation(rows, kind, range) {
  check(['catalog', 'college'].includes(kind) && ['A', 'B'].includes(range), 'unknown population/range');
  rows.forEach(validateRow);
  const expectedGames = kind === 'catalog' ? 40 : 8;
  check(rows.length === expectedGames * 20, 'missing fixed population player/game coverage');
  const games = group(rows, r => r.seed), offset = range === 'B' ? 100000 : 0;
  check(games.size === expectedGames, 'duplicate or missing population gameplay seeds');
  const seenGames = new Set(), seenCareers = new Set();
  for (const rr of games.values()) {
    check(rr.length === 20 && new Set(rr.map(r => r.player_id)).size === 20, 'game lacks exactly20 distinct player rows');
    check(new Set(rr.map(r => r.ledger_sha256)).size === 1 && /^[a-f0-9]{64}$/.test(rr[0].ledger_sha256), 'missing/mixed game ledger digest');
    check(rr.filter(r => r.subject_home).length === 10 && rr.filter(r => r.subject_opens).length === 10, 'missing venue/opener player population');
    for (const r of rr) {
      check(r.experiment === kind && r.range === range, 'population/range identity changed');
      check(Number.isInteger(r.slot) && r.slot >= 0 && r.slot < 4, 'invalid population slot');
      if (kind === 'catalog') {
        const competition = COMPETITIONS.indexOf(r.competition);
        check(competition >= 0, 'unknown catalog competition');
        check(Number.isInteger(r.variation) && r.variation >= 0 && r.variation < 8, 'invalid catalog variation');
        check(r.slot === r.variation % 4 && r.cluster === competition * 2 + Math.floor(r.variation / 4), 'catalog quartet mapping changed');
        check(r.seed === 9820001 + offset + competition * 8 + r.variation, 'catalog seed shifted');
        check(/^(home|away)_p([1-9]|10)$/.test(r.player_id) && r.subject_home === r.player_id.startsWith('home_'), 'catalog player/venue mapping changed');
        check(r.subject_opens === (r.subject_home === (r.variation % 2 === 0)), 'catalog opener counterbalance changed');
        const first = Math.floor(r.variation / 4), second = 2 * first;
        const homeRoster = r.slot === 0 || r.slot === 3 ? first : second;
        const awayRoster = r.slot === 0 || r.slot === 3 ? second : first;
        check(r.roster_variation === (r.subject_home ? homeRoster : awayRoster), 'corrected v4 catalog pairing changed');
        check(r.caps === null && r.maximum_potential === null && r.age === null, 'catalog invented absent lifecycle facts');
        seenGames.add(r.competition + '/' + r.variation);
      } else {
        check(r.competition === 'college' && Number.isInteger(r.cluster) && r.cluster >= 0 && r.cluster < 2, 'invalid college population identity');
        check(r.seed === 9850001 + offset + r.cluster * 4 + r.slot, 'college gameplay seed shifted');
        const match = /^college_([01])_p([0-9])$/.exec(r.player_id);
        check(match, 'unknown generated college player identity');
        const side = Number(match[1]), index = Number(match[2]);
        check(r.career_seed === 9840001 + offset + r.cluster * 20 + side * 10 + index, 'natural college career seed shifted');
        check(r.subject_home === ((r.slot === 0 || r.slot === 3) === (side === 0)) &&
          r.subject_opens === ((r.slot === 0 || r.slot === 1) === (side === 0)), 'generated college counterbalance changed');
        check(r.class_year === index % 3 + 1 && r.snapshot_career_year === 4 + r.class_year &&
          r.growth_milestones === Math.min(r.snapshot_career_year - 1, 6), 'college snapshot/maturation coverage changed');
        check(r.age === 18 + r.class_year && r.snapshot_recorded_ovr === r.current_ovr, 'college snapshot ratings/age changed');
        check(r.creation_ap === r.creation_spent && [155, 195, 235].includes(r.creation_ap), 'college original creation AP not exhausted');
        check(typeof r.body_state_signature === 'string' && r.body_state_signature.length > 0, 'college body provenance missing');
        seenGames.add(r.cluster + '/' + r.slot); seenCareers.add(r.career_seed);
      }
    }
  }
  check(seenGames.size === expectedGames, 'missing complete population quartet coverage');
  if (kind === 'college') check(seenCareers.size === 40, 'duplicate natural college source-player seed');
  else check(new Set(rows.map(r => r.competition)).size === 5, 'missing catalog competition');
  return {games: games.size, player_game_rows: rows.length, source_quartets: kind === 'catalog' ? 10 : 2,
    natural_careers: kind === 'college' ? seenCareers.size : null, frozen_coverage_validated: true};
}
function totals(rows) {
  const t = {games: rows.length, team_margin: 0, raw_ovr_sum: 0, current_ovr_sum: 0};
  for (const key of COUNTS) t[key] = 0;
  for (const r of rows) {
    for (const key of COUNTS) t[key] += r[key] || 0;
    t.team_margin += r.team_margin || 0;
    t.raw_ovr_sum += r.raw_ovr || 0; t.current_ovr_sum += r.current_ovr || 0;
  }
  return t;
}
function combinedPlayerTotals(players) {
  const out = {player_game_exposures: 0};
  for (const key of COUNTS) out[key] = 0;
  for (const p of players) {
    out.player_game_exposures += p.raw.games;
    for (const key of COUNTS) out[key] += p.raw[key];
  }
  return out;
}
const divide = (a, b, multiplier = 1) => b > 0 ? multiplier * a / b : null;
function metrics(t) {
  return {
    team_margin: divide(t.team_margin, t.games), team_win_fraction: divide(t.won, t.games),
    mean_minutes: divide(t.seconds_played, 60 * t.games), points_per32: divide(t.points, t.seconds_played, 1920),
    points_per100_offense_possessions: divide(t.points, t.on_court_offense_possessions, 100),
    field_goal_fraction: divide(t.field_goals_made, t.field_goals_attempted),
    effective_field_goal_fraction: divide(t.field_goals_made + 0.5 * t.three_pointers_made, t.field_goals_attempted),
    three_point_fraction: divide(t.three_pointers_made, t.three_pointers_attempted),
    assists_per100_touches: divide(t.assists, t.touches, 100),
    turnovers_per100_touches: divide(t.turnovers, t.touches, 100),
    advantages_per100_offense_possessions: divide(t.advantages_created, t.on_court_offense_possessions, 100),
    rebounds_per32: divide(t.offensive_rebounds + t.defensive_rebounds, t.seconds_played, 1920),
    defensive_rebounds_per100_defense_possessions: divide(t.defensive_rebounds, t.on_court_defense_possessions, 100),
    steals_blocks_per32: divide(t.steals + t.blocks, t.seconds_played, 1920),
    opponent_field_goal_fraction_on_court: divide(t.opponent_fgm_on_court, t.opponent_fga_on_court),
    fouls_per32: divide(t.personal_fouls, t.seconds_played, 1920),
    mean_raw_ovr: divide(t.raw_ovr_sum, t.games), mean_current_ovr: divide(t.current_ovr_sum, t.games),
  };
}
function rng(seed) {
  let s = seed >>> 0;
  return () => { s = (Math.imul(s, 1664525) + 1013904223) >>> 0; return s / 4294967296; };
}
function quantile(sorted, p) {
  if (!sorted.length) return null;
  const x = (sorted.length - 1) * p, i = Math.floor(x);
  return sorted[i] + (sorted[Math.min(i + 1, sorted.length - 1)] - sorted[i]) * (x - i);
}
function pairedBootstrap(rows, target, iterations = 10000, seed = 812) {
  const source = [...group(rows, r => r.cluster).values()];
  const strata = [...group(source, c => c[0].family).values()];
  const b = rows.filter(r => r.arm === 'baseline'), a = rows.filter(r => r.arm === target);
  const m0 = metrics(totals(b)), m1 = metrics(totals(a));
  const distributions = Object.fromEntries(Object.keys(m0).map(k => [k, []]));
  const random = rng(seed);
  for (let i = 0; i < iterations; i++) {
    const sample = strata.flatMap(stratum => stratum.flatMap(() => stratum[Math.floor(random() * stratum.length)]));
    const zero = metrics(totals(sample.filter(r => r.arm === 'baseline')));
    const one = metrics(totals(sample.filter(r => r.arm === target)));
    for (const key of Object.keys(distributions)) {
      if (zero[key] !== null && one[key] !== null) distributions[key].push(one[key] - zero[key]);
    }
  }
  const out = {};
  for (const [key, distribution] of Object.entries(distributions)) {
    distribution.sort((a, b) => a - b);
    const primary = target === ARMS[1] && PRIMARY.includes(key);
    const tail = 0.05 / (2 * 14);
    out[key] = {baseline: m0[key], target: m1[key], difference: m0[key] === null || m1[key] === null ? null : m1[key] - m0[key],
      ci95: [quantile(distribution, 0.025), quantile(distribution, 0.975)],
      familywise_ci95: primary && source.length === 24 ? [quantile(distribution, tail), quantile(distribution, 1 - tail)] : null,
      primary, source_player_clusters: source.length, bootstrap_draws_with_defined_denominator: distribution.length,
      resamples: iterations, method: 'paired source-player bootstrap retaining quartet and stratifying family',
      sparse: source.length < 10, locked_performance_threshold: null};
  }
  return out;
}
function histogram(values) {
  const counts = {};
  for (const v of values) counts[v] = (counts[v] || 0) + 1;
  const ordered = values.slice().sort((a, b) => a - b);
  return {n: values.length, min: ordered[0] ?? null, median: quantile(ordered, 0.5), max: ordered.at(-1) ?? null,
    share95plus: divide(values.filter(v => v >= 95).length, values.length), count95plus: values.filter(v => v >= 95).length,
    count96plus: values.filter(v => v >= 96).length, count99: values.filter(v => v === 99).length, counts};
}
function naturalHistogram(payloads) {
  const careers = payloads.flatMap(p => p.natural_rows), fixture = payloads[0].fixture_rows;
  check(payloads.length === 2 && new Set(payloads.map(p => p.range)).size === 2, 'missing independent histogram range');
  for (const payload of payloads) {
    check(['A', 'B'].includes(payload.range), 'unknown histogram range');
    check(payload.natural_rows.length === 1000, 'missing frozen natural career histogram sample');
    const offset = payload.range === 'B' ? 100000 : 0;
    const expected = new Set(Array.from({length: 1000}, (_, i) => 9860001 + offset + i));
    for (const c of payload.natural_rows) check(expected.delete(c.career_seed), 'duplicate or shifted natural histogram seed');
    check(expected.size === 0, 'missing natural histogram seed');
    const fixtureRows = payload.fixture_rows;
    check(fixtureRows.length === 117 * 10 * 5, 'missing finite fixture histogram coverage');
    const fixtureGroups = group(fixtureRows, r => r.competition);
    check(fixtureGroups.size === 5 && COMPETITIONS.every(c => fixtureGroups.has(c)), 'missing histogram competition');
    for (const rr of fixtureGroups.values()) {
      check(rr.length === 1170, 'duplicate/missing fixture histogram rows');
      check(new Set(rr.map(r => r.roster_variation + '/' + r.player_id)).size === 1170, 'duplicate fixture histogram player');
      for (const r of rr) {
        check(Number.isInteger(r.roster_variation) && r.roster_variation >= 0 && r.roster_variation < 117 &&
          /^histogram_p([1-9]|10)$/.test(r.player_id), 'invalid histogram roster/player domain');
        check(oracle(r.values).display === r.current_ovr, 'fixture histogram OVR disagrees with oracle');
      }
    }
  }
  check(JSON.stringify(payloads[0].fixture_rows) === JSON.stringify(payloads[1].fixture_rows), 'unchanged catalog histogram differs across ranges');
  const seen = new Set();
  for (const c of careers) {
    check(!seen.has(c.career_seed), 'duplicate natural career seed'); seen.add(c.career_seed);
    check(oracle(c.starting_values).display === c.starting_current, 'natural start formula mismatch');
    check(oracle(c.exact_caps).display === c.maximum_potential, 'natural exact-cap formula mismatch');
    check(oracle(c.peak_values).display === c.peak_current, 'natural peak vector formula mismatch');
    check(oracle(c.final_values).display === c.final_current, 'natural final vector formula mismatch');
    c.college_values.forEach((v, i) => check(oracle(v).display === c.college_current[i], 'college snapshot formula mismatch'));
  }
  const out = {natural_careers: careers.length, ordinary_generated_start99: careers.filter(c => c.starting_current === 99).length,
    starting_current: histogram(careers.map(c => c.starting_current)), maximum_potential: histogram(careers.map(c => c.maximum_potential)),
    peak_current: histogram(careers.map(c => c.peak_current)), final_current: histogram(careers.map(c => c.final_current)),
    by_prospect: {}, by_family: {}, by_path: {}, by_age_and_phase: {}, fixture_by_competition: {},
    mature_world_rarity_tested: false, potential_attainment_promise_tested: false,
    applicability: 'Natural career harness populations; no recruited/draft/active-world roster selection or stable season lifecycle.'};
  for (const dimension of ['prospect', 'family', 'path']) for (const [stratum, cc] of group(careers, c => c[dimension])) {
    out['by_' + dimension][stratum] = {starting: histogram(cc.map(c => c.starting_current)),
      potential: histogram(cc.map(c => c.maximum_potential)), peak: histogram(cc.map(c => c.peak_current)),
      seed_count: cc.length};
  }
  const ageRows = careers.flatMap(c => [{age: 14, phase: 'freshman_start', value: c.starting_current},
    ...c.all_season_current.map((value, i) => ({value, age: c.all_season_ages[i],
      phase: i < 4 ? 'high_school' : i < 7 ? 'college' : 'professional_career_harness'}))]);
  for (const [k, rr] of group(ageRows, r => r.phase + '/' + r.age)) out.by_age_and_phase[k] = histogram(rr.map(r => r.value));
  for (const [competition, rr] of group(fixture, r => r.competition)) {
    out.fixture_by_competition[competition] = {current: histogram(rr.map(r => r.current_ovr)),
      potential: null, age: null, population: '1170 existing calibration fixture players, one count per roster-state/player'};
  }
  return out;
}
function correlation(pairs) {
  const pp = pairs.filter(([x, y]) => Number.isFinite(x) && Number.isFinite(y));
  if (pp.length < 3) return null;
  const mx = pp.reduce((s, p) => s + p[0], 0) / pp.length, my = pp.reduce((s, p) => s + p[1], 0) / pp.length;
  let xx = 0, yy = 0, xy = 0;
  for (const [x, y] of pp) { xx += (x - mx) ** 2; yy += (y - my) ** 2; xy += (x - mx) * (y - my); }
  return xx > 0 && yy > 0 ? xy / Math.sqrt(xx * yy) : null;
}
function playerObservations(rows) {
  rows.forEach(validateRow);
  return [...group(rows, r => r.range + '/' + r.cluster + '/' + r.competition + '/' +
    (r.experiment === 'college' ? r.player_id : r.roster_variation + '/' + /_p\d+$/.exec(r.player_id)[0])).values()]
    .map(rr => {
      const first = rr[0], t = totals(rr), m = metrics(t);
      check(rr.every(r => JSON.stringify(r.values) === JSON.stringify(first.values)), 'player ratings changed inside quartet');
      return {...first, cluster_id: first.range + '/' + first.competition + '/' + first.cluster,
        aggregate_games: rr.length, raw: t, observables: m,
        minute_stratum: m.mean_minutes < 10 ? 'under10' : m.mean_minutes < 20 ? '10to20' : '20plus',
        opportunity_stratum: t.touches / rr.length < 10 ? 'under10touches' : t.touches / rr.length < 25 ? '10to25touches' : '25plustouches'};
    });
}
function relationships(rows) {
  const players = playerObservations(rows);
  const outcomes = ['points_per32', 'field_goal_fraction', 'assists_per100_touches', 'turnovers_per100_touches',
    'rebounds_per32', 'steals_blocks_per32', 'opponent_field_goal_fraction_on_court'];
  function describe(pp) {
    const correlations = Object.fromEntries(outcomes.map(o => [o, correlation(pp.map(p => [p.raw_ovr, p.observables[o]]))]));
    const sourceClusters = [...group(pp, p => p.cluster_id).values()];
    const bootstrap = Object.fromEntries(outcomes.map(o => [o, []]));
    const strata = [...group(sourceClusters, cc => cc[0].competition).values()], random = rng(91153);
    for (let i = 0; i < 2000; i++) {
      const sample = strata.flatMap(stratum => stratum.flatMap(() => stratum[Math.floor(random() * stratum.length)]));
      for (const o of outcomes) {
        const value = correlation(sample.map(p => [p.raw_ovr, p.observables[o]]));
        if (value !== null) bootstrap[o].push(value);
      }
    }
    const intervals = Object.fromEntries(outcomes.map(o => {
      const sorted = bootstrap[o].sort((a, b) => a - b);
      return [o, {ci95: [quantile(sorted, 0.025), quantile(sorted, 0.975)],
        valid_resamples: sorted.length, resamples: 2000, descriptive_only: true,
        method: 'quartet/source-population cluster bootstrap stratified by competition', sparse: sourceClusters.length < 10}];
    }));
    return {players: pp.length, independent_quartet_or_population_clusters: sourceClusters.length,
      current_range: histogram(pp.map(p => p.current_ovr)), raw_counts: combinedPlayerTotals(pp), correlation: correlations,
      correlation_intervals: intervals,
      inference: 'Descriptive; only two source quartets/populations per competition/range. No player-row independence or calibrated acceptance claim.'};
  }
  const out = {overall: describe(players), strata: {}, within_strata_demeaned: {}, inversions: []};
  for (const dimension of ['competition', 'position', 'tactical_role', 'rotation_role', 'archetype', 'minute_stratum', 'opportunity_stratum']) {
    out.strata[dimension] = {};
    for (const [k, pp] of group(players, p => p[dimension])) out.strata[dimension][k] = describe(pp);
  }
  const dimensions = ['competition', 'position', 'tactical_role', 'rotation_role'];
  for (const dimension of dimensions) out.within_strata_demeaned[dimension] = Object.fromEntries(outcomes.map(o => {
    const pairs = [...group(players, p => p[dimension]).values()].flatMap(pp => {
      const ok = pp.filter(p => Number.isFinite(p.observables[o]));
      if (!ok.length) return [];
      const mx = ok.reduce((s, p) => s + p.raw_ovr, 0) / ok.length;
      const my = ok.reduce((s, p) => s + p.observables[o], 0) / ok.length;
      return ok.map(p => [p.raw_ovr - mx, p.observables[o] - my]);
    });
    return [o, correlation(pairs)];
  }));
  const jointlyDemeaned = outcomes.map(o => {
    const pairs = [...group(players, p => [p.competition, p.position, p.tactical_role, p.rotation_role].join('/')).values()].flatMap(pp => {
      const ok = pp.filter(p => Number.isFinite(p.observables[o]));
      if (ok.length < 2) return [];
      const mx = ok.reduce((s, p) => s + p.raw_ovr, 0) / ok.length;
      const my = ok.reduce((s, p) => s + p.observables[o], 0) / ok.length;
      return ok.map(p => [p.raw_ovr - mx, p.observables[o] - my]);
    });
    return [o, {correlation: correlation(pairs), player_observations: pairs.length}];
  });
  out.within_strata_demeaned.joint_competition_position_tactical_rotation = Object.fromEntries(jointlyDemeaned);
  // Examples are explicitly searched descriptively, never thresholded into a
  // rating defect. Preserve actual values/body/deployment so causes can be read.
  const comparable = [...group(players, p => p.cluster_id + '/' + p.position + '/' + p.tactical_role + '/' + p.rotation_role).values()];
  for (const pp of comparable) for (let i = 0; i < pp.length; i++) for (let j = i + 1; j < pp.length; j++) {
    const hi = pp[i].raw_ovr > pp[j].raw_ovr ? pp[i] : pp[j], lo = hi === pp[i] ? pp[j] : pp[i];
    if (hi.current_ovr <= lo.current_ovr) continue;
    const reversed = outcomes.filter(o => hi.observables[o] !== null && lo.observables[o] !== null &&
      (o === 'turnovers_per100_touches' || o === 'opponent_field_goal_fraction_on_court' ? hi.observables[o] > lo.observables[o] : hi.observables[o] < lo.observables[o]));
    if (!reversed.length) continue;
    const detail = p => ({player: p.player_id, current: p.current_ovr, raw_ovr: p.raw_ovr, values: p.values,
      body: p.body, position: p.position, role: p.tactical_role, rotation: p.rotation_role,
      mean_minutes: p.observables.mean_minutes, touches: p.raw.touches, attempts: p.raw.field_goals_attempted,
      observables: p.observables, source_seed: p.career_seed ?? null, roster: p.roster_variation ?? null});
    out.inversions.push({cluster: hi.cluster_id, higher: detail(hi), lower: detail(lo), reversed_observables: reversed,
      interpretation: 'Exploratory inversion with raw attributes/deployment/opportunities retained. Causal attribution is unresolved: this descriptive comparison does not isolate individual attributes, body, tendencies, opponents or sampling noise.'});
  }
  out.inversion_total = out.inversions.length;
  out.inversions = out.inversions.slice(0, 12);
  return out;
}
function builderComparables(rows) {
  const ranges = new Set(rows.map(r => r.range));
  check(rows.length === 2368 && ranges.size === 2 && ranges.has('validation_a') && ranges.has('validation_b'),
    'shared Builder confirmation coverage incomplete');
  const primary = rows.filter(r => r.primary);
  check(primary.length === 2304 && new Set(primary.map(r => r.build_id)).size === 18 &&
    BUILDER_PRIMARY.every(id => primary.some(r => r.build_id === id)), 'shared Builder primary portfolio missing');
  for (const r of primary) {
    const rangeStart = r.range === 'validation_a' ? 71000000 : 81000000;
    check(Number.isInteger(r.cell) && r.cell >= 0 && r.cell < 8 && [0,1].includes(r.quartet) && [0,1,2,3].includes(r.phase),
      'shared Builder context domain changed');
    check(r.seed === rangeStart + r.cell * 1000 + r.quartet * 4 + r.phase + 1, 'shared Builder seed shifted');
    check(r.home_subject === (r.phase === 0 || r.phase === 3) && r.subject_opens === (r.phase === 0 || r.phase === 1),
      'shared Builder counterbalance changed');
    check(r.build.family === 1 && r.build.prospect === 1 && r.build.ap_granted === 195 &&
      r.build.ap_spent === 195 && r.build.ap_remaining === 0 && r.build.confirmed === true,
      'shared Builder unequal-resource or unconfirmed primary');
    check(oracle(r.build.ratings).display === r.build.current_overall && oracle(r.build.caps).display === r.build.maximum_potential,
      'shared Builder OVR formula disagreement');
    check(Array.isArray(r.errors) && r.errors.length === 0 && r.touches === r.ledger_touches &&
      r.points === 2*r.field_goals_made+r.three_pointers_made+r.free_throws_made, 'shared Builder instrument reconciliation failed');
    check(typeof r.teammate_signature === 'string' && r.teammate_signature.length > 0 &&
      typeof r.opponent_signature === 'string' && r.opponent_signature.length > 0, 'shared Builder controls missing');
  }
  for (const rr of group(primary, r => r.range+'/'+r.build_id+'/'+r.cell+'/'+r.quartet).values()) {
    check(rr.length === 4 && new Set(rr.map(r => r.phase)).size === 4, 'shared Builder duplicate/missing quartet');
  }
  for (const rr of group(primary, r => r.range+'/'+r.cell+'/'+r.quartet+'/'+r.phase).values()) {
    check(rr.length === 18 && new Set(rr.map(r => r.build_id)).size === 18 &&
      new Set(rr.map(r => r.teammate_signature)).size === 1 && new Set(rr.map(r => r.opponent_signature)).size === 1,
      'shared Builder matched comparison changed controls');
  }
  const players = [...group(primary, r => [r.range,r.cell,r.quartet,r.subject_roster,r.build_id].join('/')).values()].map(rr => {
    const f = rr[0], normalized = rr.map(r => ({...r, team_score:r.team_points, opponent_score:r.opponent_points,
      won:r.team_win ? 1:0, raw_ovr:oracle(r.build.ratings).raw, current_ovr:r.build.current_overall}));
    check(rr.every(r => JSON.stringify(r.build.ratings) === JSON.stringify(f.build.ratings)), 'shared Builder source ratings changed');
    const raw = totals(normalized), defense = rr.reduce((s,r) => s+r.defended_attempts, 0);
    const unavailableCounts = COUNTS.filter(key => normalized.some(r => !Object.hasOwn(r, key)));
    for (const key of unavailableCounts) delete raw[key];
    const defendedMakes = rr.reduce((s,r) => s+r.defended_makes, 0), defendedThrees = rr.reduce((s,r) => s+r.defended_three_makes, 0);
    const m = metrics(raw);
    if (unavailableCounts.includes('opponent_fga_on_court') || unavailableCounts.includes('opponent_fgm_on_court'))
      delete m.opponent_field_goal_fraction_on_court;
    m.allowed_effective_field_goal_fraction = divide(defendedMakes+0.5*defendedThrees, defense);
    return {range:f.range, cell:f.cell, quartet:f.quartet, roster:f.subject_roster, build_id:f.build_id,
      context:f.context, current_ovr:f.build.current_overall, raw_ovr:oracle(f.build.ratings).raw,
      values:f.build.ratings, caps:f.build.caps, body:f.build.body, tendencies:f.build.tendencies,
      raw, observables:m, unavailable_counts:unavailableCounts, defender_attempts:defense, defender_makes:defendedMakes};
  });
  const outcomes = ['points_per32','field_goal_fraction','assists_per100_touches','turnovers_per100_touches',
    'rebounds_per32','steals_blocks_per32','allowed_effective_field_goal_fraction','team_margin'];
  const pairs = [], inversions = [];
  const detail = p => ({build_id:p.build_id, current_ovr:p.current_ovr, raw_ovr:p.raw_ovr, values:p.values,
    caps:p.caps, body:p.body, tendencies:p.tendencies, raw:p.raw, unavailable_counts:p.unavailable_counts, defender_attempts:p.defender_attempts,
    defender_makes:p.defender_makes, observables:p.observables});
  for (const pp of group(players, p => [p.range,p.cell,p.quartet,p.roster].join('/')).values()) {
    for (let i=0;i<pp.length;i++) for (let j=i+1;j<pp.length;j++) {
      const a=pp[i], b=pp[j], delta=Object.fromEntries(outcomes.map(o=>[o,
        a.observables[o]===null||b.observables[o]===null?null:a.observables[o]-b.observables[o]]));
      const ref={range:a.range, cell:a.cell, quartet:a.quartet, roster:a.roster, context:a.context};
      if (a.current_ovr===b.current_ovr && JSON.stringify(a.values)!==JSON.stringify(b.values)) {
        pairs.push({...ref, a:detail(a), b:detail(b), differences:delta,
          interpretation:'Same displayed rating with different legal strengths; direct pooled-count outcomes in a matched context. Small samples and differences in body/tendencies prevent isolated causal attribution.'});
      } else if (a.current_ovr!==b.current_ovr) {
        const hi=a.current_ovr>b.current_ovr?a:b, lo=hi===a?b:a;
        const reversed=outcomes.filter(o=>hi.observables[o]!==null&&lo.observables[o]!==null&&
          (o==='turnovers_per100_touches'||o==='allowed_effective_field_goal_fraction'?hi.observables[o]>lo.observables[o]:hi.observables[o]<lo.observables[o]));
        if(reversed.length) inversions.push({...ref,higher:detail(hi),lower:detail(lo),reversed_observables:reversed,
          interpretation:'Matched same-resource comparison; individual attribute/body/tendency causes remain unresolved without targeted interventions.'});
      }
    }
  }
  const byContext={};
  for(const [cell,pp] of group(players,p=>p.cell)) byContext[cell]={context:pp[0].context,
    source_player_quartet_observations:pp.length, descriptive_correlations:Object.fromEntries(outcomes.map(o=>[o,
      correlation(pp.map(p=>[p.raw_ovr,p.observables[o]]))]))};
  return {games:rows.length, primary_equal_resource_games:primary.length, omitted_unequal_profile_and_other_family_games:rows.length-primary.length,
    unavailable_counters:[...new Set(players.flatMap(p=>p.unavailable_counts))],
    source_player_context_observations:players.length, same_displayed_ovr_pair_count:pairs.length,
    same_displayed_ovr_examples:pairs.slice(0,24), differing_ovr_inversion_count:inversions.length,
    differing_ovr_inversion_examples:inversions.slice(0,24), by_context:byContext,
    uncertainty:'Descriptive secondary use of independently frozen Builder validation; no extra confirmatory family or equivalence/dominance verdict.',
    primary_legality_authority:'Builder independent full-fixture validator and its retained manifests; this reader independently verifies budget, exact rating arithmetic and matched input coverage.'};
}
function main() {
  const directory = path.resolve(process.argv[2] || path.join(ROOT, 'reports'));
  const output = path.resolve(process.argv[3] || path.join(__dirname, 'aggregate.json'));
  const result = {version: 'ovr-truthfulness-v1', protocol_sha256: sha(path.join(__dirname, 'protocol.json')),
    primary_family: '7 aggregate outcomes x two untouched ranges; descriptive family strata excluded',
    inputs: [], within: {}, population_relationships: {}, histograms: null, certified: false};
  const histogramPayloads = [];
  for (const range of ['A', 'B']) {
    const files = ['within', 'catalog', 'college'].map(kind => ({kind, file: path.join(directory, `ovr_${kind}_${range}.ndjson`)}));
    const manifestFile = path.join(directory, `ovr_manifest_${range}.json`), manifest = json(manifestFile);
    check(manifest.protocol_sha256 === result.protocol_sha256, 'protocol changed since execution');
    result.inputs.push({range, manifest, manifest_sha256: sha(manifestFile)});
    for (const {kind, file} of files) {
      check(sha(file) === manifest.outputs[kind].sha256, 'raw output changed since execution: ' + kind);
      const rows = ndjson(file);
      check(rows.length === manifest.outputs[kind].rows, 'row count disagrees with manifest');
      if (kind === 'within') {
        const audit = validateWithin(rows);
        const summaries = Object.fromEntries(ARMS.map(a => [a, {raw: totals(rows.filter(r => r.arm === a)),
          normalized: metrics(totals(rows.filter(r => r.arm === a)))}]));
        const byFamily = {};
        for (const [family, rr] of group(rows, r => r.family)) byFamily[family] = {
          arms: Object.fromEntries(ARMS.map(a => [a, {raw: totals(rr.filter(r => r.arm === a)), normalized: metrics(totals(rr.filter(r => r.arm === a)))}])),
          all20_vs_baseline: pairedBootstrap(rr, ARMS[1], 10000, 931),
          interpretation: '8 source-player clusters; descriptive sparse family stratum, no simultaneous test'};
        result.within[range] = {audit, arms: summaries, all20_vs_baseline: pairedBootstrap(rows, ARMS[1]),
          scoring5_vs_baseline: pairedBootstrap(rows, ARMS[2], 10000, 913), by_family: byFamily,
          seed_first: Math.min(...rows.map(r => r.seed)), seed_last: Math.max(...rows.map(r => r.seed))};
      } else {
        const coverage = validatePopulation(rows, kind, range);
        check(coverage.games === manifest.outputs[kind].games, 'population game count disagrees with manifest');
        result.population_relationships[kind + '_' + range] = {coverage, ...relationships(rows)};
      }
    }
    const histFile = path.join(directory, `ovr_histograms_${range}.json`);
    check(sha(histFile) === manifest.outputs.histograms.sha256, 'histogram output changed since execution');
    histogramPayloads.push(json(histFile));
  }
  result.histograms = naturalHistogram(histogramPayloads);
  const builderFiles = process.argv.slice(4);
  if (builderFiles.length) {
    check(builderFiles.length === 2, 'both untouched Builder validation raw files required');
    result.shared_builder = builderComparables(builderFiles.flatMap(file=>ndjson(path.resolve(file))));
    result.shared_builder.inputs = builderFiles.map(file=>({path:path.resolve(file),sha256:sha(path.resolve(file))}));
  }
  result.source_sha256 = {analysis: sha(__filename)};
  fs.writeFileSync(output, JSON.stringify(result, null, 2) + '\n');
  process.stdout.write(JSON.stringify({output, within_games: Object.values(result.within).reduce((s, r) => s + r.audit.games, 0),
    catalog_games: ['A', 'B'].reduce((s, r) => s + result.population_relationships['catalog_' + r].coverage.games, 0),
    college_games: ['A', 'B'].reduce((s, r) => s + result.population_relationships['college_' + r].coverage.games, 0),
    natural_careers: result.histograms.natural_careers, certified: false}) + '\n');
}
module.exports = {oracle, pointCost, validateRow, validateWithin, validatePopulation, totals, metrics, pairedBootstrap, correlation, playerObservations, relationships, naturalHistogram, builderComparables, PRIMARY, COUNTS, COMPETITIONS, BUILDER_PRIMARY};
if (require.main === module) main();
