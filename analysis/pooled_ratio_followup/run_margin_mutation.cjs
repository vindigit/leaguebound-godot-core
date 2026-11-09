'use strict';
// Reproduce the old margin _share endpoint loss on both real runner paths.
// Usage: node analysis/pooled_ratio_followup/run_margin_mutation.cjs <godot-console>
const fs = require('node:fs'), path = require('node:path');
const cp = require('node:child_process'), crypto = require('node:crypto');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const source = path.join(root, 'calibration/runners/run_margin_covariance.gd');
const checker = path.join(__dirname, 'check_margin_report.cjs');
const godot = process.argv[2];
if (!godot) throw new Error('provide Godot console executable');
const original = fs.readFileSync(source);
const hash = b => crypto.createHash('sha256').update(b).digest('hex');
const originalHash = hash(original), prefix = 'interval_mutation_' + Date.now();
const out = path.join(root, 'reports/interval_margin_mutations');
fs.mkdirSync(out, {recursive:true});
function restore() { if (hash(fs.readFileSync(source)) !== originalHash) fs.writeFileSync(source, original); }
process.on('exit', restore);
for (const signal of ['SIGINT','SIGTERM']) process.on(signal, () => {restore(); process.exit(130);});
function run(mode, phase) {
  const label = prefix+'_'+phase+'_'+mode;
  const r = cp.spawnSync(godot, ['--headless','--path',root,'--script',
    'res://calibration/runners/run_margin_covariance.gd','--','--games=2',
    '--competition=high_school','--mode='+mode,'--label='+label],
    {cwd:root, encoding:'utf8', windowsHide:true, timeout:180000});
  if (r.error) throw r.error;
  const log = (r.stdout || '') + (r.stderr || '');
  fs.writeFileSync(path.join(out, phase+'_'+mode+'.log'), log);
  assert.ok(!/SCRIPT ERROR|Parse Error|Abnormal exit/.test(log), phase+' '+mode+' runtime error');
  assert.equal(r.status, mode === 'population' ? 1 : 0, phase+' '+mode+' expected verdict exit');
  const file = path.join(root,'reports','margin_covariance_'+label+'.json');
  const bytes = fs.readFileSync(file);
  const payload = JSON.parse(bytes);
  assert.equal(payload.metrics.length,151, phase+' complete metric coverage');
  return {file, payload, sha256:hash(bytes), log_sha256:hash(log), exit_code:r.status};
}
function runChecker(pop, mirror, id, shouldPass) {
  const r = cp.spawnSync(process.execPath,[checker,pop.file,mirror.file],
    {cwd:root, encoding:'utf8', windowsHide:true, timeout:30000});
  if (r.error) throw r.error;
  const log = (r.stdout || '') + (r.stderr || '');
  fs.writeFileSync(path.join(out,id+'.log'),log);
  if (shouldPass) assert.equal(r.status,0,id+' must pass');
  else {
    assert.equal(r.status,1,id+' must fail');
    assert.match(log,/AssertionError \[ERR_ASSERTION\]: (lower|upper) endpoint shape\./,
      id+' must fail an endpoint assertion');
    assert.doesNotMatch(log,/TypeError|ReferenceError|SyntaxError|MODULE_NOT_FOUND/);
  }
  return {id, exit_code:r.status, log_sha256:hash(log)};
}
function signatures(report) {
  return report.payload.metrics.map(({metric, estimate, sample_count, verdict, target, aggregation}) =>
    ({metric, estimate, sample_count, verdict, target, aggregation}));
}
const cleanPop = {file:path.join(root,'reports/margin_covariance_interval_probe_population.json')};
const cleanMirror = {file:path.join(root,'reports/margin_covariance_interval_probe_mirror.json')};
for (const r of [cleanPop,cleanMirror]) r.payload=JSON.parse(fs.readFileSync(r.file));
const before = runChecker(cleanPop,cleanMirror,'before',true);
const from = '.with_interval_bounds(interval[0], interval[1])';
const to = '.with_interval((interval[1] - interval[0]) / 2.0)';
assert.equal(original.toString('utf8').split(from).length,3,'two runner paths must be mutated');
let mutantPop, mutantMirror;
try {
  fs.writeFileSync(source,original.toString('utf8').replaceAll(from,to));
  mutantPop=run('population','mutant');
  mutantMirror=run('mirror','mutant');
} finally {restore();}
assert.equal(hash(fs.readFileSync(source)), originalHash, 'runner bytes restored');
assert.deepEqual(signatures(mutantPop), signatures(cleanPop), 'judged point metrics unchanged');
assert.deepEqual(signatures(mutantMirror), signatures(cleanMirror), 'informational point metrics unchanged');
const populationKill=runChecker(mutantPop,cleanMirror,'population_mutant',false);
const mirrorKill=runChecker(cleanPop,mutantMirror,'mirror_mutant',false);
const afterPop=run('population','after'), afterMirror=run('mirror','after');
assert.deepEqual(signatures(afterPop),signatures(cleanPop),'judged deterministic replay');
assert.deepEqual(signatures(afterMirror),signatures(cleanMirror),'informational deterministic replay');
const after=runChecker(afterPop,afterMirror,'after',true);
const proof={source_sha256:originalHash, checker_sha256:hash(fs.readFileSync(checker)),
  driver_sha256:hash(fs.readFileSync(__filename)), godot, node_version:process.version,
  mutation:'restore centered half-width serialization in both _share branches',
  preserved_point_metrics:151, source_restored:true,
  runs:{mutant_population:{sha256:mutantPop.sha256,log_sha256:mutantPop.log_sha256,exit_code:mutantPop.exit_code},
    mutant_mirror:{sha256:mutantMirror.sha256,log_sha256:mutantMirror.log_sha256,exit_code:mutantMirror.exit_code},
    after_population:{sha256:afterPop.sha256,log_sha256:afterPop.log_sha256,exit_code:afterPop.exit_code},
    after_mirror:{sha256:afterMirror.sha256,log_sha256:afterMirror.log_sha256,exit_code:afterMirror.exit_code}},
  checks:[before,populationKill,mirrorKill,after]};
fs.writeFileSync(path.join(__dirname,'margin_runner_mutation.json'),JSON.stringify(proof,null,2)+'\n');
console.log(JSON.stringify({runner_paths:2, intended_endpoint_kills:2,source_restored:true}));
