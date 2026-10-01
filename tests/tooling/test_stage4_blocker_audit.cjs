'use strict';
const {test} = require('node:test');
const assert = require('node:assert/strict');
const {aggregationEstimate, auditReport, auditCorrectedRows, classify, auditVenue,
  wilsonEndpoints, reproduceOvertimeIntervals} = require('../../tools/stage4_blocker_audit.cjs');
const clone = x => JSON.parse(JSON.stringify(x));
function report() {
  const metrics = [
    {metric: 'sample.meets_certification_size', definition: 'Required sample reached', denominator: 'boolean invariant',
      estimate: 0, sample_count: 4, verdict: 'fail', target: {minimum: 1, maximum: 1, source: 'BALANCE_SPEC.md §27.1'}},
    {metric: 'college.field_goal_percentage', definition: 'Made / attempted', denominator: 'attempts', estimate: 0.4,
      sample_count: 100, verdict: 'fail', target: {minimum: 0.42, maximum: 0.49, source: 'BALANCE_SPEC.md §14.1'},
      aggregation: {kind: 'proportion', numerator: 40, denominator: 100, scale: 1}},
    {metric: 'college.points_per_possession', definition: 'Points / engine possessions', denominator: 'engine possessions', estimate: 1,
      sample_count: 200, verdict: 'pass', target: {minimum: 0.98, maximum: 1.10, source: 'BALANCE_SPEC.md §14.1'},
      aggregation: {kind: 'ratio', numerator: 200, denominator: 200, scale: 1}}
  ];
  return {schema: 'leaguebound.calibration.report/1', metrics,
    summary: {metric_count: 3, judged_metric_count: 3, failure_count: 2, passed: false},
    context: {sample_count: 4, seed_range: {start: 1, end: 4}}, sections: {competition_table: [{competition: 'college', games: 4}]}};
}
function corrected() {
  const first = 28080000, A = {attribute_vectors: [Array(20).fill(45)], mean_raw_overall: 45},
    B = {attribute_vectors: [Array(20).fill(47)], mean_raw_overall: 47};
  const rows = Array.from({length: 468}, (_, i) => ({seed: first + i + 1, variation: first + i,
    block: Math.floor((first + i) / 4), opening_home: i % 2 === 0, games: 1, team_games: 2, decided_games: 1,
    home_strength: i % 4 === 1 || i % 4 === 2 ? B : A, away_strength: i % 4 === 1 || i % 4 === 2 ? A : B,
    home_score: 10, away_score: 8, points: 18, margin: 2, engine_possessions: 20, regulation_possessions: 20, overtime_possessions: 0,
    field_goals_made: 8, field_goals_attempted: 16, three_pointers_made: 2, three_pointers_attempted: 6,
    free_throws_made: 0, free_throws_attempted: 2, turnovers: 3, offensive_rebounds: 2, offensive_rebound_chances: 10,
    assists: 4, home_wins: 1, overtime_games: 0, close_games: 1, blowout_games: 0}));
  const terms = {possessions_per_game: [20, 2], points_per_game: [18, 2], points_per_possession: [18, 20],
    field_goal_percentage: [8, 16], three_point_percentage: [2, 6], free_throw_percentage: [0, 2],
    three_point_attempt_rate: [6, 16], free_throw_attempt_rate: [2, 16], turnovers_per_100_possessions: [3, 20, 100],
    offensive_rebound_percentage: [2, 10], assist_percentage: [4, 8], home_win_rate: [1, 1],
    overtime_rate: [0, 1], close_game_rate: [1, 1], blowout_rate: [0, 1]};
  const metrics = Object.entries(terms).map(([name, [n, d, scale = 1]]) => ({metric: 'college.' + name,
    estimate: scale * n / d, verdict: 'informational'}));
  const summary = {metrics: Object.fromEntries(metrics.map(m => [m.metric.slice(8),
    {estimate: m.estimate, canonical_verdict: m.verdict, target: null, interval: null, interval_status: 'test'}]))};
  return {first, raw: {catalog: 'competition-catalog-v4-roster-pairing', competition: 'college', environment: 0.5,
    seed_first: first + 1, seed_last: first + 468, rows}, report: {metrics}, summary};
}
test('raw totals use weighted denominator, never a mean of rates', () => {
  assert.equal(aggregationEstimate({kind: 'ratio', numerator: 30, denominator: 100, scale: 100}), 30);
  assert.equal(aggregationEstimate({kind: 'mean', count: 2, sum: 9, sum_of_squares: 41}), 4.5);
});
test('invalid denominator is rejected', () => {
  assert.throws(() => aggregationEstimate({kind: 'ratio', numerator: 1, denominator: 0}), /positive finite denominator/);
  assert.throws(() => aggregationEstimate({kind: 'ratio', numerator: 1, denominator: NaN}), /positive finite denominator/);
});
test('report reconciles exact coverage and failures', () => {
  const a = auditReport(report(), null, ['college']); assert.equal(a.failures.length, 2); assert.equal(a.recomputed, 2);
});
test('duplicate metrics are rejected', () => {
  const x = report(); x.metrics.push(clone(x.metrics[1])); assert.throws(() => auditReport(x, null, ['college']), /unique metric ids/);
});
test('changed verdict is rejected for its target', () => {
  const x = report(); x.metrics[1].verdict = 'pass'; assert.throws(() => auditReport(x, null, ['college']), /canonical verdict/);
});
test('changed target is rejected against the reference', () => {
  const x = report(); x.metrics[1].target.minimum = 0.38; x.metrics[1].verdict = 'pass';
  x.summary.failure_count = 1; assert.throws(() => auditReport(x, report(), ['college']), /locked target unchanged/);
});
test('changed aggregate and missing competition are rejected', () => {
  const x = report(); x.metrics[1].aggregation.numerator = 42; assert.throws(() => auditReport(x, null, ['college']), /raw aggregate estimate/);
  assert.throws(() => auditReport(report(), null, ['high_school', 'college']), /competition coverage/);
});
test('corrected quartets and raw-to-canonical ratios reconcile', () => {
  const x = corrected(); const r = auditCorrectedRows(x.raw, x.report, x.summary, x.first, 'college');
  assert.equal(r.clusters, 117); assert.equal(r.metrics.turnovers_per_100_possessions.estimate, 15);
});
test('duplicate seeds are rejected', () => {
  const x = corrected(); x.raw.rows[1].seed = x.raw.rows[0].seed;
  assert.throws(() => auditCorrectedRows(x.raw, x.report, x.summary, x.first, 'college'), /duplicate seeds rejected/);
});
test('broken opener and roster pairings are rejected', () => {
  const x = corrected(); x.raw.rows[1].opening_home = true;
  assert.throws(() => auditCorrectedRows(x.raw, x.report, x.summary, x.first, 'college'), /balanced opener/);
  const y = corrected(); y.raw.rows[1].home_strength = y.raw.rows[0].home_strength;
  assert.throws(() => auditCorrectedRows(y.raw, y.report, y.summary, y.first, 'college'), /ABBA roster pair/);
});
test('sample shortage is a certification blocker and population venue is a separate estimand', () => {
  assert.equal(classify('sample.meets_certification_size').category, 'Insufficient sample or missing coverage');
  assert.equal(classify('college.home_win_rate').category, 'Infrastructure/reporting problem');
  assert.equal(classify('college.overtime_rate').category, 'Statistical target miss without a proven defect');
});
test('venue uses symmetrized triples and rejects duplicates', () => {
  const r = {fixture: 'college/1', competition: 'college', home_margin: 8, reversed_margin: -2,
    neutral_margin: 2, home_possessions: 60, neutral_possessions: 60, reversed_possessions: 60};
  const metrics = [['venue.attributable_home_win_rate', 0.5], ['venue.points_per_100', 5],
    ['venue.cap_respected', 0], ['home.points_per_100_contribution', 7]].map(([suffix, estimate]) =>
    ({metric: 'college.' + suffix, estimate, verdict: 'informational'}));
  const x = {context: {competition: 'college', sample_count: 2}, metrics,
    sections: {venue_paired_fixtures: [r, {...r, fixture: 'college/2'}]}};
  assert.equal(auditVenue(x).paired_points_per100.estimate, 5);
  x.sections.venue_paired_fixtures[1].fixture = r.fixture;
  assert.throws(() => auditVenue(x), /unique venue fixture/);
});

test('probability reproducer preserves actual and correct Wilson endpoints', () => {
  const zero = wilsonEndpoints(0, 40), one = wilsonEndpoints(1, 40);
  assert.ok(Math.abs(zero[0]) < 1e-14 && Math.abs(zero[1] - 0.08762160245846368) < 1e-14);
  assert.ok(Math.abs(one[0] - 0.004426831453704344) < 1e-14 &&
    Math.abs(one[1] - 0.12881369088183614) < 1e-14);
  const interval = {low: -0.0438108012292318, high: 0.0438108012292318};
  const metric = {metric: 'development.overtime_rate', estimate: 0,
    aggregation: {kind: 'proportion', numerator: 0, denominator: 40}, interval_95: interval};
  const witness = reproduceOvertimeIntervals({metrics: [metric]})[0];
  assert.deepEqual(witness.published, interval);
  assert.deepEqual(witness.Wilson_endpoints, zero);
  assert.equal(witness.proven_reporting_defect, true);
  assert.throws(() => wilsonEndpoints(0, 0), /valid Wilson counts/);
});
