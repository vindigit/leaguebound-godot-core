'use strict';
// Compare the same five-competition, 40-game seed prefix before and after
// the reporting correction. This is not an untouched validation sample.
// Usage: node check_competition_replay.cjs <historical.json> <current.json>
const fs = require('node:fs'), assert = require('node:assert/strict');
const crypto = require('node:crypto');
assert.equal(process.argv.length, 4, 'provide historical and current reports');
function read(file) {
  const bytes = fs.readFileSync(file);
  return {data:JSON.parse(bytes), sha256:crypto.createHash('sha256').update(bytes).digest('hex')};
}
function close(a,b,message) { assert.ok(Math.abs(a-b)<1e-11,message+`: ${a} vs ${b}`); }
function wilson(k,n) {
  const z=1.959964, p=k/n, d=1+z*z/n;
  const center=(p+z*z/(2*n))/d;
  const width=z*Math.sqrt(p*(1-p)/n+z*z/(4*n*n))/d;
  return [Math.max(0,center-width), Math.min(1,center+width)];
}
const historical=read(process.argv[2]), current=read(process.argv[3]);
const a=historical.data, b=current.data;
for (const [label,report] of [['historical',a],['current',b]]) {
  assert.equal(report.schema,'leaguebound.calibration.report/1',label+' schema');
  const c=report.context;
  assert.ok(c && typeof c === 'object' && !Array.isArray(c),label+' context');
  assert.ok(typeof c.commit_sha === 'string' && /^[0-9a-f]{40}$/.test(c.commit_sha),label+' commit identifier');
  assert.equal(c.report_id,'competition_calibration',label+' report identity');
  assert.equal(c.godot_version,'4.7.1-stable (official)',label+' Godot version');
  assert.equal(c.build_mode,'editor-debug (asserts active)',label+' build mode');
  assert.deepEqual(c.rules_profile,{id:'high_school',version:'competition-v2-stopped-clock-pace'},label+' rules profile');
  assert.deepEqual(c.balance_profile,{id:'simulation_baseline',version:'simulation-v17-stopped-foul-clock-and-live-rebound'},label+' balance profile');
  assert.equal(c.ratings_profile_version,'ratings-v1',label+' ratings version');
  assert.equal(c.targets_version,'calibration-targets-v1',label+' targets version');
  assert.deepEqual(c.rng,{algorithm:'godot-pcg32-v1',stream_key_version:'sha256-stream-key-v1'},label+' RNG version');
  assert.deepEqual(c.seed_range,{start:1,end:40},label+' seed range');
  assert.deepEqual(c.shard,{index:0,count:1},label+' shard identity');
  assert.equal(c.sample_count,200,label+' total sample');
  assert.equal(c.sample_unit,'complete games per competition',label+' sample unit');
  assert.equal(c.competition,'',label+' all-competition scope');
}
assert.equal(a.metrics.length,98); assert.equal(b.metrics.length,98);
assert.deepEqual(b.summary,a.summary,'judgment summary');
assert.equal(b.summary.failure_count,9,'historical failure count');
assert.deepEqual(b.sections,a.sections,'competition and role sections');
assert.equal(b.sections.competition_table.length,5,'competition coverage');
assert.deepEqual(b.sections.competition_table.map(row=>row.competition).sort(),
  ['college','development','high_school','overseas','top_domestic_pro'], 'competition identities');
for (const row of b.sections.competition_table) assert.equal(row.games,40,'games per competition');
const old = new Map(a.metrics.map(row=>[row.metric,row]));
assert.equal(old.size,98,'unique historical metrics');
assert.equal(new Set(b.metrics.map(row=>row.metric)).size,98,'unique current metrics');
let wilsonCount=0, preservedIntervals=0, shiftedEndpoints=0;
const corrected=[];
for (const row of b.metrics) {
  const before=old.get(row.metric);
  assert.ok(before,'metric coverage: '+row.metric);
  const nowCore={...row}, oldCore={...before};
  delete nowCore.interval_95; delete oldCore.interval_95;
  assert.deepEqual(nowCore,oldCore,'point metric and aggregation: '+row.metric);
  assert.equal(Boolean(row.interval_95),Boolean(before.interval_95),'interval presence: '+row.metric);
  if (!row.interval_95) continue;
  const isWilson=row.aggregation?.kind === 'proportion' && !row.metric.endsWith('.field_goal_percentage');
  if (!isWilson) {
    assert.deepEqual(row.interval_95,before.interval_95,'non-Wilson interval: '+row.metric);
    preservedIntervals++;
    continue;
  }
  const n=row.aggregation.denominator, k=row.aggregation.numerator;
  assert.ok(n>0 && Number.isInteger(n) && Number.isInteger(k) && k>=0 && k<=n,'valid counts');
  const [low,high]=wilson(k,n);
  close(row.interval_95.low,low,'new lower endpoint '+row.metric);
  close(row.interval_95.high,high,'new upper endpoint '+row.metric);
  close(row.interval_95.half_width,(high-low)/2,'new half-width '+row.metric);
  close(before.interval_95.half_width,row.interval_95.half_width,'unchanged width '+row.metric);
  close(before.interval_95.low,before.estimate-before.interval_95.half_width,'historical low '+row.metric);
  close(before.interval_95.high,before.estimate+before.interval_95.half_width,'historical high '+row.metric);
  if (Math.abs(row.interval_95.low-before.interval_95.low)>1e-11) shiftedEndpoints++;
  corrected.push({metric:row.metric,successes:k,trials:n,estimate:row.estimate,
    old_low:before.interval_95.low,old_high:before.interval_95.high,low,high});
  wilsonCount++;
}
assert.ok(wilsonCount>0 && shiftedEndpoints>0,'must exercise asymmetric correction');
console.log(JSON.stringify({historical_sha256:historical.sha256,current_sha256:current.sha256,
  historical_head:a.context.commit_sha,current_head:b.context.commit_sha,
  same_declared_seed_prefix:true, games:200, games_per_competition:40, metrics:98, failures:9,
  limitation:'Metadata and equal outcomes do not independently prove individual game seeds or event ledgers. Commit identifiers name HEAD only and do not establish working-tree cleanliness; use separate source fingerprints.',
  point_metrics_and_sections_identical:true, wilson_intervals_checked:wilsonCount,
  wilson_intervals_with_shifted_endpoints:shiftedEndpoints, other_intervals_preserved:preservedIntervals,
  corrected},null,2));
