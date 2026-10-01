'use strict';
// Observation-only independent recount. It consumes canonical targets rather
// than supplying new acceptance bands. No gameplay or report verdict is tuned.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const COMPS = ['high_school', 'college', 'development', 'overseas', 'top_domestic_pro'];
const TERMS = {
  possessions_per_game: ['engine_possessions', 'team_games'],
  points_per_game: ['points', 'team_games'],
  points_per_possession: ['points', 'engine_possessions'],
  field_goal_percentage: ['field_goals_made', 'field_goals_attempted'],
  three_point_percentage: ['three_pointers_made', 'three_pointers_attempted'],
  free_throw_percentage: ['free_throws_made', 'free_throws_attempted'],
  three_point_attempt_rate: ['three_pointers_attempted', 'field_goals_attempted'],
  free_throw_attempt_rate: ['free_throws_attempted', 'field_goals_attempted'],
  turnovers_per_100_possessions: ['turnovers', 'engine_possessions', 100],
  offensive_rebound_percentage: ['offensive_rebounds', 'offensive_rebound_chances'],
  assist_percentage: ['assists', 'field_goals_made'],
  home_win_rate: ['home_wins', 'decided_games'],
  overtime_rate: ['overtime_games', 'games'],
  close_game_rate: ['close_games', 'games'],
  blowout_rate: ['blowout_games', 'games']
};
const approx = (a, b, label) => assert.ok(Number.isFinite(a) && Number.isFinite(b) &&
  Math.abs(a - b) <= 1e-11 * Math.max(1, Math.abs(a), Math.abs(b)), label);
