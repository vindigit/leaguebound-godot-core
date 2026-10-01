'use strict';
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const cp = require('node:child_process');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '..'), isolated = fs.mkdtempSync(path.join(os.tmpdir(), 'leaguebound-blocker-audit-'));
const relative = 'tools/stage4_blocker_audit.cjs', testFile = 'tests/tooling/test_stage4_blocker_audit.cjs';
for (const f of [relative, testFile]) {fs.mkdirSync(path.dirname(path.join(isolated, f)), {recursive: true}); fs.copyFileSync(path.join(root, f), path.join(isolated, f));}
const output = path.resolve(root, process.argv[2] || 'analysis/stage4_blocker_review/mutations_v3'); fs.mkdirSync(output, {recursive: true});
const original = fs.readFileSync(path.join(isolated, relative));
const hash = b => crypto.createHash('sha256').update(b).digest('hex');
const mutants = [
  ['denominator_guard', "assert.ok(Number.isFinite(a.denominator) && a.denominator > 0, 'positive finite denominator');", '', 'invalid denominator is rejected'],
  ['duplicate_metric', "assert.ok(!seen.has(m.metric), 'unique metric ids');", 'if (seen.has(m.metric)) continue;', 'duplicate metrics are rejected'],
  ['verdict_guard', "assert.equal(m.verdict, verdict, 'canonical verdict matches unchanged target');", '', 'changed verdict is rejected for its target'],
  ['target_guard', "assert.deepEqual(m.target, refs.get(m.metric).target, 'locked target unchanged');", '', 'changed target is rejected against the reference'],
  ['duplicate_seed', "assert.ok(!seen.has(r.seed), 'duplicate seeds rejected');", 'if (seen.has(r.seed)) continue;', 'duplicate seeds are rejected'],
  ['opener_guard', "assert.equal(r.opening_home, r.variation % 2 === 0, 'balanced opener');", '', 'broken opener and roster pairings are rejected'],
  ['ratio_scale', 'return (a.scale ?? 1) * a.numerator / a.denominator;', 'return a.numerator / a.denominator;', 'raw totals use weighted denominator, never a mean of rates'],
  ['venue_sign', 'marginSum += 0.5 * (r.home_margin + r.reversed_margin);', 'marginSum += 0.5 * (r.home_margin - r.reversed_margin);', 'venue uses symmetrized triples and rejects duplicates'],
  ['venue_duplicate', "assert.ok(!seen.has(r.fixture), 'unique venue fixture');", '', 'venue uses symmetrized triples and rejects duplicates'],
  ['Wilson_center', 'const center = (p + z2 / (2 * trials)) / divisor;', 'const center = p;', 'probability reproducer preserves actual and correct Wilson endpoints']
];
function run(id) {
  const r = cp.spawnSync(process.execPath, ['--test', '--test-reporter=tap', testFile], {cwd: isolated, encoding: 'utf8', windowsHide: true, timeout: 30000});
  if (r.error) throw r.error;
  const log = (r.stdout || '') + (r.stderr || ''); fs.writeFileSync(path.join(output, id + '.log'), log);
  if (/SyntaxError|MODULE_NOT_FOUND/.test(log) || !/# tests 13\b/.test(log)) throw new Error(id + ' invalid execution');
  return {id, exit_code: r.status, log, log_sha256: hash(log),
    log_path: path.relative(root, path.join(output, id + '.log')).replaceAll('\\', '/')};
}
const before = run('before'); if (before.exit_code !== 0 || !/# fail 0\b/.test(before.log)) throw new Error('baseline not green');
const results = [];
for (const [id, needle, replacement, intended] of mutants) {
  const text = original.toString('utf8'); if (text.split(needle).length !== 2) throw new Error(id + ' nonunique mutation');
  try {
    fs.writeFileSync(path.join(isolated, relative), text.replace(needle, replacement));
    const r = run(id);
    if (/The input did not match the regular expression/.test(r.log)) throw new Error(id + ' message-only failure rejected');
    if (r.exit_code !== 1 || !r.log.split('\n').some(line => line.startsWith('not ok ') && line.includes(intended))
      || !/ERR_ASSERTION/.test(r.log)) throw new Error(id + ' not an intended assertion kill');
    results.push({id, intended_test: intended, needle, replacement, exit_code: r.exit_code, killed: true,
      log_path: r.log_path, log_sha256: r.log_sha256});
  } finally {fs.writeFileSync(path.join(isolated, relative), original);}
}
const after = run('after'); if (after.exit_code !== 0 || hash(fs.readFileSync(path.join(isolated, relative))) !== hash(original)
  || hash(fs.readFileSync(path.join(root, relative))) !== hash(original)) throw new Error('restoration/baseline failed');
fs.writeFileSync(path.join(output, 'results.json'), JSON.stringify({source_sha256: hash(original),
  test_source_sha256: hash(fs.readFileSync(path.join(root, testFile))),
  driver_sha256: hash(fs.readFileSync(__filename)), node_version: process.version,
  clean_before: before.exit_code, clean_after: after.exit_code,
  clean_before_log_sha256: before.log_sha256, clean_after_log_sha256: after.log_sha256,
  killed: results.length, results}, null, 2) + '\n');
process.stdout.write(JSON.stringify({killed: results.length, output}) + '\n');
