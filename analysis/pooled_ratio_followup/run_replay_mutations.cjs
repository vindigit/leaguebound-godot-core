'use strict';
// Mutate isolated copies of the real replay comparator; never modify it.
// Usage: node analysis/pooled_ratio_followup/run_replay_mutations.cjs
const fs=require('node:fs'), path=require('node:path'), cp=require('node:child_process');
const crypto=require('node:crypto'), assert=require('node:assert/strict');
const root=path.resolve(__dirname,'../..');
const source=path.join(__dirname,'check_competition_replay.cjs');
const test='tests/tooling/test_interval_replay.cjs';
const out=path.join(root,'reports','interval_replay_mutations_'+process.pid+'_'+Date.now());
fs.mkdirSync(out,{recursive:true});
const original=fs.readFileSync(source), hash=b=>crypto.createHash('sha256').update(b).digest('hex');
const sourceHash=hash(original);
const mutants=[
  {id:'point_guard',from:"assert.deepEqual(nowCore,oldCore,'point metric and aggregation: '+row.metric);",to:'void 0;',test:'changed point metric is rejected'},
  {id:'wilson_low_guard',from:"close(row.interval_95.low,low,'new lower endpoint '+row.metric);",to:'void 0;',test:'incorrect Wilson endpoint is rejected'},
  {id:'fg_override_guard',from:"assert.deepEqual(row.interval_95,before.interval_95,'non-Wilson interval: '+row.metric);",to:'void 0;',test:'changed FG ratio override is rejected'},
  {id:'unique_current_guard',from:"assert.equal(new Set(b.metrics.map(row=>row.metric)).size,98,'unique current metrics');",to:'void 0;',test:'duplicate metric is rejected'},
  {id:'section_guard',from:"assert.deepEqual(b.sections,a.sections,'competition and role sections');",to:'void 0;',test:'altered competition section is rejected'},
  {id:'games_guard',from:"assert.equal(row.games,40,'games per competition');",to:'void 0;',test:'coherently changed game counts are rejected'},
  {id:'seed_guard',from:"assert.deepEqual(c.seed_range,{start:1,end:40},label+' seed range');",to:'void 0;',test:'coherently shifted seed ranges are rejected'},
  {id:'competition_guard',from:"assert.deepEqual(b.sections.competition_table.map(row=>row.competition).sort(),\n  ['college','development','high_school','overseas','top_domestic_pro'], 'competition identities');",to:'void 0;',test:'coherently duplicated competition identities are rejected'},
  {id:'rules_guard',from:"assert.deepEqual(c.rules_profile,{id:'high_school',version:'competition-v2-stopped-clock-pace'},label+' rules profile');",to:'void 0;',test:'coherently changed rules versions are rejected'},
  {id:'rng_guard',from:"assert.deepEqual(c.rng,{algorithm:'godot-pcg32-v1',stream_key_version:'sha256-stream-key-v1'},label+' RNG version');",to:'void 0;',test:'changed RNG version is rejected'},
  {id:'commit_guard',from:"assert.ok(typeof c.commit_sha === 'string' && /^[0-9a-f]{40}$/.test(c.commit_sha),label+' commit identifier');",to:'void 0;',test:'unverifiable commit identifier is rejected'},
];
function execute(id,checker,pattern) {
  const args=['--test','--test-reporter=tap'];
  if (pattern) args.push('--test-name-pattern',pattern);
  args.push(test);
  const env={...process.env};
  if (checker) env.LEAGUEBOUND_REPLAY_CHECKER=checker; else delete env.LEAGUEBOUND_REPLAY_CHECKER;
  const r=cp.spawnSync(process.execPath,args,{cwd:root,encoding:'utf8',env,timeout:60000});
  if (r.error) throw r.error;
  const log=(r.stdout||'')+(r.stderr||'');
  fs.writeFileSync(path.join(out,id+'.log'),log);
  assert.match(log,pattern ? /# tests 1\b/ : /# tests 15\b/,id+' test coverage');
  assert.doesNotMatch(log,/SyntaxError|ReferenceError|TypeError|MODULE_NOT_FOUND|The input did not match/,
    id+' must not fail by crash or unrelated regex mismatch');
  return {id,exit_code:r.status,log_sha256:hash(log),log};
}
function clean(id) {
  const r=execute(id,null,null);
  assert.equal(r.exit_code,0,id+' clean suite'); assert.match(r.log,/# pass 15\b/);
  return {id:r.id,exit_code:r.exit_code,log_sha256:r.log_sha256};
}
const results=[clean('before')];
for (const m of mutants) {
  const text=original.toString('utf8');
  assert.equal(text.split(m.from).length,2,m.id+' unique mutation');
  const file=path.join(out,m.id+'.cjs');
  fs.writeFileSync(file,text.replace(m.from,m.to));
  const r=execute(m.id,file,m.test);
  assert.equal(r.exit_code,1,m.id+' mutant must fail');
  assert.ok(r.log.split('\n').some(line=>line.startsWith('not ok ') && line.includes(m.test)),m.id+' intended test');
  assert.match(r.log,/corruption must fail/,m.id+' semantic reason');
  assert.match(r.log,/# fail 1\b/,m.id+' one intended failure');
  results.push({id:m.id,exit_code:r.exit_code,intended_test:m.test,log_sha256:r.log_sha256});
  assert.equal(hash(fs.readFileSync(source)),sourceHash,'original comparator unchanged');
  results.push(clean('after_'+m.id));
}
const proof={source_sha256:sourceHash,test_sha256:hash(fs.readFileSync(path.join(root,test))),
  driver_sha256:hash(fs.readFileSync(__filename)),node_version:process.version,
  log_directory:path.relative(root,out).replaceAll('\\','/'),
  isolated_copies:true,mutants:mutants.length,results};
fs.writeFileSync(path.join(__dirname,'replay_mutations.json'),JSON.stringify(proof,null,2)+'\n');
console.log(JSON.stringify({mutants:mutants.length,original_unchanged:true,results:results.length}));