const read = f => JSON.parse(fs.readFileSync(f, 'utf8').replace(/^\uFEFF/, ''));
const hash = f => crypto.createHash('sha256').update(fs.readFileSync(f)).digest('hex');
function aggregationEstimate(a) {
  assert.ok(a && typeof a === 'object', 'aggregation payload');
  if (a.kind === 'ratio' || a.kind === 'proportion') {
    assert.ok(Number.isFinite(a.denominator) && a.denominator > 0, 'positive finite denominator');
    assert.ok(Number.isFinite(a.numerator), 'finite numerator');
    if (a.kind === 'proportion') assert.ok(a.numerator >= 0 && a.numerator <= a.denominator, 'valid proportion');
    return (a.scale ?? 1) * a.numerator / a.denominator;
  }
  if (a.kind === 'mean') {
    assert.ok(Number.isInteger(a.count) && a.count > 0 && Number.isFinite(a.sum), 'valid mean terms');
    assert.ok(Number.isFinite(a.sum_of_squares) && a.sum_of_squares + 1e-7 >= a.sum * a.sum / a.count, 'valid mean moments');
    return a.sum / a.count;
  }
  if (a.kind === 'constant') return a.sum;
  throw new Error('Unsupported aggregation kind: ' + a.kind);
}
function auditReport(report, reference = null, competitions = COMPS) {
  assert.equal(report.schema, 'leaguebound.calibration.report/1', 'report schema');
  assert.ok(Array.isArray(report.metrics) && report.metrics.length > 0, 'metrics present');
  const seen = new Set(), failures = [], refs = new Map(reference?.metrics.map(m => [m.metric, m]) || []);
  let judged = 0, recomputed = 0;
  for (const m of report.metrics) {
    assert.ok(!seen.has(m.metric), 'unique metric ids'); seen.add(m.metric);
    assert.ok(m.definition && m.denominator, 'metric definition and denominator required');
    assert.ok(Number.isFinite(m.estimate) && Number.isInteger(m.sample_count) && m.sample_count >= 0, 'finite metric/count');
    if (m.aggregation) { approx(m.estimate, aggregationEstimate(m.aggregation), 'raw aggregate estimate'); recomputed++; }
    let verdict = 'informational';
    if (m.target) {
      judged++;
      assert.ok(Number.isFinite(m.target.minimum) && Number.isFinite(m.target.maximum) &&
        m.target.minimum <= m.target.maximum && m.target.source, 'valid target');
      verdict = m.estimate >= m.target.minimum && m.estimate <= m.target.maximum ? 'pass' : 'fail';
    }
    assert.equal(m.verdict, verdict, 'canonical verdict matches unchanged target');
    if (reference) {
      assert.ok(refs.has(m.metric), 'reference metric coverage');
      assert.deepEqual(m.target, refs.get(m.metric).target, 'locked target unchanged');
      assert.equal(m.denominator, refs.get(m.metric).denominator, 'denominator definition unchanged');
    }
    if (verdict === 'fail') failures.push(m);
  }
  if (reference) assert.equal(seen.size, refs.size, 'complete reference metric set');
  assert.equal(report.summary.metric_count, seen.size, 'metric count');
  assert.equal(report.summary.judged_metric_count, judged, 'judged metric count');
  assert.equal(report.summary.failure_count, failures.length, 'failure count');
  assert.equal(report.summary.passed, failures.length === 0, 'summary verdict');
  const table = report.sections.competition_table;
  assert.deepEqual(table.map(r => r.competition).sort(), [...competitions].sort(), 'competition coverage');
  assert.ok(table.every(r => Number.isInteger(r.games) && r.games > 0), 'positive complete games');
  assert.equal(report.context.sample_count, table.reduce((n, r) => n + r.games, 0), 'total games across competitions');
  assert.equal(report.context.seed_range.end - report.context.seed_range.start + 1, table[0].games, 'seed span per competition');
  assert.ok(table.every(r => r.games === table[0].games), 'same declared games per competition');
  return {metric_count: seen.size, judged, recomputed, failures,
    total_games: report.context.sample_count, per_competition_games: table[0].games,
    seed_range: report.context.seed_range, context: report.context,
    note: 'context.sample_count is total across competitions; the historical sample_unit says per competition. This audit uses table/metric counts. Intervals retained from canonical report, not certified.'};
}
function auditCorrectedRows(raw, report, summaryCell, first, comp) {
  assert.equal(raw.catalog, 'competition-catalog-v4-roster-pairing', 'corrected fixture population');
  assert.equal(raw.competition, comp, 'raw competition'); assert.equal(raw.environment, 0.5, 'home environment');
  assert.equal(raw.rows.length, 468, 'full corrected marginal cycle');
  assert.equal(raw.seed_first, first + 1, 'declared first seed'); assert.equal(raw.seed_last, first + 468, 'declared last seed');
  const seen = new Set();
  for (let i = 0; i < raw.rows.length; i++) {
    const r = raw.rows[i];
    assert.ok(!seen.has(r.seed), 'duplicate seeds rejected'); seen.add(r.seed);
    assert.equal(r.variation, first + i, 'exact variation coverage'); assert.equal(r.seed, r.variation + 1, 'simulation seed');
    assert.equal(r.block, Math.floor(r.variation / 4), 'quartet cluster');
    assert.equal(r.opening_home, r.variation % 2 === 0, 'balanced opener');
    assert.equal(r.games, 1); assert.equal(r.team_games, 2); assert.equal(r.decided_games, 1);
    assert.equal(r.margin, r.home_score - r.away_score, 'signed margin');
    assert.equal(r.points, r.home_score + r.away_score, 'points identity');
    assert.equal(r.engine_possessions, r.regulation_possessions + r.overtime_possessions, 'possession identity');
    if (i % 4 === 0) {
      const [a, b, c, d] = raw.rows.slice(i, i + 4);
      assert.deepEqual(a.home_strength, b.away_strength, 'ABBA roster pair');
      assert.deepEqual(a.home_strength, c.away_strength, 'ABBA roster pair');
      assert.deepEqual(a.home_strength, d.home_strength, 'ABBA roster pair');
      assert.deepEqual(a.away_strength, b.home_strength, 'ABBA roster pair');
      assert.deepEqual(a.away_strength, c.home_strength, 'ABBA roster pair');
      assert.deepEqual(a.away_strength, d.away_strength, 'ABBA roster pair');
    }
  }
  const totals = {};
  for (const [name, [numerator, denominator, scale = 1]] of Object.entries(TERMS)) {
    const n = raw.rows.reduce((s, r) => s + r[numerator], 0), d = raw.rows.reduce((s, r) => s + r[denominator], 0);
    assert.ok(Number.isFinite(n) && d > 0 && Number.isFinite(d), 'raw valid denominator');
    const m = report.metrics.find(m => m.metric === comp + '.' + name);
    assert.ok(m, 'canonical raw metric coverage'); approx(scale * n / d, m.estimate, 'raw-to-canonical ratio');
    const s = summaryCell.metrics[name]; assert.ok(s, 'summary coverage');
    approx(m.estimate, s.estimate, 'raw-to-summary estimate');
    assert.equal(m.verdict, s.canonical_verdict, 'summary verdict'); assert.deepEqual(m.target ?? null, s.target, 'summary target');
    totals[name] = {numerator: n, denominator: d, scale, estimate: m.estimate,
      verdict: m.verdict, target: m.target ?? null, interval: s.interval, interval_status: s.interval_status};
  }
  return {games: 468, clusters: 117, first_variation: first, last_variation: first + 467, metrics: totals};
}
function classify(metric) {
  if (metric === 'sample.meets_certification_size') return {category: 'Insufficient sample or missing coverage',
    next_action: 'Close mechanism, population, owner and infrastructure blockers before the authorized later §27.1 run. No gameplay defect inferred.'};
  if (metric.endsWith('.home.combined_cap_respected')) return {category: 'Infrastructure/reporting problem',
    next_action: 'Retain the legacy failed verdict and canonical paired cap separately; reconcile the measurement definitions, then assess controlled disjoint venue ranges before any tuning.'};
  if (metric.endsWith('.home_win_rate')) return {category: 'Infrastructure/reporting problem',
    next_action: 'Preserve canonical population verdict; separately run the locked controlled equal-team §17.4 estimand with balanced disjoint ranges. Do not infer home-court tuning from population win rates.'};
  return {category: 'Statistical target miss without a proven defect',
    next_action: /field_goal|three_point_percentage|three_point_attempt_rate/.test(metric)
      ? 'Audit ledger FGA conventions and appropriate roster shape first; retain locked shooting bands. Contract changes require owner direction.'
      : 'Use disjoint controlled diagnostics to identify a mechanism; preserve §14.2 bands, clocks and probabilities. Any policy/target change needs owner direction.'};
}
function auditVenue(report) {
  const rows = report.sections.venue_paired_fixtures, comp = report.context.competition;
  assert.ok(Array.isArray(rows) && rows.length === report.context.sample_count, 'venue triple coverage');
  const seen = new Set();
  let winSum = 0, marginSum = 0, possessionSum = 0;
  for (const r of rows) {
    assert.ok(!seen.has(r.fixture), 'unique venue fixture'); seen.add(r.fixture);
    assert.equal(r.competition, comp, 'venue competition');
    for (const arm of ['home', 'neutral', 'reversed']) {
      assert.ok(Number.isFinite(r[arm + '_margin']) && Number.isFinite(r[arm + '_possessions'])
        && r[arm + '_possessions'] > 0, 'complete finite venue triple');
      possessionSum += r[arm + '_possessions'];
    }
    const win = m => m > 0 ? 1 : m < 0 ? 0 : 0.5;
    winSum += 0.5 * (win(r.home_margin) + win(r.reversed_margin));
    marginSum += 0.5 * (r.home_margin + r.reversed_margin);
  }
  const metric = suffix => {
    const found = report.metrics.filter(m => m.metric === comp + '.' + suffix);
    assert.equal(found.length, 1, 'unique venue metric'); return found[0];
  };
  const winRate = winSum / rows.length, possessionBase = possessionSum / (3 * rows.length),
    pointsPer100 = 100 * marginSum / rows.length / possessionBase;
  approx(metric('venue.attributable_home_win_rate').estimate, winRate, 'controlled venue win estimate');
  approx(metric('venue.points_per_100').estimate, pointsPer100, 'controlled venue points estimate');
  const failures = report.metrics.filter(m => m.verdict === 'fail');
  for (const m of report.metrics.filter(m => m.target)) assert.equal(m.verdict,
    m.estimate >= m.target.minimum && m.estimate <= m.target.maximum ? 'pass' : 'fail', 'venue target verdict');
  return {competition: comp, source_commit: report.context.commit_sha, pairs: rows.length, games: 3 * rows.length,
    seed_range: report.context.seed_range, controlled_win: metric('venue.attributable_home_win_rate'),
    controlled_cap: metric('venue.cap_respected'), paired_points_per100: metric('venue.points_per_100'),
    legacy_points_per100: metric('home.points_per_100_contribution'), failed_metrics: failures,
    note: 'Reused controlled mirror triples. Points uncertainty fixes the observed denominator; source report has no independent per-arm box aggregates for the legacy efficiency-gap calculation. No new venue simulation or certification.'};
}
function main() {
  const root = path.resolve(__dirname, '..'), out = path.join(root, 'analysis/stage4_blocker_review');
  const current = path.resolve(root, process.argv[2] || 'analysis/stage4_blocker_review/competition_current_40_each.json');
  const old = path.join(root, 'analysis/margin_growth_followup/competition_calibration_current_40_each.json');
  const sourceFiles = [current, old], reference = read(old), fresh = auditReport(read(current), reference);
  const corrected = {}, registry = new Map();
  const retain = (metric, evidence) => {
    if (!registry.has(metric)) registry.set(metric, {metric, ...classify(metric), evidence: []});
    registry.get(metric).evidence.push(evidence);
  };
  for (const m of fresh.failures) retain(m.metric, {kind: 'fresh canonical', estimate: m.estimate,
    target: m.target, sample_count: m.sample_count, interval: m.interval_95 ?? null, denominator: m.denominator});
  for (const [phase, first] of [['validation_a', 28080000], ['validation_b', 32760000]]) {
    const summaryFile = path.join(root, 'analysis/roster_pairing_followup', phase + '_summary.json'); sourceFiles.push(summaryFile);
    const summary = read(summaryFile); corrected[phase] = {};
    for (const comp of COMPS) {
      const base = `${phase}_candidate_home_${comp}`;
      const directory = path.join(root, 'analysis/roster_pairing_followup/reports');
      const rawFile = path.join(directory, `roster_raw_${base}_${comp}.json`), reportFile = path.join(directory, `competition_calibration_${base}.json`);
      sourceFiles.push(rawFile, reportFile);
      const report = read(reportFile); auditReport(report, null, [comp]);
      const cell = auditCorrectedRows(read(rawFile), report, summary.competitions[comp].cells.candidate_home, first, comp);
      corrected[phase][comp] = cell;
      for (const [name, m] of Object.entries(cell.metrics)) if (m.verdict === 'fail') retain(comp + '.' + name,
        {kind: phase + ' corrected pairing, reused evidence', games: cell.games, clusters: cell.clusters, ...m});
    }
  }
  const venue = {};
  for (const comp of COMPS) {
    const f = path.join(root, 'analysis/timing_pace_followup/reports', `home_court_diagnostics_v17_${comp}.json`);
    sourceFiles.push(f); const cell = auditVenue(read(f)); venue[comp] = cell;
    for (const m of cell.failed_metrics) retain(m.metric, {kind: 'reused v17 controlled venue report, legacy estimand',
      estimate: m.estimate, target: m.target, sample_count: m.sample_count,
      actual_legacy_points_per100: cell.legacy_points_per100.estimate,
      canonical_paired_points_per100: cell.paired_points_per100.estimate});
  }
  const result = {schema: 'leaguebound.stage4.blocker-recount/1', current: fresh, corrected, venue,
    failed_verdict_registry: [...registry.values()].sort((a, b) => a.metric.localeCompare(b.metric)),
    source_sha256: Object.fromEntries(sourceFiles.map(f => [path.relative(root, f).split(path.sep).join('/'), hash(f)])),
    limitation: 'No certification. Exact raw and canonical recount, not fresh simulation of the archived validation games. Population home-win is not the controlled §17.4 verdict. Additional missing reports/owner blockers are documented separately.'};
  fs.mkdirSync(out, {recursive: true}); fs.writeFileSync(path.join(out, 'blocker_recount.json'), JSON.stringify(result, null, 2) + '\n');
  process.stdout.write(JSON.stringify({fresh_failures: fresh.failures.length, reused_corrected_games: 4680,
    reused_venue_games: 3000, failure_union: registry.size,
    output: 'analysis/stage4_blocker_review/blocker_recount.json'}) + '\n');
}
module.exports = {aggregationEstimate, auditReport, auditCorrectedRows, classify, auditVenue};
if (require.main === module) main();
