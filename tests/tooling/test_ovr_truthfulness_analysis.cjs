'use strict';
const assert = require('node:assert/strict');
const A = require('../../analysis/ovr_truthfulness_followup/analyze.cjs');
const cases = {};
cases.exact_rational_formula_and_rounding = () => {
  assert.equal(A.oracle(Array(20).fill(25)).display, 25);
  assert.equal(A.oracle(Array(20).fill(99)).display, 99);
  const boundary = [25,25,26,28,28,30,30,34,41,41,44,48,54,69,76,82,84,89,92,94];
  assert.equal(A.oracle(boundary).raw, 56.5); assert.equal(A.oracle(boundary).display, 57);
  boundary[10]--; assert.equal(A.oracle(boundary).display, 56);
};
function fakeRows(perFamily = 1) {
  const rows = [];
  for (let family = 0; family < 3; family++) for (let i = 0; i < perFamily; i++) {
    const cluster = family * perFamily + i;
    const before = Array(20).fill(48), caps = Array(20).fill(80);
    for (const [a, arm] of ['baseline', 'all20_plus10_toward_caps', 'scoring5_plus10_toward_caps'].entries()) for (let slot = 0; slot < 4; slot++) {
      const values = before.map((v, k) => a === 0 || (a === 2 && k > 4) ? v : v + 10);
      const row = Object.fromEntries(A.COUNTS.map(k => [k, 0]));
      Object.assign(row, {experiment: 'within', range: 'A', cluster, family: ['guard','wing','big'][family], arm, slot,
        source_seed: 9800001 + cluster, seed: 9810001 + cluster * 4 + slot, subject_home: slot === 0 || slot === 3,
        subject_opens: slot === 0 || slot === 1, values, caps, current_ovr: A.oracle(values).display,
        raw_ovr: A.oracle(values).raw, maximum_potential: 80, position: 'SF', rotation_role: 'starter',
        tactical_role: 'slasher', body: 'constant', teammates_sha256: 'a'.repeat(64), opponent_sha256: 'b'.repeat(64), tendencies: Array(10).fill(3),
        competition: 'high_school', creation_ap: 195, teammate_seed_first: (9800001 + cluster) * 100,
        opponent_seed_first: (9800001 + cluster) * 100 + 20,
        intervention: {before, ap_granted: a === 0 ? 0 : a === 1 ? 200 : 50, rating_points_applied: a === 0 ? 0 : a === 1 ? 200 : 50},
        seconds_played: 1920, points: a === 0 ? 10 : 12, field_goals_made: a === 0 ? 5 : 6, field_goals_attempted: 12,
        touches: 20, ledger_touches: 20, on_court_offense_possessions: 50, on_court_defense_possessions: 50,
        team_possessions: 60, opponent_possessions: 60, team_score: 52 + a, opponent_score: 50, team_margin: 2 + a, won: 1,
        assists: 3, turnovers: 2, offensive_rebounds: 1, defensive_rebounds: 4, steals: 1, blocks: 1, player_id: 'subject_focus'});
      rows.push(row);
    }
  }
  return rows;
}
cases.complete_pairing_and_shuffled_rows = () => {
  const rows = fakeRows(); assert.equal(A.validateWithin(rows, 1, {allowSynthetic:true}).complete, true);
  assert.deepEqual(A.validateWithin(rows.slice().reverse(), 1, {allowSynthetic:true}), A.validateWithin(rows, 1, {allowSynthetic:true}));
  assert.equal(A.validateWithin(fakeRows(8)).games, 288);
};
cases.duplicate_seed_is_rejected = () => {
  const rows = fakeRows(); rows[1].seed = rows[0].seed;
  assert.throws(() => A.validateWithin(rows, 1, {allowSynthetic:true}), /duplicate seed/);
};
cases.missing_counterbalance_is_rejected = () => {
  const rows = fakeRows(); rows[1].subject_home = rows[0].subject_home; rows[1].subject_opens = rows[0].subject_opens;
  assert.throws(() => A.validateWithin(rows, 1, {allowSynthetic:true}), /unbalanced venue/);
};
cases.controlled_roster_mutation_is_rejected = () => {
  const rows = fakeRows(); rows[4].opponent_sha256 = 'c'.repeat(64);
  assert.throws(() => A.validateWithin(rows, 1, {allowSynthetic:true}), /controlled teammates\/opponent/);
};
cases.coherently_shifted_confirmation_archive_is_rejected = () => {
  const rows = fakeRows(8); rows.forEach(r => r.seed += 1000);
  assert.throws(() => A.validateWithin(rows), /confirmation gameplay seed shifted/);
};
cases.missing_both_control_hashes_is_rejected = () => {
  const rows = fakeRows(8); rows.forEach(r => { delete r.teammates_sha256; delete r.opponent_sha256; });
  assert.throws(() => A.validateWithin(rows), /missing held-fixed roster hashes/);
};
cases.invalid_slot_domain_is_rejected = () => {
  const rows = fakeRows(); rows.forEach(r => r.slot += 4);
  assert.throws(() => A.validateWithin(rows, 1, {allowSynthetic:true}), /invalid slot domain/);
};
function population(kind, range = 'A') {
  const rows = [], base = fakeRows()[0], offset = range === 'B' ? 100000 : 0;
  for (let competition = 0; competition < (kind === 'catalog' ? 5 : 1); competition++) for (let variation = 0; variation < 8; variation++) {
    const slot = variation % 4, cluster = kind === 'catalog' ? competition * 2 + Math.floor(variation / 4) : Math.floor(variation / 4);
    for (let side = 0; side < 2; side++) for (let index = 0; index < 10; index++) {
      const subjectHome = kind === 'catalog' ? side === 0 : (slot === 0 || slot === 3) === (side === 0);
      const r = structuredClone(base);
      Object.assign(r, {experiment:kind, range, competition:kind === 'catalog' ? A.COMPETITIONS[competition] : 'college',
        cluster, slot, variation, seed:(kind === 'catalog' ? 9820001 + competition * 8 : 9850001) + offset + variation,
        player_id:kind === 'catalog' ? `${side === 0 ? 'home' : 'away'}_p${index+1}` : `college_${side}_p${index}`,
        subject_home:subjectHome, subject_opens:kind === 'catalog' ? subjectHome === (variation % 2 === 0) : (slot === 0 || slot === 1) === (side === 0),
        ledger_sha256:'d'.repeat(64), archetype:'balanced'});
      if (kind === 'catalog') {
        const a = Math.floor(variation/4), b = 2*a;
        r.roster_variation = (slot === 0 || slot === 3) === (side === 0) ? a : b;
        r.caps = null; r.maximum_potential = null; r.age = null;
      } else {
        Object.assign(r, {career_seed:9840001+offset+cluster*20+side*10+index, class_year:index%3+1,
          snapshot_career_year:5+index%3, growth_milestones:4+index%3, age:19+index%3,
          snapshot_recorded_ovr:r.current_ovr, creation_spent:195, body_state_signature:'body-with-milestones'});
      }
      rows.push(r);
    }
  }
  return rows;
}
cases.catalog_and_college_fixed_coverage_is_validated = () => {
  assert.equal(A.validatePopulation(population('catalog'), 'catalog', 'A').games, 40);
  assert.equal(A.validatePopulation(population('college', 'B'), 'college', 'B').natural_careers, 40);
};
cases.missing_complete_population_game_is_rejected = () => {
  const rows = population('catalog').slice(20);
  assert.throws(() => A.validatePopulation(rows, 'catalog', 'A'), /missing fixed population/);
};
cases.coherently_shifted_catalog_archive_is_rejected = () => {
  const rows = population('catalog'); rows.forEach(r => r.seed++);
  assert.throws(() => A.validatePopulation(rows, 'catalog', 'A'), /catalog seed shifted/);
};
cases.coherently_flipped_catalog_openers_are_rejected = () => {
  const rows = population('catalog'); rows.forEach(r => r.subject_opens = !r.subject_opens);
  assert.throws(() => A.validatePopulation(rows, 'catalog', 'A'), /catalog opener counterbalance/);
};
cases.corrected_catalog_pairing_is_preserved = () => {
  const rows = population('catalog'); rows.filter(r => r.variation >= 4).forEach(r => r.roster_variation = 1);
  assert.throws(() => A.validatePopulation(rows, 'catalog', 'A'), /corrected v4 catalog pairing/);
};
cases.natural_college_career_ranges_are_enforced = () => {
  const rows = population('college'); rows.forEach(r => r.career_seed++);
  assert.throws(() => A.validatePopulation(rows, 'college', 'A'), /natural college career seed shifted/);
};
cases.college_chronological_body_provenance_is_enforced = () => {
  const rows = population('college'); rows[0].growth_milestones++;
  assert.throws(() => A.validatePopulation(rows, 'college', 'A'), /snapshot\/maturation/);
};
function histograms() {
  const fixture = [];
  for (const competition of A.COMPETITIONS) for (let roster = 0; roster < 117; roster++) for (let player = 1; player <= 10; player++) {
    fixture.push({competition, roster_variation:roster, player_id:'histogram_p'+player, values:Array(20).fill(60), current_ovr:60});
  }
  return ['A','B'].map((range, k) => ({range, fixture_rows:structuredClone(fixture), natural_rows:Array.from({length:1000}, (_, i) => ({
    career_seed:9860001+k*100000+i, starting_values:Array(20).fill(48), starting_current:48, exact_caps:Array(20).fill(80),
    maximum_potential:80, college_values:[0,1,2].map(() => Array(20).fill(60)), college_current:[60,60,60],
    family:'wing', prospect:'balanced', path:'rotation', peak_current:70, final_current:60,
    all_season_current:[50,52,54,56,60,60,60], all_season_ages:[15,16,17,18,19,20,21]
  }))}));
}
cases.histogram_all_ranges_and_five_populations_are_checked = () => {
  assert.equal(A.naturalHistogram(histograms()).natural_careers, 2000);
};
cases.second_histogram_payload_formula_corruption_is_rejected = () => {
  const payloads = histograms(); payloads[1].fixture_rows[0].current_ovr++;
  assert.throws(() => A.naturalHistogram(payloads), /fixture histogram OVR disagrees/);
};
cases.enlarged_duplicate_fixture_histogram_is_rejected = () => {
  const payloads = histograms(); payloads[0].fixture_rows.push(structuredClone(payloads[0].fixture_rows[0]));
  assert.throws(() => A.naturalHistogram(payloads), /finite fixture histogram coverage/);
};
cases.missing_histogram_competition_is_rejected = () => {
  const payloads = histograms(); payloads[0].fixture_rows.filter(r => r.competition === 'college').forEach(r => r.competition = 'high_school');
  assert.throws(() => A.naturalHistogram(payloads), /missing histogram competition/);
};
cases.coherently_shifted_natural_histogram_seeds_are_rejected = () => {
  const payloads = histograms(); payloads[1].natural_rows.forEach(r => r.career_seed++);
  assert.throws(() => A.naturalHistogram(payloads), /shifted natural histogram seed/);
};
cases.touch_denominator_corruption_is_rejected = () => {
  const row = fakeRows()[0]; row.touches++;
  assert.throws(() => A.validateRow(row), /ledger touch denominator/);
};
cases.ratio_of_pooled_attempts_and_zero_denominator = () => {
  const a = fakeRows()[0], b = {...a};
  a.field_goals_made = 1; a.field_goals_attempted = 1;
  b.field_goals_made = 0; b.field_goals_attempted = 9;
  assert.equal(A.metrics(A.totals([a, b])).field_goal_fraction, 0.1);
  a.field_goals_attempted = 0; a.field_goals_made = 0;
  assert.equal(A.metrics(A.totals([a])).field_goal_fraction, null);
};
cases.bootstrap_retains_paired_clusters_and_is_deterministic = () => {
  const rows = fakeRows(8);
  rows.forEach(r => { r.points += r.cluster * 2; r.field_goals_made += r.cluster; r.field_goals_attempted += r.cluster; });
  const first = A.pairedBootstrap(rows, 'all20_plus10_toward_caps', 500, 1);
  const second = A.pairedBootstrap(rows, 'all20_plus10_toward_caps', 500, 1);
  assert.deepEqual(first, second);
  assert.ok(Math.abs(first.points_per32.difference - 2) < 1e-12);
  assert.ok(first.points_per32.ci95.every(v => Math.abs(v - 2) < 1e-12));
  assert.equal(first.team_margin.source_player_clusters, 24);
};
cases.multiplicity_interval_is_wider_than_pointwise = () => {
  const rows = fakeRows(8);
  rows.filter(r => r.arm === 'all20_plus10_toward_caps').forEach(r => {
    r.team_score += r.cluster; r.team_margin += r.cluster;
  });
  const m = A.pairedBootstrap(rows, 'all20_plus10_toward_caps', 1000, 17).team_margin;
  assert.ok(m.familywise_ci95[0] < m.ci95[0], '14-comparison lower bound must be wider');
  assert.ok(m.familywise_ci95[1] > m.ci95[1], '14-comparison upper bound must be wider');
};
cases.raw_count_minutes_and_opportunity_denominators = () => {
  const rows = fakeRows().filter(r => r.arm === 'baseline'), t = A.totals(rows), m = A.metrics(t);
  assert.equal(t.games, 12); assert.equal(t.seconds_played, 12 * 1920);
  assert.equal(m.points_per32, 10); assert.equal(m.points_per100_offense_possessions, 20);
  assert.equal(m.assists_per100_touches, 15); assert.equal(m.turnovers_per100_touches, 10);
  assert.equal(m.rebounds_per32, 5);
};
cases.aggregate_relationship_does_not_imply_within_stratum = () => {
  assert.ok(A.correlation([[40,10],[50,8],[70,30],[80,28]]) > 0);
  assert.equal(A.correlation([[40,10],[50,8],[45,9]]), -1);
  assert.equal(A.correlation([[50,1],[50,2],[50,3]]), null);
};
function builderRows() {
  const rows=[], base=fakeRows()[0];
  for(const [range,start] of [['validation_a',71000000],['validation_b',81000000]]) {
    for(const [k,id] of A.BUILDER_PRIMARY.entries()) for(let cell=0;cell<8;cell++) for(let quartet=0;quartet<2;quartet++) for(let phase=0;phase<4;phase++) {
      const r=structuredClone(base), ratings=Array(20).fill(48);
      if(k) {ratings[k%20]+=5; ratings[(k+1)%20]-=5;}
      Object.assign(r,{range,build_id:id,primary:true,cell,quartet,phase,seed:start+cell*1000+quartet*4+phase+1,
        home_subject:phase===0||phase===3,subject_opens:phase===0||phase===1,context:{role:cell<4?'utility_energy':'shooter'},
        subject_roster:quartet,teammate_signature:'fixed-teammates',opponent_signature:'fixed-opponents',errors:[],
        team_points:r.team_score,opponent_points:r.opponent_score,team_win:true,
        defended_attempts:10,defended_makes:4,defended_three_makes:1,
        build:{family:1,prospect:1,ap_granted:195,ap_spent:195,ap_remaining:0,confirmed:true,ratings,caps:Array(20).fill(80),
          current_overall:A.oracle(ratings).display,maximum_potential:80,body:[80,210,83,107],tendencies:Array(10).fill(3)}});
      rows.push(r);
    }
    for(let i=0;i<32;i++) rows.push({range,primary:false});
  }
  return rows;
}
cases.shared_builder_same_ovr_pairs_are_actually_read = () => {
  const report=A.builderComparables(builderRows());
  assert.equal(report.games,2368); assert.equal(report.primary_equal_resource_games,2304);
  assert.equal(report.omitted_unequal_profile_and_other_family_games,64);
  assert.ok(report.same_displayed_ovr_pair_count>0);
  const example=report.same_displayed_ovr_examples[0];
  assert.equal(example.a.current_ovr,example.b.current_ovr);
  assert.notDeepEqual(example.a.values,example.b.values);
  assert.equal(example.a.raw.games,4); assert.equal(example.a.observables.allowed_effective_field_goal_fraction,0.45);
};
cases.shared_builder_unequal_starting_budget_is_rejected = () => {
  const rows=builderRows(); rows[0].build.ap_granted=155;
  assert.throws(()=>A.builderComparables(rows),/unequal-resource/);
};
cases.shared_builder_coherent_schedule_corruption_is_rejected = () => {
  const rows=builderRows(); rows.filter(r=>r.primary).forEach(r=>r.seed++);
  assert.throws(()=>A.builderComparables(rows),/shared Builder seed shifted/);
};
let passed = 0, failed = 0;
for (const [name, fn] of Object.entries(cases)) {
  try { fn(); passed++; process.stdout.write('PASSED ' + name + '\n'); }
  catch (error) { failed++; process.stderr.write('FAILED ' + name + ' ' + error.name + ': ' + error.message + '\n'); }
}
process.stdout.write(`${passed}/${Object.keys(cases).length} passed, ${failed} failed\n`);
if (failed) process.exitCode = 1;
