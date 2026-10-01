'use strict';
const assert = require('node:assert/strict');
const A = require('../../analysis/ovr_truthfulness_followup/analyze.cjs');
const cases = {};
cases.exact_rational_formula_and_rounding = () => {
  assert.equal(A.oracle(Array(20).fill(25)).display, 25);
  assert.equal(A.oracle(Array(20).fill(99)).display, 99);
  const boundary = [25,25,26,28,28,30,30,34,41,41,44,48,54,69,76,82,84,89,92,94];
  assert.equal(A.oracle(boundary).raw, 56.5); assert.equal(A.oracle(boundary).display, 57);
  boundary[10]--; assert.equal(A.oracle(boundary).display, 56);
};
function fakeRows(perFamily = 1) {
  const rows = [];
  for (let family = 0; family < 3; family++) for (let i = 0; i < perFamily; i++) {
    const cluster = family * perFamily + i;
    const before = Array(20).fill(48), caps = Array(20).fill(80);
    for (const [a, arm] of ['baseline', 'all20_plus10_toward_caps', 'scoring5_plus10_toward_caps'].entries()) for (let slot = 0; slot < 4; slot++) {
      const values = before.map((v, k) => a === 0 || (a === 2 && k > 4) ? v : v + 10);
      const row = Object.fromEntries(A.COUNTS.map(k => [k, 0]));
      Object.assign(row, {experiment: 'within', range: 'A', cluster, family: ['guard','wing','big'][family], arm, slot,
        source_seed: 500 + cluster, seed: 900 + cluster * 4 + slot, subject_home: slot === 0 || slot === 3,
        subject_opens: slot === 0 || slot === 1, values, caps, current_ovr: A.oracle(values).display,
        raw_ovr: A.oracle(values).raw, maximum_potential: 80, position: 'SF', rotation_role: 'starter',
        tactical_role: 'slasher', body: 'constant', teammates_sha256: 'fixed', opponent_sha256: 'fixed', tendencies: Array(10).fill(3),
        intervention: {before, ap_granted: a === 0 ? 0 : a === 1 ? 200 : 50, rating_points_applied: a === 0 ? 0 : a === 1 ? 200 : 50},
        seconds_played: 1920, points: a === 0 ? 10 : 12, field_goals_made: a === 0 ? 5 : 6, field_goals_attempted: 12,
        touches: 20, ledger_touches: 20, on_court_offense_possessions: 50, on_court_defense_possessions: 50,
        team_possessions: 60, opponent_possessions: 60, team_score: 52 + a, opponent_score: 50, team_margin: 2 + a, won: 1,
        assists: 3, turnovers: 2, offensive_rebounds: 1, defensive_rebounds: 4, steals: 1, blocks: 1, player_id: 'subject_focus'});
      rows.push(row);
    }
  }
  return rows;
}
cases.complete_pairing_and_shuffled_rows = () => {
  const rows = fakeRows(); assert.equal(A.validateWithin(rows, 1).complete, true);
  assert.deepEqual(A.validateWithin(rows.slice().reverse(), 1), A.validateWithin(rows, 1));
};
cases.duplicate_seed_is_rejected = () => {
  const rows = fakeRows(); rows[1].seed = rows[0].seed;
  assert.throws(() => A.validateWithin(rows, 1), /duplicate seed/);
};
cases.missing_counterbalance_is_rejected = () => {
  const rows = fakeRows(); rows[1].subject_home = rows[0].subject_home; rows[1].subject_opens = rows[0].subject_opens;
  assert.throws(() => A.validateWithin(rows, 1), /unbalanced venue/);
};
cases.controlled_roster_mutation_is_rejected = () => {
  const rows = fakeRows(); rows[4].opponent_sha256 = 'changed';
  assert.throws(() => A.validateWithin(rows, 1), /controlled teammates\/opponent/);
};
cases.touch_denominator_corruption_is_rejected = () => {
  const row = fakeRows()[0]; row.touches++;
  assert.throws(() => A.validateRow(row), /ledger touch denominator/);
};
cases.ratio_of_pooled_attempts_and_zero_denominator = () => {
  const a = fakeRows()[0], b = {...a};
  a.field_goals_made = 1; a.field_goals_attempted = 1;
  b.field_goals_made = 0; b.field_goals_attempted = 9;
  assert.equal(A.metrics(A.totals([a, b])).field_goal_fraction, 0.1);
  a.field_goals_attempted = 0; a.field_goals_made = 0;
  assert.equal(A.metrics(A.totals([a])).field_goal_fraction, null);
};
cases.bootstrap_retains_paired_clusters_and_is_deterministic = () => {
  const rows = fakeRows(8);
  rows.forEach(r => { r.points += r.cluster * 2; r.field_goals_made += r.cluster; r.field_goals_attempted += r.cluster; });
  const first = A.pairedBootstrap(rows, 'all20_plus10_toward_caps', 500, 1);
  const second = A.pairedBootstrap(rows, 'all20_plus10_toward_caps', 500, 1);
  assert.deepEqual(first, second);
  assert.ok(Math.abs(first.points_per32.difference - 2) < 1e-12);
  assert.ok(first.points_per32.ci95.every(v => Math.abs(v - 2) < 1e-12));
  assert.equal(first.team_margin.source_player_clusters, 24);
};
cases.multiplicity_interval_is_wider_than_pointwise = () => {
  const rows = fakeRows(8);
  rows.filter(r => r.arm === 'all20_plus10_toward_caps').forEach(r => {
    r.team_score += r.cluster; r.team_margin += r.cluster;
  });
  const m = A.pairedBootstrap(rows, 'all20_plus10_toward_caps', 1000, 17).team_margin;
  assert.ok(m.familywise_ci95[0] < m.ci95[0], '14-comparison lower bound must be wider');
  assert.ok(m.familywise_ci95[1] > m.ci95[1], '14-comparison upper bound must be wider');
};
cases.raw_count_minutes_and_opportunity_denominators = () => {
  const rows = fakeRows().filter(r => r.arm === 'baseline'), t = A.totals(rows), m = A.metrics(t);
  assert.equal(t.games, 12); assert.equal(t.seconds_played, 12 * 1920);
  assert.equal(m.points_per32, 10); assert.equal(m.points_per100_offense_possessions, 20);
  assert.equal(m.assists_per100_touches, 15); assert.equal(m.turnovers_per100_touches, 10);
  assert.equal(m.rebounds_per32, 5);
};
cases.aggregate_relationship_does_not_imply_within_stratum = () => {
  assert.ok(A.correlation([[40,10],[50,8],[70,30],[80,28]]) > 0);
  assert.equal(A.correlation([[40,10],[50,8],[45,9]]), -1);
  assert.equal(A.correlation([[50,1],[50,2],[50,3]]), null);
};
let passed = 0, failed = 0;
for (const [name, fn] of Object.entries(cases)) {
  try { fn(); passed++; process.stdout.write('PASSED ' + name + '\n'); }
  catch (error) { failed++; process.stderr.write('FAILED ' + name + ' ' + error.name + ': ' + error.message + '\n'); }
}
process.stdout.write(`${passed}/${Object.keys(cases).length} passed, ${failed} failed\n`);
if (failed) process.exitCode = 1;
