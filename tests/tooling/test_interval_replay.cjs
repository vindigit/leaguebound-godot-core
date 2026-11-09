'use strict';
const test = require('node:test'), assert = require('node:assert/strict');
const fs = require('node:fs'), path = require('node:path'), cp = require('node:child_process');
const root = path.resolve(__dirname,'../..');
const checker = process.env.LEAGUEBOUND_REPLAY_CHECKER || path.join(root,'analysis/pooled_ratio_followup/check_competition_replay.cjs');
const out = path.join(root,'reports','interval_replay_tests_'+process.pid+'_'+Date.now());
fs.mkdirSync(out,{recursive:true});
const z=1.959964, hi=z*z/(40+z*z), half=hi/2;
function fixtures() {
  const overtime={metric:'high_school.overtime_rate',estimate:0,sample_count:40,verdict:'fail',
    aggregation:{kind:'proportion',numerator:0,denominator:40},
    interval_95:{half_width:half,low:-half,high:half}};
  const fg={metric:'high_school.field_goal_percentage',estimate:0.4,sample_count:40,verdict:'fail',
    aggregation:{kind:'proportion',numerator:16,denominator:40},
    interval_95:{half_width:0.06,low:0.34,high:0.46}};
  const rows=[overtime,fg,...Array.from({length:96},(_,i)=>({metric:'fixture.'+i,estimate:i,verdict:'informational'}))];
  const context={report_id:'competition_calibration',commit_sha:'a'.repeat(40),godot_version:'4.7.1-stable (official)',
    build_mode:'editor-debug (asserts active)',rules_profile:{id:'high_school',version:'competition-v2-stopped-clock-pace'},
    balance_profile:{id:'simulation_baseline',version:'simulation-v17-stopped-foul-clock-and-live-rebound'},
    ratings_profile_version:'ratings-v1',targets_version:'calibration-targets-v1',
    rng:{algorithm:'godot-pcg32-v1',stream_key_version:'sha256-stream-key-v1'},
    seed_range:{start:1,end:40},shard:{index:0,count:1},sample_count:200,
    sample_unit:'complete games per competition',competition:''};
  const old={schema:'leaguebound.calibration.report/1',context,metrics:rows,
    summary:{passed:false,metric_count:98,judged_metric_count:74,failure_count:9},
    sections:{competition_table:['high_school','college','development','overseas','top_domestic_pro'].map(competition=>({competition,games:40}))}};
  const current=JSON.parse(JSON.stringify(old));
  current.metrics[0].interval_95={half_width:half,low:0,high:hi};
  return {old,current};
}
let next=0;
function check(old,current) {
  const id=next++, a=path.join(out,id+'a.json'), b=path.join(out,id+'b.json');
  fs.writeFileSync(a,JSON.stringify(old)); fs.writeFileSync(b,JSON.stringify(current));
  const r=cp.spawnSync(process.execPath,[checker,a,b],{cwd:root,encoding:'utf8',timeout:30000});
  if (r.error) throw r.error;
  return r;
}
function rejected(r,reason) {
  assert.equal(r.status,1,'corruption must fail');
  assert.match(r.stderr,/AssertionError \[ERR_ASSERTION\]/);
  assert.match(r.stderr,reason);
  assert.doesNotMatch(r.stderr,/TypeError|ReferenceError|SyntaxError|MODULE_NOT_FOUND/);
}
test('valid known-answer replay is accepted',()=>{
  const {old,current}=fixtures(), r=check(old,current);
  assert.equal(r.status,0,r.stderr);
  const output=JSON.parse(r.stdout);
  assert.equal(output.wilson_intervals_checked,1);
  assert.equal(output.wilson_intervals_with_shifted_endpoints,1);
  assert.equal(output.other_intervals_preserved,1);
  assert.match(output.limitation,/HEAD only/);
});
test('changed point metric is rejected',()=>{
  const {old,current}=fixtures(); current.metrics[0].estimate=0.025;
  rejected(check(old,current),/point metric and aggregation/);
});
test('incorrect Wilson endpoint is rejected',()=>{
  const {old,current}=fixtures(); current.metrics[0].interval_95.low=0.01;
  rejected(check(old,current),/new lower endpoint/);
});
test('changed FG ratio override is rejected',()=>{
  const {old,current}=fixtures(); current.metrics[1].interval_95.high=0.47;
  rejected(check(old,current),/non-Wilson interval/);
});
test('duplicate metric is rejected',()=>{
  const {old,current}=fixtures(); current.metrics[2]=JSON.parse(JSON.stringify(current.metrics[1]));
  rejected(check(old,current),/unique current metrics/);
});
test('unchanged erroneous endpoint is rejected',()=>{
  const {old,current}=fixtures(); current.metrics[0].interval_95=old.metrics[0].interval_95;
  rejected(check(old,current),/new lower endpoint/);
});
test('altered competition section is rejected',()=>{
  const {old,current}=fixtures(); current.sections.competition_table[0].sample_label='changed';
  rejected(check(old,current),/competition and role sections/);
});
test('coherently changed game counts are rejected',()=>{
  const {old,current}=fixtures();
  old.sections.competition_table[0].games=39;
  current.sections.competition_table[0].games=39;
  rejected(check(old,current),/games per competition/);
});
test('shifted current seed range is rejected',()=>{
  const {old,current}=fixtures(); current.context.seed_range={start:1001,end:1040};
  rejected(check(old,current),/current seed range/);
});
test('coherently shifted seed ranges are rejected',()=>{
  const {old,current}=fixtures(); old.context.seed_range={start:1001,end:1040};
  current.context.seed_range={start:1001,end:1040};
  rejected(check(old,current),/historical seed range/);
});
test('coherently duplicated competition identities are rejected',()=>{
  const {old,current}=fixtures();
  old.sections.competition_table[1].competition='high_school';
  current.sections.competition_table[1].competition='high_school';
  rejected(check(old,current),/competition identities/);
});
test('coherently changed rules versions are rejected',()=>{
  const {old,current}=fixtures(); old.context.rules_profile.version='changed';
  current.context.rules_profile.version='changed';
  rejected(check(old,current),/historical rules profile/);
});
test('missing context is rejected as an assertion',()=>{
  const {old,current}=fixtures(); delete current.context;
  rejected(check(old,current),/current context/);
});
test('changed RNG version is rejected',()=>{
  const {old,current}=fixtures(); current.context.rng.stream_key_version='changed';
  rejected(check(old,current),/current RNG version/);
});
test('unverifiable commit identifier is rejected',()=>{
  const {old,current}=fixtures(); current.context.commit_sha='unknown';
  rejected(check(old,current),/current commit identifier/);
  delete current.context.commit_sha;
  rejected(check(old,current),/current commit identifier/);
});
