import fs from 'node:fs';
import path from 'node:path';

// Recomputes descriptive accounting from the archived raw rows. Every cell is
// checked for a complete footer and every matched comparison is key-joined.
const root = path.dirname(new URL(import.meta.url).pathname.replace(/^\/(?=[A-Za-z]:)/, ''));
const files = process.argv.slice(2);
if (files.length !== 4) throw new Error('pass the four declared protocol cells');
const declared = new Map([
  ['range_a/college', 43290000], ['range_a/top_domestic_pro', 43290000],
  ['range_b/college', 47970000], ['range_b/top_domestic_pro', 47970000],
]);
const declaredSeen = new Set();
const rows = [];
const globalSeen = new Set();
for (const file of files) {
  const lines = fs.readFileSync(file, 'utf8').trim().split(/\r?\n/).map(JSON.parse);
  const header = lines[0], footer = lines.at(-1), games = lines.slice(1, -1);
  const cellKey = `${header.label}/${header.competition}`;
  if (!declared.has(cellKey) || declaredSeen.has(cellKey) ||
      header.first_variation !== declared.get(cellKey) || header.games_per_arm !== 40 ||
      JSON.stringify(header.arms) !== JSON.stringify(['ordinary_ab','identical_aa','reversed_ba']) ||
      JSON.stringify(header.environments) !== JSON.stringify([0,0.5]))
    throw new Error(`cell violates predeclared protocol ${file}`);
  declaredSeen.add(cellKey);
  if (header.kind !== 'header' || footer.kind !== 'complete' || footer.games !== games.length ||
      games.length !== header.games_per_arm * header.arms.length * header.environments.length)
    throw new Error(`incomplete cell ${file}`);
  const seen = new Set();
  for (const game of games) {
    const pairIndex = Math.floor(game.variation / 4);
    const a = pairIndex % 117, b = (2 * a + Math.floor(pairIndex / 117)) % 117;
    const pair = game.variation % 4 === 1 || game.variation % 4 === 2 ? [b,a] : [a,b];
    const expectedRoster = game.arm === 'ordinary_ab' ? pair : game.arm === 'identical_aa' ? [pair[0],pair[0]] : [pair[1],pair[0]];
    if (game.kind !== 'game' || game.measurement.errors.length ||
        game.seed !== game.variation + 1 ||
        game.variation < header.first_variation || game.variation >= header.first_variation + header.games_per_arm ||
        !header.arms.includes(game.arm) || !header.environments.includes(game.environment) ||
        game.match_id !== `calib_${header.competition}_${game.variation}` ||
        game.opening_home !== (game.variation % 2 === 0) ||
        game.home_roster !== expectedRoster[0] || game.away_roster !== expectedRoster[1] ||
        game.home_score - game.away_score !== game.measurement.final.margin)
      throw new Error(`invalid row ${file} ${game.variation}`);
    const regulationMs = header.competition === 'college' ? 2400000 : header.competition === 'top_domestic_pro' ? 2880000 : null;
    if (regulationMs === null) throw new Error(`unsupported competition clock ${header.competition}`);
    const chargedMs = game.measurement.final.home.live_ms + game.measurement.final.away.live_ms;
    if (chargedMs !== regulationMs + game.overtime_periods * 300000)
      throw new Error(`charged-clock conservation ${file} ${game.variation}: ${chargedMs}`);
    const key = `${game.variation}/${game.arm}/${game.environment}`;
    if (seen.has(key)) throw new Error(`duplicate row ${file} ${key}`);
    seen.add(key);
    const globalKey = `${header.competition}/${key}`;
    if (globalSeen.has(globalKey)) throw new Error(`duplicate supplied cell ${globalKey}`);
    globalSeen.add(globalKey);
    rows.push({...game, range: header.label, competition: header.competition});
  }
  for (let v = header.first_variation; v < header.first_variation + header.games_per_arm; v++)
    for (const arm of header.arms) for (const environment of header.environments)
      if (!seen.has(`${v}/${arm}/${environment}`)) throw new Error(`missing matched row ${file} ${v}/${arm}/${environment}`);
}
if (declaredSeen.size !== declared.size) throw new Error('missing declared cell');
const mean = a => a.reduce((s, x) => s + x, 0) / a.length;
const variance = a => a.length < 2 ? 0 : a.reduce((s, x) => s + (x - mean(a)) ** 2, 0) / (a.length - 1);
const cov = (a, b) => a.length < 2 ? 0 : a.reduce((s, x, i) => s + (x - mean(a)) * (b[i] - mean(b)), 0) / (a.length - 1);
const sum = a => a.reduce((s, x) => s + x, 0);
const by = (array, fn) => Object.groupBy(array, fn);
const hashKey = value => {
  let hash = 2166136261;
  for (const code of value) hash = Math.imul(hash ^ code.charCodeAt(0), 16777619) >>> 0;
  return hash || 1;
};
const makeRandomIndex = key => {
  let state = hashKey(`22092026/${key}`);
  return n => {
    state ^= state << 13;
    state ^= state >>> 17;
    state ^= state << 5;
    return Math.floor(((state >>> 0) / 4294967296) * n);
  };
};
const segmentSummary = (games, pick) => {
  const segments = games.map(g => pick(g.measurement));
  const margins = segments.map(s => s.margin);
  const keys = Object.keys(segments[0].components);
  const channelKeys = [
    'field_goals_attempted','field_goals_made','expected_field_points',
    'conditional_shot_variance','free_throws_attempted','free_throws_made',
    'turnovers','offensive_rebounds','defensive_rebounds','fouls',
    'intentional_fouls','possessions',
  ];
  const channel_counts = Object.fromEntries(channelKeys.map(key => [key, {
    home: mean(segments.map(s => s.home[key])), away: mean(segments.map(s => s.away[key])),
    signed: mean(segments.map(s => s.home[key] - s.away[key])),
    total: mean(segments.map(s => s.home[key] + s.away[key])),
  }]));
  const component = Object.fromEntries(keys.map(k => [k, {
    mean_signed: mean(segments.map(s => s.components[k])),
    covariance_share: variance(margins) ? cov(segments.map(s => s.components[k]), margins) / variance(margins) : null,
  }]));
  const conditional = Object.fromEntries(Object.keys(segments[0].conditional_components).map(k => [k, {
    mean_signed: mean(segments.map(s => s.conditional_components[k])),
    covariance_share: variance(margins) ? cov(segments.map(s => s.conditional_components[k]), margins) / variance(margins) : null,
  }]));
  return {
    mean_signed_margin: mean(margins), sd_signed_margin: Math.sqrt(variance(margins)),
    mean_absolute_margin: mean(margins.map(Math.abs)),
    mean_home_possessions: mean(segments.map(s => s.home.possessions)),
    mean_away_possessions: mean(segments.map(s => s.away.possessions)),
    mean_total_possessions: mean(segments.map(s => s.home.possessions + s.away.possessions)),
    mean_charged_clock_ms: mean(segments.map(s => s.home.live_ms + s.away.live_ms)),
    component, conditional, channel_counts,
  };
};
const summary = {files, cells: {}, contrasts: {}, coverage: {}};
for (const [key, games] of Object.entries(by(rows, g => `${g.range}/${g.competition}/${g.arm}/${g.environment}`))) {
  const margins = games.map(g => g.measurement.final.margin);
  const pre = games.map(g => g.measurement.pre_late_margin);
  const late = games.map(g => g.measurement.late_margin_increment);
  const conditionalVariance = games.map(g => g.measurement.final.home.conditional_shot_variance + g.measurement.final.away.conditional_shot_variance);
  const regulationPeriods = games[0].measurement.periods.length - games[0].overtime_periods;
  if (!games.every(g => g.measurement.periods.length - g.overtime_periods === regulationPeriods))
    throw new Error(`inconsistent native period count ${key}`);
  summary.cells[key] = {
    n: games.length, close_n: margins.filter(x => Math.abs(x) <= 5).length,
    blowout_n: margins.filter(x => Math.abs(x) >= 20).length,
    overtime_n: games.filter(g => g.overtime_periods > 0).length,
    strength_gap_mean: mean(games.map(g => g.strength_gap)),
    strength_gap_sd: Math.sqrt(variance(games.map(g => g.strength_gap))),
    final: segmentSummary(games, m => m.final),
    native_regulation_periods: Array.from({length: regulationPeriods}, (_, i) => segmentSummary(games, m => m.periods[i])),
    normalized_quarters: [0,1,2,3].map(i => segmentSummary(games, m => m.quarters[i])),
    cumulative_quarter_sd: [0,1,2,3].map(i => Math.sqrt(variance(games.map(g => sum(g.measurement.quarters.slice(0, i+1).map(q => q.margin)))))),
    cumulative_native_regulation_sd: Array.from({length: regulationPeriods}, (_, i) => Math.sqrt(variance(games.map(g => sum(g.measurement.periods.slice(0, i+1).map(p => p.margin)))))),
    windows: Object.fromEntries(['early_regulation','late_regulation','overtime'].map(k => [k, segmentSummary(games, m => m.windows[k])])),
    mean_conditional_shot_variance: mean(conditionalVariance),
    mean_pre_late_signed: mean(pre), mean_late_signed_increment: mean(late),
    mean_pre_leader_aligned_late: mean(pre.map((x,i) => Math.sign(x) * late[i])),
    mean_late_absolute_expansion: mean(games.map(g => g.measurement.late_absolute_expansion)),
    late_expanded_n: games.filter(g => g.measurement.late_absolute_expansion > 0).length,
    pre_late_close_n: pre.filter(x => Math.abs(x) <= 5).length,
    pre_late_close_to_wide_n: games.filter((g,i) => Math.abs(pre[i]) <= 5 && Math.abs(pre[i]+late[i]) > 5).length,
    pre_late_wide_to_close_n: games.filter((g,i) => Math.abs(pre[i]) > 5 && Math.abs(pre[i]+late[i]) <= 5).length,
    regulation_close_n: games.filter(g => Math.abs(g.measurement.regulation_margin) <= 5).length,
  };
}
for (const [key, games] of Object.entries(by(rows, g => `${g.range}/${g.competition}`))) {
  const map = new Map(games.map(g => [`${g.variation}/${g.arm}/${g.environment}`, g]));
  const ordinary = games.filter(g => g.arm === 'ordinary_ab' && g.environment === 0.5);
  const contrasts = {};
  for (const [name, leftArm, leftEnv, rightArm, rightEnv, multiplier] of [
    ['ordinary_home_minus_neutral','ordinary_ab',0.5,'ordinary_ab',0.0,1],
    ['identical_home_minus_neutral','identical_aa',0.5,'identical_aa',0.0,1],
    ['reversed_home_minus_neutral','reversed_ba',0.5,'reversed_ba',0.0,1],
    ['ordinary_minus_identical_neutral','ordinary_ab',0.0,'identical_aa',0.0,1],
    ['ordinary_vs_reversed_neutral','ordinary_ab',0.0,'reversed_ba',0.0,1],
  ]) {
    const differences = ordinary.map(g => {
      const left = map.get(`${g.variation}/${leftArm}/${leftEnv}`);
      const right = map.get(`${g.variation}/${rightArm}/${rightEnv}`);
      if (!left || !right || left.seed !== right.seed || left.match_id !== right.match_id || left.opening_home !== right.opening_home)
        throw new Error(`unmatched ${key} ${g.variation} ${name}`);
      return multiplier * (left.measurement.final.margin - right.measurement.final.margin);
    });
    const blocks = Object.values(by(ordinary.map((g,i) => ({block: Math.floor(g.variation/4), difference: differences[i]})), x => x.block));
    const clusterMeans = blocks.map(block => mean(block.map(x => x.difference)));
    const left = ordinary.map(g => map.get(`${g.variation}/${leftArm}/${leftEnv}`));
    const right = ordinary.map(g => map.get(`${g.variation}/${rightArm}/${rightEnv}`));
    const indicator = predicate => left.map((g,i) => Number(predicate(g)) - Number(predicate(right[i])));
    const closeChanges = indicator(g => Math.abs(g.measurement.final.margin) <= 5);
    const blowChanges = indicator(g => Math.abs(g.measurement.final.margin) >= 20);
    const quartetSe = values => {
      const blockMeans = Object.values(by(ordinary.map((g,i) => ({block: Math.floor(g.variation/4), value: values[i]})), x => x.block))
        .map(block => mean(block.map(x => x.value)));
      return Math.sqrt(variance(blockMeans) / blockMeans.length);
    };
    const quartetIndices = Object.values(by(ordinary.map((g,i) => ({block: Math.floor(g.variation/4), index:i})), x => x.block))
      .map(block => block.map(x => x.index));
    const randomIndex = makeRandomIndex(`${key}/${name}`);
    const sdBoot = [];
    for (let iteration = 0; iteration < 2000; iteration++) {
      const selected = [];
      for (let j = 0; j < quartetIndices.length; j++) selected.push(...quartetIndices[randomIndex(quartetIndices.length)]);
      sdBoot.push(Math.sqrt(variance(selected.map(i => left[i].measurement.final.margin))) -
        Math.sqrt(variance(selected.map(i => right[i].measurement.final.margin))));
    }
    sdBoot.sort((a,b) => a-b);
    contrasts[name] = {mean_signed: mean(differences), quartet_se: Math.sqrt(variance(clusterMeans)/clusterMeans.length),
      half_signed_mean: name === 'ordinary_vs_reversed_neutral' ? mean(differences)/2 : null,
      quartet_count: clusterMeans.length, positive_n: differences.filter(x => x > 0).length,
      negative_n: differences.filter(x => x < 0).length, zero_n: differences.filter(x => x === 0).length,
      close_share_change: mean(closeChanges), close_quartet_se: quartetSe(closeChanges),
      blowout_share_change: mean(blowChanges), blowout_quartet_se: quartetSe(blowChanges),
      sd_difference: Math.sqrt(variance(left.map(g => g.measurement.final.margin))) - Math.sqrt(variance(right.map(g => g.measurement.final.margin))),
      sd_difference_bootstrap_95: [sdBoot[49], sdBoot[1949]],
    };
  }
  summary.contrasts[key] = contrasts;
}
for (const [key, games] of Object.entries(by(rows, g => `${g.range}/${g.competition}`))) {
  const counters = {};
  for (const game of games) for (const [name, value] of Object.entries(game.measurement.coverage)) counters[name] = (counters[name] || 0) + value;
  summary.coverage[key] = counters;
}
const requiredWitnesses = [
  'two_point_attempts','three_point_attempts','blocked_attempts','unblocked_attempts',
  'turnovers','offensive_rebounds','defensive_rebounds','fouls','free_throws_made',
  'free_throws_missed','intentional_fouls','late_regulation_possessions',
];
summary.coverage_gaps = {};
for (const competition of ['college','top_domestic_pro']) {
  const counts = {};
  for (const label of ['range_a','range_b'])
    for (const [key,value] of Object.entries(summary.coverage[`${label}/${competition}`])) counts[key] = (counts[key] || 0) + value;
  const missing = requiredWitnesses.filter(key => !(counts[key] > 0));
  if (missing.length) throw new Error(`required live witness absent for ${competition}: ${missing.join(',')}`);
  summary.coverage_gaps[competition] = {
    overtime_possessions: counts.overtime_possessions || 0,
    straddled_late_boundary: counts.straddled_late_boundary || 0,
  };
}
fs.writeFileSync(path.join(root, 'summary.json'), JSON.stringify(summary, null, 2) + '\n');
console.log(JSON.stringify({rows: rows.length, cells: Object.keys(summary.cells).length, output: path.join(root, 'summary.json')}));
