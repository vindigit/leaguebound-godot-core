'use strict';
// Mutate only the owned report source, restore exact bytes after each case.
// Usage: node analysis/pooled_ratio_followup/run_interval_mutations.cjs <godot-console>
const fs = require('node:fs');
const path = require('node:path');
const cp = require('node:child_process');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '../..');
const source = path.join(root, 'calibration/harness/calibration_metric.gd');
const test = 'tests/calibration/test_metric_interval_endpoints.gd';
const godot = process.argv[2];
if (!godot) throw new Error('provide the Godot console executable');
const original = fs.readFileSync(source);
const sourceHash = sha(original);
const out = path.join(root, 'reports/interval_mutations');
fs.mkdirSync(out, {recursive:true});
function sha(bytes) { return crypto.createHash('sha256').update(bytes).digest('hex'); }
function plain(text) { return text.replace(/\x1b\[[0-9;]*m/g, '').replace(/\x1b\[[0-9;]*[A-Za-z]/g, ''); }
function restore() { if (sha(fs.readFileSync(source)) !== sourceHash) fs.writeFileSync(source, original); }
process.on('exit', restore);
for (const signal of ['SIGINT', 'SIGTERM']) process.on(signal, () => {restore(); process.exit(130);});
function run(id) {
  const r = cp.spawnSync(godot, ['--headless','--path',root,'-s',
    'addons/gdUnit4/bin/GdUnitCmdTool.gd','--ignoreHeadlessMode','-a',test,'-c'],
    {cwd:root, encoding:'utf8', windowsHide:true, timeout:120000});
  if (r.error) throw r.error;
  const log = (r.stdout || '') + (r.stderr || '');
  fs.writeFileSync(path.join(out, id+'.log'), log);
  const p = plain(log);
  assertValid(p, id);
  return {id, exit_code:r.status, log_sha256:sha(log), text:p};
}
function assertValid(log, id) {
  if (/SCRIPT ERROR|Parse Error|No test cases found|Abnormal exit/.test(log) ||
      !/Overall Summary: 8 test cases \| 0 errors \|/.test(log))
    throw new Error(id+' did not execute all eight tests cleanly');
}
function clean(id) {
  const r = run(id);
  if (r.exit_code !== 0 || !/Overall Summary: 8 test cases \| 0 errors \| 0 failures/.test(r.text))
    throw new Error(id+' clean suite failed');
  return {id:r.id, exit_code:r.exit_code, log_sha256:r.log_sha256};
}
const mutants = [
  {id:'wilson_low_centered', from:'interval_low = bounds[0]', to:'interval_low = estimate - half_width',
    intended:'test_wilson_endpoints_survive_serialization', allowed:['test_wilson_endpoints_survive_serialization','test_known_wilson_endpoints_survive_json_and_console_rendering','test_one_trial_has_a_bounded_interval']},
  {id:'wilson_high_centered', from:'interval_high = bounds[1]', to:'interval_high = estimate + half_width',
    intended:'test_wilson_endpoints_survive_serialization', allowed:['test_wilson_endpoints_survive_serialization','test_known_wilson_endpoints_survive_json_and_console_rendering','test_one_trial_has_a_bounded_interval']},
  {id:'console_recenters', from:'text += " [%.4f, %.4f]" % [interval_low, interval_high]',
    to:'text += " ±%.4f" % interval_half_width',
    intended:'test_known_wilson_endpoints_survive_json_and_console_rendering', allowed:['test_known_wilson_endpoints_survive_json_and_console_rendering']},
  {id:'stale_width', from:'\tinterval_high = NAN\n\tinterval_half_width = half_width\n\tif half_width >= 0.0:',
    to:'\tinterval_high = NAN\n\tif half_width >= 0.0:\n\t\tinterval_half_width = half_width\n\tif half_width >= 0.0:',
    intended:'test_replacing_aggregation_clears_unavailable_interval', allowed:['test_replacing_aggregation_clears_unavailable_interval']},
  {id:'override_keeps_low', from:'func with_interval(half_width: float) -> CalibrationMetric:\n\tinterval_half_width = half_width\n\tinterval_low = NAN',
    to:'func with_interval(half_width: float) -> CalibrationMetric:\n\tinterval_half_width = half_width\n\tpass',
    intended:'test_explicit_interval_override_stays_centered_on_estimate', allowed:['test_explicit_interval_override_stays_centered_on_estimate']},
  {id:'drop_archived_endpoints', from:'\t\tmetric.interval_low = JsonRead.optional_float_at(interval, "low")\n\t\tmetric.interval_high = JsonRead.optional_float_at(interval, "high")',
    to:'\t\tpass', intended:'test_wilson_endpoints_survive_serialization',
    allowed:['test_wilson_endpoints_survive_serialization','test_known_wilson_endpoints_survive_json_and_console_rendering']},
  {id:'drop_explicit_low', from:'\tinterval_low = low\n\tinterval_high = high',
    to:'\tinterval_low = NAN\n\tinterval_high = high',
    intended:'test_explicit_bounds_keep_banded_estimate_and_verdict', allowed:['test_explicit_bounds_keep_banded_estimate_and_verdict']},
];
const results = [clean('before')];
for (const m of mutants) {
  const sourceText = original.toString('utf8');
  if (sourceText.split(m.from).length !== 2) throw new Error(m.id+' mutation is not unique');
  try {
    fs.writeFileSync(source, sourceText.replace(m.from, m.to));
    const r = run(m.id);
    const failed = [...r.text.matchAll(/> (test_[a-z0-9_]+) FAILED/g)].map(x => x[1]);
    if (r.exit_code !== 100 || !failed.includes(m.intended) ||
        failed.some(name => !m.allowed.includes(name)))
      throw new Error(m.id+' did not fail only the intended semantic tests: '+failed.join(','));
    results.push({id:m.id, exit_code:r.exit_code, intended:m.intended,
      failed_tests:failed, log_sha256:r.log_sha256});
  } finally { restore(); }
  if (sha(fs.readFileSync(source)) !== sourceHash) throw new Error('source bytes not restored');
  results.push(clean('after_'+m.id));
}
const proof = {source_sha256:sourceHash, test_sha256:sha(fs.readFileSync(path.join(root,test))),
  driver_sha256:sha(fs.readFileSync(__filename)), node_version:process.version,
  godot, mutants:mutants.length, results};
fs.writeFileSync(path.join(__dirname,'interval_mutations.json'), JSON.stringify(proof,null,2)+'\n');
console.log(JSON.stringify({mutants:mutants.length, source_restored:true, results:results.length}));
