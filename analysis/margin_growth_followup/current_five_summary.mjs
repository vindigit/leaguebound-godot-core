import fs from 'node:fs';
const report=JSON.parse(fs.readFileSync('analysis/margin_growth_followup/competition_calibration_current_40_each.json'));
const fail=report.metrics.filter(m=>m.verdict==='fail').map(m=>({metric:m.metric,estimate:m.estimate}));
console.log(JSON.stringify({sample_count:report.context.sample_count,summary:report.summary,fail,sections:Object.keys(report.sections)},null,2));
