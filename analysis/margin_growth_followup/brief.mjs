import fs from 'node:fs';
const s = JSON.parse(fs.readFileSync('analysis/margin_growth_followup/summary.json','utf8'));
for (const range of ['range_a','range_b']) for (const competition of ['college','top_domestic_pro']) {
  console.log(`\n${range} ${competition}`);
  for (const arm of ['ordinary_ab','identical_aa','reversed_ba']) for (const env of [0,0.5]) {
    const r = s.cells[`${range}/${competition}/${arm}/${env}`];
    console.log(`${arm} env${env} n${r.n} close${r.close_n} blow${r.blowout_n} ot${r.overtime_n} `+
      `sd${r.final.sd_signed_margin.toFixed(3)} mean${r.final.mean_signed_margin.toFixed(3)} `+
      `poss${r.final.mean_total_possessions.toFixed(2)} gapSD${r.strength_gap_sd.toFixed(3)} `+
      `qSD[${r.cumulative_quarter_sd.map(x=>x.toFixed(2)).join(',')}] `+
      `lateAbs${r.mean_late_absolute_expansion.toFixed(2)} `+
      `lateAligned${r.mean_pre_leader_aligned_late.toFixed(2)} `+
      `preClose${r.pre_late_close_n} lost${r.pre_late_close_to_wide_n} gained${r.pre_late_wide_to_close_n}`);
    if (arm === 'ordinary_ab' && env === 0.5) {
      console.log('  components', Object.fromEntries(Object.entries(r.final.component)
        .map(([k,v])=>[k,+v.covariance_share.toFixed(3)])));
      console.log('  conditional', Object.fromEntries(Object.entries(r.final.conditional)
        .map(([k,v])=>[k,+v.covariance_share.toFixed(3)])));
      console.log('  periodSigned', r.native_regulation_periods.map(x=>+x.mean_signed_margin.toFixed(2)));
      console.log('  quarterSigned', r.normalized_quarters.map(x=>+x.mean_signed_margin.toFixed(2)));
      console.log('  quarterComponents', r.normalized_quarters.map(x=>Object.fromEntries(
        Object.entries(x.component).map(([k,v])=>[k,+v.mean_signed.toFixed(2)]))));
      console.log('  lateCounts', Object.fromEntries(['free_throws_attempted','free_throws_made','intentional_fouls','turnovers','offensive_rebounds','possessions'].map(k=>[k,+r.windows.late_regulation.channel_counts[k].total.toFixed(2)])));
      console.log('  conditionalShotVar', r.mean_conditional_shot_variance.toFixed(2));
    }
  }
  console.log('contrasts',s.contrasts[`${range}/${competition}`]);
  console.log('coverage',s.coverage[`${range}/${competition}`]);
}
