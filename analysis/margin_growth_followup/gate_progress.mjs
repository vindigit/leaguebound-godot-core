import fs from 'node:fs';
const text=fs.readFileSync('analysis/margin_growth_followup/full_gate.log','utf8').replace(/\x1b\[[0-9;]*m/g,'');
const lines=text.split(/\r?\n/);
console.log(JSON.stringify({
  steps:lines.filter(x=>x.startsWith('=== ')),
  suites:lines.filter(x=>x.startsWith('Run Test Suite:')).length,
  cases_passed:lines.filter(x=>x.includes(' > ')&&x.includes(' PASSED ')).length,
  cases_failed:lines.filter(x=>x.includes(' > ')&&x.includes(' FAILED ')).length,
  last:lines.slice(-6),
},null,2));
