'use strict';
// Validate the runner's real judged and informational share paths.
// Usage: node check_margin_report.cjs population.json mirror.json
const fs = require('node:fs');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
const names = ['shape.blowout_rate', 'shape.close_game_rate',
  'shape.overtime_rate', 'shape.home_win_rate'];
const z = 1.959964;
function wilson(k, n) {
  const p = k / n, d = 1 + z*z/n;
  const center = (p + z*z/(2*n))/d;
  const width = z*Math.sqrt(p*(1-p)/n + z*z/(4*n*n))/d;
  return [Math.max(0, center-width), Math.min(1, center+width)];
}
function check(file, judged) {
  const bytes = fs.readFileSync(file);
  const report = JSON.parse(bytes);
  const rows = names.map(name => {
    const matches = report.metrics.filter(row => row.metric === name);
    assert.equal(matches.length, 1, `unique metric ${name}`);
    const row = matches[0], n = row.sample_count;
    assert.equal(n, 2, `probe sample for ${name}`);
    const k = Math.round(row.estimate*n);
    assert.ok(Math.abs(row.estimate-k/n) < 1e-12, `count ratio ${name}`);
    const [low, high] = wilson(k, n), ci = row.interval_95;
    assert.ok(Math.abs(ci.low-low)<1e-12, `lower endpoint ${name}`);
    assert.ok(Math.abs(ci.high-high)<1e-12, `upper endpoint ${name}`);
    assert.ok(Math.abs(ci.half_width-(high-low)/2)<1e-12, `width ${name}`);
    if (judged) {
      assert.ok(row.target, `target ${name}`);
      assert.equal(row.verdict, row.estimate >= row.target.minimum &&
        row.estimate <= row.target.maximum ? 'pass' : 'fail', `verdict ${name}`);
    } else assert.equal(row.verdict, 'informational', `informational ${name}`);
    return {metric:name, successes:k, trials:n, estimate:row.estimate,
      verdict:row.verdict, low:ci.low, high:ci.high};
  });
  return {file, sha256:crypto.createHash('sha256').update(bytes).digest('hex'), rows};
}
assert.equal(process.argv.length, 4, 'provide population and mirror report paths');
console.log(JSON.stringify({population:check(process.argv[2], true),
  mirror:check(process.argv[3], false)}, null, 2));
