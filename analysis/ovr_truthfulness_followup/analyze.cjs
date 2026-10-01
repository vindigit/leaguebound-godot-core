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
  check(oracle(r.values).display === r.current_ovr, 'current OVR disagrees with independent rational oracle');
  check(Math.abs(oracle(r.values).raw - r.raw_ovr) < 1e-9, 'raw OVR disagrees with independent rational oracle');
  if (r.caps) check(oracle(r.caps).display === r.maximum_potential, 'exact-cap potential disagrees with oracle');
  return true;
}
function group(rows, key) {
  const map = new Map();
  for (const row of rows) { const k = key(row); if (!map.has(k)) map.set(k, []); map.get(k).push(row); }
  return map;
}
function validateWithin(rows, clustersPerFamily = 8) {
  rows.forEach(validateRow);
  const clusters = group(rows, r => r.range + '/' + r.cluster);
  check(rows.length === clustersPerFamily * 3 * 3 * 4, 'missing complete within-player sample');
  check(clusters.size === clustersPerFamily * 3, 'missing source-player cluster');
  const familyCounts = {};
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
  const seen = new Set();
  for (const c of careers) {
    check(!seen.has(c.career_seed), 'duplicate natural career seed'); seen.add(c.career_seed);
    check(oracle(c.starting_values).display === c.starting_current, 'natural start formula mismatch');
    check(oracle(c.exact_caps).display === c.maximum_potential, 'natural exact-cap formula mismatch');
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
  check(fixture.length === 117 * 10 * 5, 'missing finite fixture histogram coverage');
  for (const [competition, rr] of group(fixture, r => r.competition)) {
    check(new Set(rr.map(r => r.roster_variation + '/' + r.player_id)).size === 1170, 'duplicate fixture histogram player');
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
      interpretation: 'Exploratory inversion; both attributes, body, opponent, finite samples and rotation can matter. Overall is no simulation input.'});
  }
  out.inversion_total = out.inversions.length;
  out.inversions = out.inversions.slice(0, 12);
  return out;
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
      } else result.population_relationships[kind + '_' + range] = relationships(rows);
    }
    const histFile = path.join(directory, `ovr_histograms_${range}.json`);
    check(sha(histFile) === manifest.outputs.histograms.sha256, 'histogram output changed since execution');
    histogramPayloads.push(json(histFile));
  }
  result.histograms = naturalHistogram(histogramPayloads);
  result.source_sha256 = {analysis: sha(__filename)};
  fs.writeFileSync(output, JSON.stringify(result, null, 2) + '\n');
  process.stdout.write(JSON.stringify({output, within_games: 576, catalog_games: 80, college_games: 16,
    natural_careers: result.histograms.natural_careers, certified: false}) + '\n');
}
module.exports = {oracle, pointCost, validateRow, validateWithin, totals, metrics, pairedBootstrap, correlation, playerObservations, relationships, naturalHistogram, PRIMARY, COUNTS};
if (require.main === module) main();
